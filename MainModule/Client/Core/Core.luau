return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})

	local client, service = Vargs.Client, Vargs.Service
	local FiOne = service.UnWrap(client.Shared.FiOne)
	local Anti, Core, Functions, Process, Remote, UI, Variables, log, Pcall, Routine

	local function Init(data)
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;
		log = client.log
		Pcall = client.Pcall
		Routine = client.Routine

		Core.Name = "\0"
		Core.Special = client.DepsName
		Core.MakeGui = UI.Make;
		Core.GetGui = UI.Get;
		Core.RemoveGui = UI.Remove;

		if data.DebugMode == true then
			Core.DebugMode = true
		end
		
		
		Core.Init = nil;
	end

	local function RunAfterPlugins(data)
		Core.GetEvent()

		Core.RunAfterPlugins = nil;
	end

	local function RunLast()
		--// API
		if service.NetworkClient then
			service.TrackTask("Thread: API Manager", Core.StartAPI)
		end

		Core.RunLast = nil
	end


	client.Core = {
		Init = Init;
		RunLast = RunLast;
		--RunAfterLoaded = RunAfterLoaded;
		RunAfterPlugins = RunAfterPlugins;
		Name = script.Name;
		Special = script.Name;
		ScriptCache = {};

		GetEvent = function()
			if Core.RemoteEvent then
				log("Disconnect old RemoteEvent")

				for name,event in Core.RemoteEvent.Events do
					event:Disconnect()
				end

				Core.RemoteEvent = nil;
			end

			log("Getting RemoteEvent");

			local eventData = {}
			local remoteParent = service.ReplicatedStorage;
			local event = remoteParent:WaitForChild(client.RemoteName, 300)

			if not event then
				Anti.Detected("Kick", "RemoteEvent Not Found");
			else
				log("Getting RemoteFunction");

				local rFunc = event:WaitForChild("__FUNCTION", 120);

				if not rFunc then
					Anti.Detected("Kick", "RemoteFunction Not Found");
				else
					local events = {};

					rFunc.OnClientInvoke = Process.Remote;

					eventData.Object = event;
					eventData.Function = rFunc;
					eventData.FireServer = event.FireServer;
					eventData.Events = events;

					events.ProcessRemote = event.OnClientEvent:Connect(Process.Remote)
					events.ParentChildRemoved = remoteParent.ChildRemoved:Connect(function(child)
						if (Core.RemoteEvent == eventData) and child == event and task.wait() then
							warn("::ADONIS:: REMOTE EVENT REMOVED? RE-GRABBING");
							log("~! REMOTEEVENT WAS REMOVED?")
							Core.GetEvent();
						end
					end)

					Core.RemoteEvent = eventData

					if not Core.Key then
						log("~! Getting key from server")
						--Remote.Fire(`{client.DepsName}GET_KEY`)
						Core.Key = Remote.Get(`{client.DepsName}GET_KEY`)
						if Core.Key then
							client.Finish_Loading()
						else
							Remote.Fire(`{client.DepsName}GET_KEY`)
						end
					end
				end
			end
		end;

		DebugMode = client.DebugMode;

		LoadBytecode = function(str, env)
			return require(FiOne)(str, env)
		end;

		LoadCode = function(str, env)
			return Core.LoadBytecode(str, env)
		end;

		StartAPI = function()
			local ScriptCache = Core.ScriptCache
			local FiOne = client.Shared.FiOne
			local Get = Remote.Get
			local GetFire = Remote.GetFire
			local G_API = client.G_API
			local Allowed_API_Calls = client.Allowed_API_Calls
			local NewProxy = service.NewProxy
			local ReplicatedStorage = service.ReplicatedStorage
			local MetaFunc = service.MetaFunc
			local ReadOnly = service.ReadOnly
			local StartLoop = service.StartLoop
			local ReadOnly = service.ReadOnly
			local UnWrap = service.UnWrap
			local service = nil
			local client = nil
			local _G = _G
			local setmetatable = setmetatable
			local type = type
			local print = print
			local error = error
			local pairs = pairs
			local ipairs = ipairs
			local warn = warn
			local next = next
			local table = table
			local rawset = rawset
			local rawget = rawget
			local require = require
			local tostring = tostring
			local client = client
			local Routine = Routine
			local Pcall = Pcall

			--// Get Settings
			local API_Special = {

			}

			local API_Specific = {
				API_Specific = {
					Test = function()
						print("We ran the api specific stuff")
					end
				};
				Service = service;
			}

			local API = {
				Access = ReadOnly({}, nil, nil, true);

				Scripts = ReadOnly({
					ExecutePermission = (function(srcScript, code)
						local exists;

						for i,v in ScriptCache do
							if UnWrap(v.Script) == srcScript then
								exists = v
							end
						end

						if exists and exists.noCache ~= true and (not exists.runLimit or (exists.runLimit and exists.Executions <= exists.runLimit)) then
							exists.Executions = exists.Executions+1
							return exists.Source, exists.Loadstring
						end

						local data = Get("ExecutePermission", srcScript, code, true)
						if data and data.Source then
							local module;
							if not exists then
								module = require(UnWrap(FiOne):clone())
								table.insert(ScriptCache,{
									Script = srcScript;
									Source = data.Source;
									Loadstring = module;
									noCache = data.noCache;
									runLimit = data.runLimit;
									Executions = data.Executions;
								})
							else
								module = exists.Loadstring
								exists.Source = data.Source
							end
							return data.Source, module
						end
					end);
				}, nil, nil, true);
			}

			if Core.DebugMode == true then
				local DebugAPI = {
					Env = Vargs
				}
				API.Debug = DebugAPI -- Allows fetching of the Debug API from within the _G API

				local pointers = {}

				local function getRealEnvResult(PointerOrPath)
					if tonumber(PointerOrPath) and pointers[PointerOrPath] then
						return pointers[PointerOrPath], true
					else
						local envPath = PointerOrPath:split('/.\\')
						local RealEnvResult = Vargs
						for i, pathArg in ipairs(envPath) do
							RealEnvResult = RealEnvResult[pathArg]
						end
						return RealEnvResult, false
					end
				end	

				local AdonisDebugAPIBindable = ReplicatedStorage:FindFirstChild("Adonis_Debug_API")
				if AdonisDebugAPIBindable then
					AdonisDebugAPIBindable.OnInvoke = function(DebugCommand,...)
						local args = {...}
						if DebugCommand == "RunEnvFunc" then
							local FunctionInEnvToRunPath = args[1]
							if FunctionInEnvToRunPath and type(FunctionInEnvToRunPath) == "string" then
								local realEnvResult, isResultPointer = getRealEnvResult(FunctionInEnvToRunPath)
								return realEnvResult(table.unpack(args,2,#args))
							end
						elseif DebugCommand == "GetEnvTableMeta" then
							local TableInEnvPath = args[1]
							if TableInEnvPath and type(TableInEnvPath) == "string" then
								local realEnvResult, isResultPointer = getRealEnvResult(TableInEnvPath)
								return getmetatable(realEnvResult)
							end
						elseif DebugCommand == "RunEnvTableMetaFunc" then
							local TableInEnvPath = args[1]
							local FuncToRun = args[2]
							if TableInEnvPath and type(TableInEnvPath) == "string" then
								local realEnvResult, isResultPointer = getRealEnvResult(TableInEnvPath)
								local metaTableInEnv = getmetatable(realEnvResult)
								local result = metaTableInEnv[FuncToRun](realEnvResult,table.unpack(args,3,#args))
								local resultPointer = tostring(math.random())
								pointers[resultPointer] = result

								return UnWrap(result), resultPointer
							end
						elseif DebugCommand == "GetApi" or not DebugCommand then
							return DebugAPI
						end
					end
				end
			end

			local AdonisGTable = NewProxy({
				__index = function(tab,ind)
					if ind == "Scripts" then
						return API.Scripts
					elseif G_API and Allowed_API_Calls.Client == true then
						if type(API[ind]) == "function" then
							return MetaFunc(API[ind])
						else
							return API[ind]
						end
					else
						error("_G API is disabled")
					end
				end;
				__newindex = function()
					error("Read-only")
				end;
				__metatable = "API";
			})

			if not rawget(_G, "Adonis") then
				if table.isfrozen and not table.isfrozen(_G) or not table.isfrozen then
					rawset(_G, "Adonis", AdonisGTable)
					StartLoop("APICheck", 1, function()
						if rawget(_G, "Adonis") ~= AdonisGTable then
							if table.isfrozen and not table.isfrozen(_G) or not table.isfrozen then
								rawset(_G, "Adonis", AdonisGTable)
							else
								warn("⚠️ ADONIS CRITICAL WARNING! MALICIOUS CODE IS TRYING TO CHANGE THE ADONIS _G API AND IT CAN'T BE SET BACK! PLEASE SHUTDOWN THE SERVER AND REMOVE THE MALICIOUS CODE IF POSSIBLE!")
							end
						end
					end, true)
				else
					warn("The _G table was locked and the Adonis _G API could not be loaded")
				end
			end
		end;
	};
end
--!native
--!optimize 2

--// 8ch_32bit has done a lot of unmangling.
--// A LOT of unmangling.

type TrackedTask = {
	Name: string,
	Status: string,
	Function: (...any) -> (...any),
	isThread: boolean,
	Created: number,
	Index: string,
}

local HttpService = game:GetService("HttpService")

return function(ErrorHandler, fenceSpecific, env)
	local Pcall = env.Pcall
	local LogError = env.logError or env.LogError
	local Server = env.server or env.Server
	local Client = env.client or env.Client

	local Main = Server or Client

	if not LogError then
		LogError = Main.LogError or Main.logError
	end

	local Service = nil;

	local passOwnershipCache = {}
	local assetOwnershipCache = {}
	local assetInfoCache = {}
	local groupInfoCache = {}
	local ChangedLocale = nil

	local toBoolean = function(Value: any): boolean
		return not (not Value)
	end

	local WaitingEvents = {}
	local HookedEvents = {}
	local Debounces = {}
	local Queues = {}
	local RbxEvents = {}
	local LoopQueue = {}
	local RunningLoops = {}
	local ServiceVariables = {}
	local RealMethods = {}

	local TrackedTasks: { [string | number]: TrackedTask } = {}

	local Methods = setmetatable({}, {
		__index = function(_, Index: any)
			return function(Object: any, ...)
				local Success, ClassName = pcall(function()
					return Object.ClassName
				end)

				if Success and typeof(Object[Index]) == "function" then
					local Method = RealMethods[ClassName]

					if not Method then
						Method = {}
						RealMethods[ClassName] = Method
					end

					local ObjectIndex = Object[Index]
					local MethodIndex = Method[Index]

					if not MethodIndex then
						MethodIndex = Object[Index]
						Method[Index] = MethodIndex
					end

					if ErrorHandler and MethodIndex ~= ObjectIndex then
						ErrorHandler("MethodError", `{debug.traceback()} || Cached method doesn't match found method: {Index}`, `Method: {Index}`, Index)
					end

					return MethodIndex(Object, ...)
				end

				return Object[Index](Object, ...)
			end
		end,

		__metatable = "Methods",
	})

	local CreatedItems = setmetatable({}, {__mode = "v"})
	local Wrappers = setmetatable({}, {__mode = "kv"})

	local Instance_new = Instance.new

	local Instance = {
		new = function(ClassName: string, Parent: Instance?)
			local Object: Instance = Instance_new(ClassName)

			if Parent then
				Object.Parent = Service.UnWrap(Parent)
			end

			return if Service and Client then Service.Wrap(Object, true) else Object
		end
	}

	local Events, Wrapper, Helpers = {
		TrackTask = function(Name: string, Function: (...any) -> (...any), TaskErrorHandler: (string) -> ()?, ...: any?)
			if type(TaskErrorHandler) ~= "function" then
				TaskErrorHandler = function(Error: string | any)
					LogError(`{Error}\n{debug.traceback()}`)
				end
			end

			local Index: string = HttpService:GenerateGUID(false)
			local IsThread: boolean = string.sub(Name, 1, 7) == "Thread:"

			local Task: TrackedTask = {
				Name = Name,
				Status = "Waiting",
				Function = Function,
				isThread = IsThread,
				Created = DateTime.now().UnixTimestamp,
				Index = Index,
			}

			local function TaskFunction(...: any)
				TrackedTasks[Index] = Task

				Task.Status = "Running"

				local Returns: { any? } = { xpcall(Function, TaskErrorHandler, ...) }

				Task.Returns = Returns

				if not Task.Returns[1] then
					Task.Status = "Errored"
				else
					Task.Status = "Finished"
				end

				TrackedTasks[Index] = nil

				return table.unpack(Task.Returns)
			end

			if IsThread then
				local Thread: thread = coroutine.create(TaskFunction)

				Task.Thread = Thread

				return coroutine.resume(Thread, ...)
			end

			return TaskFunction(...)
		end,

		EventTask = function(Name: string, Function: (...any?) -> (...any?))
			local TrackTask = Service.TrackTask

			return function(...: any?)
				return TrackTask(Name, Function, false, ...)
			end
		end;

		GetTasks = function()
			return TrackedTasks
		end;

		Events = setmetatable({}, {
			__index = function(_, EventName: string)
				return Service.GetEvent(EventName)
			end
		});

		GetEvent = function(name)
			if not HookedEvents[name] then
				--// GoodSignal has been setup to be fully backwards-compatible with the existing Events system
				local event = Service.GoodSignal.new()

				HookedEvents[name] = event
				return event
			else
				return HookedEvents[name]
			end
		end;

		HookEvent = function(name,func,env)
			if type(name) ~= "string" or type(func) ~= "function" then
				warn("Invalid argument supplied; HookEvent(string, function)")
			else
				return Service.GetEvent(name):Connect(func)
			end
		end;

		FireEvent = function(name,...)
			local event = HookedEvents[name]
			return event and event:Fire(...)
		end;

		RemoveEvents = function(name)
			local event = HookedEvents[name]
			if event then
				HookedEvents[name] = nil
				event:Destroy()
			end
		end;
	},{
		WrapIgnore = function(tab) return setmetatable(tab,{__metatable = if Main.Core and Main.Core.DebugMode then "Ignore" else nil}) end; -- Unused
		CheckWrappers = function()
			for obj,wrap in Wrappers do
				if Service.IsDestroyed(obj) then
					Wrappers[obj] = nil
				end
			end
		end;
		Wrapped = function(object)
			if type(getmetatable(object)) == "table" and rawget(getmetatable(object), "__ADONIS_WRAPPED") or getmetatable(object) == "Adonis_Proxy" then
				return true
			elseif (type(object) == "table" or typeof(object) == "userdata") and object.IsProxy and object:IsProxy() then
				return true
			else
				return false
			end
		end;
		UnWrap = function(object)
			local OBJ_Type = typeof(object)

			if OBJ_Type == "Instance" then
				return object
			elseif OBJ_Type == "table" then
				local UnWrap = Service.UnWrap
				local tab = {}
				for i, v in object do
					tab[i] = UnWrap(v)
				end
				return tab
			elseif Service.Wrapped(object) then
				return object:GetObject()
			else
				return object
			end
		end;
		Wrap = function(object, fullWrap)
			fullWrap = fullWrap or (fullWrap == nil and Client ~= nil) --// Everything Clientside should be getting wrapped anyway
			if getmetatable(object) == "Ignore" or getmetatable(object) == "ReadOnly_Table" then
				return object
			elseif Wrappers[object] then
				return Wrappers[object]
			elseif type(object) == "table" then
				local Wrap = Service.Wrap
				local tab = setmetatable({	}, {
					__eq = function(tab,val)
						return object
					end
				})
				for i,v in object do
					tab[i] = Wrap(v, fullWrap)
				end
				return tab
			elseif (typeof(object) == "Instance" or typeof(object) == "RBXScriptSignal" or typeof(object) == "RBXScriptConnection") and not Service.Wrapped(object) then
				local UnWrap = Service.UnWrap
				local sWrap = Service.Wrap

				local Wrap = (not fullWrap and function(...)
					return ...
				end) or function(obj)
					return sWrap(obj, fullWrap)
				end

				local newObj = newproxy(true)
				local newMeta = getmetatable(newObj)

				local custom; custom = {
					GetMetatable = function()
						return newMeta
					end;

					AddToCache = function()
						Wrappers[object] = newObj;
					end;
					RemoveFromCache = function()
						Wrappers[object] = nil
					end;

					GetObject = function()
						return object
					end;

					SetSpecial = function(ignore, name, val)
						custom[name] = val
						return custom
					end;

					Clone = function(self, noAdd)
						local new = object:Clone()
						if not noAdd then
							table.insert(CreatedItems, new)
						end
						return sWrap(new)
					end;

					IsWrapped = function()
						return true -- Cannot fully depend on __metatable if DebugMode is enabled
					end;

					connect = function(ignore, func)
						return Wrap(object:Connect(function(...)
							local packedResult = table.pack(...)
							return func(table.unpack(sWrap(packedResult), 1, packedResult.n))
						end))
					end;

					wait = function(ignore,...)
						return Wrap(object.wait)(object, ...)
					end;
				}

				custom.Connect = custom.connect
				custom.Wait = custom.wait

				newMeta.__index = function(tab, ind)
					local target = custom[ind] or object[ind]

					if custom[ind] then
						return custom[ind]
					elseif type(target) == "function" then
						return function(ignore, ...)
							local packedResult = table.pack(...)
							return table.unpack(Wrap({
								Methods[ind](object, unpack(UnWrap(packedResult), 1, packedResult.n))
							}))
						end
					else
						return Wrap(target)
					end
				end

				newMeta.__newindex = function(tab, ind, val)
					object[ind] = UnWrap(val)
				end

				newMeta.__eq = Service.RawEqual
				newMeta.__tostring = function() return custom.ToString or tostring(object) end
				-- Roblox doesn't respect this afaik.
				--newMeta.__gc = function(tab)
				--	custom:RemoveFromCache()
				--end
				newMeta.__metatable = if Main.Core and Main.Core.DebugMode then nil else "Adonis_Proxy"
				newMeta.__ADONIS_WRAPPED = true
				custom:AddToCache()
				return newObj
			else
				return object
			end
		end;
	},{
		CloneTable = function(tab)
			local new = (getmetatable(tab) ~= nil and setmetatable({},{
				__index = function(t, ind)
					return tab[ind]
				end
			})) or {}
			for i,v in tab do
				new[i] = v
			end
			return new
		end;

		DeepCopy = function(tab)
			local new = (getmetatable(tab) ~= nil and setmetatable({},{
				__index = function(t, ind)
					return tab[ind]
				end
			})) or {}
			for i,v in tab do
				if typeof(v) == 'table' then 
					new[i] = Service.DeepCopy(v)
				else
					new[i] = v
				end
			end
			return new
		end,

		IsLocked = function(obj) return not pcall(function() obj.Name = obj.Name return obj.Name end) end;

		Timer = function(t,func,check)
			local start = time()
			local event; event = Service.RunService.RenderStepped:Connect(function()
				if time()-start>t or (check and check()) then
					func()
					event:Disconnect()
				end
			end)
		end;

		AltUnpack = function(args,shift)
			if shift then shift = shift-1 end
			return args[1+(shift or 0)],args[2+(shift or 0)],args[3+(shift or 0)],args[4+(shift or 0)],args[5+(shift or 0)],args[6+(shift or 0)],args[7+(shift or 0)],args[8+(shift or 0)],args[9+(shift or 0)],args[10+(shift or 0)]
		end;

		ExtractLines = function(str)
			local strs = table.create(#str+1)
			local new = ""
			for i=1,#str+1 do
				if string.byte(string.sub(str, i,i)) == 10 or i == #str+1 then
					table.insert(strs,new)
					new = ""
				else
					local char = string.sub(str,i,i)
					if string.byte(char) < 32 then
						char = ""
					end
					new = new..char
				end
			end
			return strs
		end;

		Filter = function(str, from, to)
			if not utf8.len(str) then
				return "Filter Error"
			end

			local new = ""
			local lines = Service.ExtractLines(str)
			for i = 1,#lines do
				local ran,newl = pcall(function()
					return Service.TextService:FilterStringAsync(lines[i],from.UserId):GetNonChatStringForUserAsync(to.UserId)
				end)
				newl = (ran and newl) or lines[i] or ""
				if i > 1 then
					new = `{new}\n{newl}`
				else
					new = newl
				end
			end
			return new or "Filter Error"
		end;

		LaxFilter = function(str,from,cmd)  	-- @Roblox; If this function violates the filtering rules please note that this is currently the only way
			if tonumber(str) then				-- to avoid major filter related problems (like commands becoming unusable due to numbers or names being filtered)
				return str						-- Please consider dropping the filter rules down a notch or improving on the existing filtering methods
			elseif type(str) == "string" then	-- Also always feel free to message me with any concerns you have :)!
				if not utf8.len(str) then
					return "Filter Error"
				end

				if cmd and #Service.GetPlayers(from, str, {
					DontError = true;
					}) > 0 then
					return str
				else
					return Service.Filter(str, from, from)
				end
			else
				return str
			end
		end;

		BroadcastFilter = function(str, from)
			if not utf8.len(str) then
				return "Filter Error"
			end

			local new = ""
			local lines = Service.ExtractLines(str)
			for i = 1,#lines do
				local ran,newl = pcall(function() return Service.TextService:FilterStringAsync(lines[i],from.UserId):GetNonChatStringForBroadcastAsync() end)
				newl = (ran and newl) or lines[i] or ""
				if i > 1 then
					new = `{new}\n{newl}`
				else
					new = newl
				end
			end
			return new or "Filter Error"
		end;

		EscapeSpecialCharacters = function(x)
			return string.gsub(x, "([^%w])", "%%%1")
		end;

		RecursiveMtSearch = function(tab)
			for index, val in tab do 
				if typeof(val) == "table" or typeof(val) == "userdata" then
					if getmetatable(val) ~= nil or Service.RecursiveMtSearch(val) then
						return true
					end
				end
			end
			return false
		end,

		MetaFunc = function(func, filterArgs: boolean?, argumentTypes: {() -> boolean}?)
			return Service.NewProxy({
				__call = function(tab,...)
					if filterArgs then
						local success, res = pcall(function(...)
							if Service.RecursiveMtSearch({...}) then
								--// Prevent grabbing env through metatables
								return false
							end
							if argumentTypes then
								for index, val in {...} do 
									if argumentTypes[index] and not argumentTypes[index](val) then
										return false
									end
								end
							end
							return true
						end, ...)
						if not success or res == false then
							return nil
						end
					end

					local args = {pcall(func, ...)}
					local success = args[1]
					if not success then
						warn(args[2])
					else
						return table.unpack(args, 2)
					end
				end
			})
		end;


		NewProxy = function(meta)
			local newProxy = newproxy(true)
			local metatable = getmetatable(newProxy)
			metatable.__metatable = if Main.Core and Main.Core.DebugMode then nil else "Adonis_Proxy"
			metatable.__ADONIS_WRAPPED = true
			for i,v in meta do metatable[i] = v end
			return newProxy
		end;

		GetUserType = function(obj)
			local ran,err = pcall(function() local temp = obj[math.random()] end)
			if ran then
				return "Unknown"
			else
				return string.match(err, "%S+$")
			end
		end;

		CountTable = function(tab)
			local num = 0
			for _ in tab do num += 1 end
			return num
		end;

		Debounce = function(Key: any, Function: () -> (a...))
			if Debounces[Key] then
				return false
			end

			Debounces[Key] = true

			assert(pcall(Function)) --// the genius is impeccable

			Debounces[Key] = false
		end;

		Queue = function(key, func, timeout, doYield)
			if not Queues[key] then
				Queues[key] = {
					Processing = false;
					Functions = {};
				}
			end

			local queue = Queues[key]
			local tab = {
				Time = os.time();
				Running = false;
				Function = func;
				Timeout = timeout;

				Finished = false;
				Yield = doYield and Service.Yield();
			}

			table.insert(queue.Functions, tab);

			if not queue.Processing then
				Service.TrackTask(`Thread: QueueProcessor_{key}`, Service.ProcessQueue, false, queue, key);
			end

			if doYield and not tab.Finished then
				return select(2, tab.Yield:Wait());
			end
		end;

		ProcessQueue = function(queue, key)
			if queue then
				if queue.Processing then
					warn(`{key} is already Processing!`)
					return "Processing"
				else
					local funcs = queue.Functions;
					local Yield = Service.Yield();
					local function pop()
						local n = funcs[1]
						table.remove(funcs, 1)
						return n
					end;

					queue.Processing = true

					while funcs[1] ~= nil do
						local func = pop();
						func.Running = true;

						if func.Timeout then
							delay(func.Timeout, function()
								if not func.Finished then
									Yield:Release();
									warn(`Queue Timeout Reached for {key or "Unknown"}`)

									if func.Yield then
										func.Yield:Release(false, "Timeout Reached");
									end
								end
							end)
						end

						Service.TrackTask(`Thread: {key or "Unknown"}_QueuedFunction`, function()
							local r,e = xpcall(func.Function,function(e)
								func.Error = e;
								warn(`Queue Error: {key}: {e} \n {debug.traceback()}`)
							end);

							func.Running = false;
							func.Finished = true

							if func.Yield then
								func.Yield:Release(r, e)
							end

							Yield:Release();
						end,false)

						if func.Running then
							Yield:Wait();
						end
					end

					Yield:Destroy();
					queue.Processing = false;

					if key then
						Queues[key] = nil;
					end
				end
			end
		end;

		ProcessLoopQueue = function()
			for ind,data in LoopQueue do
				if not data.LastRun or (data.LastRun and time()-data.LastRun>data.Delay) then
					if data.MaxRuns and data.NumRuns and data.MaxRuns<=data.NumRuns then
						LoopQueue[ind] = nil
					else
						if data.MaxRuns and data.NumRuns then
							data.NumRuns = data.NumRuns+1
						end
						Pcall(data.Function)
						data.LastRun = time()
					end
				end
			end
		end;

		QueueItem = function(name,data)
			local new = data
			if data.MaxRuns then
				data.NumRuns = 0
			end
			LoopQueue[name] = new
		end;

		RemoveQueue = function(name)
			LoopQueue[name] = nil
		end;

		New = function(ClassName, Data, NoWrap, NoAdd)
			local NewInstance = NoWrap and Instance_new(ClassName) or Instance.new(ClassName);

			if not NewInstance then
				return;
			end;

			if not Data and NoAdd then
				return NewInstance;
			end;

			if Data then
				local Type = type(Data);

				if Type == "table" then
					local Parent = Data.Parent;

					if Service.Wrapped(Parent) then
						Data.Parent = Parent:GetObject();
					end;

					for Property, Value in Data do
						NewInstance[Property] = Value;
					end;
				elseif Type == "userdata" then
					if Service.Wrapped(Data) then
						Data = Data:GetObject();
					end;

					NewInstance.Parent = Data;
				end;
			end;

			if not NoAdd then
				table.insert(CreatedItems, NewInstance);
			end;

			return NewInstance;
		end;

		EscapeControlCharacters = function(str)
			return string.gsub(str, "%c", {
				["\a"] = "\\a",
				["\b"] = "\\b",
				["\f"] = "\\f",
				["\n"] = "\\n",
				["\r"] = "\\r",
				["\t"] = "\\t",
				["\v"] = "\\v"
			})
		end;

		SanitizeXML = function(str)
			return string.gsub(str, "['\"<>&]", {
				["'"] = "&apos;",
				["\""] = "&quot;",
				["<"] = "&lt;",
				[">"] = "&gt;",
				["&"] = "&amp;"
			})
		end;

		SanitizePattern = function(str)
			return string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
		end;

		GetCurrentLocale = function()
			if Service.RunService:IsClient() then
				local accountLocale, systemLocale = Service.LocalizationService.RobloxLocaleId, Service.LocalizationService.SystemLocaleId
				return ChangedLocale or (accountLocale ~= "en-us" and accountLocale ~= "en") and accountLocale or systemLocale ~= "" and systemLocale or "en-us"
			end
			return "en-us"
		end,

		GetTime = os.time;

		FormatTime = function(optTime, options)
			options = if options == true then {WithDate = true} else options or {}

			local formatString = options.FormatString
			if not formatString then
				formatString = options.WithWrittenDate and "LL HH:mm:ss" or (options.WithDate and "L HH:mm:ss" or "HH:mm:ss")
			end

			local timeObj = DateTime.fromUnixTimestamp(optTime or os.time())
			local success, value = pcall(timeObj.FormatLocalTime, timeObj, formatString, Service.GetCurrentLocale())
			return if success then value else timeObj:ToIsoDate()
		end;

		FormatPlayer = function(Player: Player, IncludeUserID: boolean?)
			if not Player then
				return "%UNKNOWN%";
			end;

			local UserID = Player.UserId;
			local Name = Player.Name or "???";
			local DisplayName = Player.DisplayName or "???";

			local UserIDString = if UserID ~= -1 then UserID else "";

			if Name == "[Unknown User]" then
				return `[UnknownUser{UserIDString}]`;
			end;

			return if DisplayName == Name then `@{Name}` else `{DisplayName} (@{Name}) {if IncludeUserID then ` [{UserIDString}]` else ""}`;
		end;

		FormatNumber = function(Number: number?, DoAbbreviate: boolean?, Separator: string?)
			if Number ~= Number then
				return "NaN";
			end;

			Number = tonumber(Number);

			if not Number then
				return "NaN";
			end;

			local Abs = (Number ^ 2) ^ 0.5

			if Abs >= math.huge then
				return "Inf";
			end;

			Separator = Separator or ",";

			local Integer, Decimal = table.unpack(string.split(Abs, "."));

			if DoAbbreviate and Abs >= 1000 then
				local ABBREVIATIONS = { "K", "M", "B", "T", "Qd", "Qi" };

				local Thousands = (#Integer - 1) // 3;
				local Suffix = ABBREVIATIONS[Thousands];

				if Suffix then
					return `{string.format("%.2f", Number / (10 ^ (3 * Thousands)))}{Suffix}`;
				end;

				return `{Service.FormatNumber(Number / 1000000000000000000, false, Separator)}{ABBREVIATIONS[6]}`;
			end;

			Integer = string.reverse(Integer);

			local NewInteger = "";
			local Counter = 1;

			for Index = 1, #Integer do
				if Counter > 3 then
					NewInteger ..= Separator;
					Counter = 1;
				end;

				NewInteger ..= string.sub(Integer, Index, Index);
				Counter += 1;
			end;

			return `{(if Number < 0 then "-" else "")}{string.reverse(NewInteger)}{if Decimal then `.{Decimal}` else ""}`;
		end;

		OwnsAsset = function(...)
			return Service.CheckAssetOwnership(...)
		end;

		GetProductInfo = function(AssetID, InfoType)
			AssetID = tonumber(AssetID);

			if not AssetID then
				return;
			end;

			InfoType = InfoType or Enum.InfoType.Asset;

			local CacheIndex = `{AssetID}-{InfoType}`
			local Cache = assetInfoCache[CacheIndex];

			if not Cache then
				Cache = {
					results = { Created = false },
					lastUpdated = os.clock(),
				};

				assetInfoCache[CacheIndex] = Cache;
			end;

			local CanUpdateCache = not Cache.LastUpdated or os.clock() - Cache.LastUpdated > 120;

			if CanUpdateCache then
				local MarketplaceService = Service.MarketplaceService
				local Success, Info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, AssetID, InfoType);

				if Success and type(Info) == "table" then
					Info.Created = true;
					Cache.results = Info;
				else
					Cache.results.Created = false;
				end;
			end;

			return table.clone(Cache.results);
		end;

		CheckPassOwnership = function(userId, gamepassId)
			userId = if type(userId) == "userdata" then userId.UserId else tonumber(userId)
			gamepassId = tonumber(gamepassId)

			local cacheIndex = `{userId}-{gamepassId}`
			local currentCache = passOwnershipCache[cacheIndex]

			if currentCache and currentCache.owned then
				return true
			elseif (currentCache and (os.time()-currentCache.lastUpdated > 60)) or not currentCache then
				local cacheTab = {
					owned = (currentCache and currentCache.owned) or false;
					lastUpdated = os.time();
				}
				passOwnershipCache[cacheIndex] = cacheTab

				local suc,ers = pcall(function()
					return Service.MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
				end)

				if suc then
					cacheTab.owned = toBoolean(ers)
					return toBoolean(ers)
				else
					return cacheTab.owned
				end
			elseif currentCache then
				return currentCache.owned
			end
		end;

		CheckAssetOwnership = function(player, assetId)
			if type(player) == "number" then
				player = Service.Players:GetPlayerByUserId(player)
			end

			local cacheIndex = `{player.UserId}-{assetId}`
			local currentCache = assetOwnershipCache[cacheIndex]

			if currentCache and currentCache.owned then
				return true
			elseif (currentCache and (os.time()-currentCache.lastUpdated > 60)) or not currentCache then
				local cacheTab = {
					owned = (currentCache and currentCache.owned) or false;
					lastUpdated = os.time();
				}
				passOwnershipCache[cacheIndex] = cacheTab

				local suc,ers = pcall(function()
					return Service.MarketplaceService:PlayerOwnsAsset(player, assetId)
				end)

				if suc then
					cacheTab.owned = toBoolean(ers)
				end

				return cacheTab.owned
			elseif currentCache then
				return currentCache.owned
			end
		end;

		GetGroupInfo = function(groupId)
			groupId = tonumber(groupId) or 0

			if groupId > 0 then
				local existingCache = groupInfoCache[groupId]
				local canUpdate = not existingCache or os.time()-existingCache.lastUpdated > 120

				if canUpdate then
					existingCache = {
						results = (existingCache and existingCache.results) or {};
						lastUpdated = os.time();
					}
					groupInfoCache[groupId] = existingCache

					local suc,info = pcall(Service.GroupService.GetGroupInfoAsync, Service.GroupService, groupId)

					if suc and type(info) == "table" then
						existingCache.results = info
					else
						existingCache.results.Failed = true
					end
				end

				return Service.CloneTable(existingCache.results)
			end
		end;

		GetGroupCreatorId = function(groupId)
			groupId = tonumber(groupId) or 0

			if groupId > 0 then
				local groupInfo = Service.GetGroupInfo(groupId)

				if groupInfo and groupInfo.Owner then
					return groupInfo.Owner.Id
				end
			end

			return 0
		end,

		MaxLen = function(Message: string, Length: number)
			if #Message > Length then
				return `{string.sub(Message, 1, Length)}...`
			end

			return Message
		end;

		Yield = function()
			local Signal = Service.GoodSignal.new()
			local Yield = { Event = Signal }

			function Yield.Release(...)
				return Signal:Fire(...)
			end

			function Yield:Wait()
				return Signal:Wait()
			end

			function Yield:Destroy()
				return Signal:Destroy()
			end

			return Yield
		end,

		StartLoop = function(Name, DelayMethod, Function, NoYielding)
			local LoopInstance = {
				Name = Name,
				Delay = DelayMethod,
				Function = Function,
				Running = true,
			};

			local Index = `{Name} - {HttpService:GenerateGUID(false)}`;

			local function Kill()
				LoopInstance.Running = false;

				if RunningLoops[Index] == LoopInstance then
					RunningLoops[Index] = nil;
				end;
			end;

			LoopInstance.Kill = Kill;
			RunningLoops[Index] = LoopInstance;

			local function Loop()
				local WaitEvent = nil;
				local DelayTime = tonumber(DelayMethod);

				if DelayTime then
					-- Set time looping

					while RunningLoops[Index] == LoopInstance and LoopInstance.Running do
						task.wait(DelayTime);

						Function();
					end;

					return Kill();
				end;

				local RunService = Service.RunService
				local WaitEvent = RunService[DelayMethod];

				if not WaitEvent then
					LoopInstance.Running = false;
					return;
				end;

				if typeof(WaitEvent) ~= "RBXScriptSignal" then
					LoopInstance.Running = false;
					return;
				end

				while RunningLoops[Index] == LoopInstance and LoopInstance.Running do
					Function();

					WaitEvent:Wait();
				end;

				return Kill();
			end;

			if NoYielding then
				Service.TrackTask(`Thread: Loop: {Name}`, Loop, false);
			else
				Service.TrackTask(`Loop: {Name}`, Loop, false);
			end;

			return LoopInstance;
		end;
		StopLoop = function(name)
			for ind,loop in RunningLoops do
				if name == loop.Function or name == loop.Name then
					loop.Running = false
				end
			end
		end;
		IsLooped = function(name)
			for cat,loop in RunningLoops do
				if name == loop.Function or name == loop.Name then
					return loop.Running
				end
			end
			return false
		end;
		ReadOnly = function(tabl, excluded, killOnError, noChecks)
			local doChecks = (not noChecks) and Service.RunService:IsClient()
			if Main.Core and Main.Core.DebugMode then 
				doChecks = false
			end
			doChecks = false
			local player = doChecks and Service.Players.LocalPlayer
			local kick = player and player.Kick
			local settings, getMeta, get, pc, resume, create = getfenv().settings, getmetatable, getfenv, pcall, coroutine.resume, coroutine.create
			local unique = doChecks and getMeta(get())
			local checkFor = doChecks and {
				secret500 = true;
				getrawmetatable = true;
				setreadonly = true;
				full_access = true;
				elysianexecute = true;
				decompile = true;
				make_writable = true;
				hookmetamethod = true;
				hookfunction = true;
			}

			return Service.NewProxy {
				__index = function(tab, ind)
					local ind = (type(ind) ~= "table" and typeof(ind) ~= "userdata") and ind or "Potentially dangerous index"

					local topEnv = doChecks and get and get(2)
					local setRan = doChecks and pcall(settings)
					if doChecks and (setRan or (get ~= getfenv or getMeta ~= getmetatable or pc ~= pcall) or (not topEnv or type(topEnv) ~= "table" or getMeta(topEnv) ~= unique)) then
						ErrorHandler("ReadError", "Tampering with Client [read rt0001]", `[{ind} {topEnv} {topEnv and getMeta(topEnv)}]\n{debug.traceback()}`)
					elseif tabl[ind]~=nil and type(tabl[ind]) == "table" and not (excluded and (excluded[ind] or excluded[tabl[ind]])) then
						return Service.ReadOnly(tabl[ind], excluded, killOnError, noChecks)
					else
						return tabl[ind]
					end
				end;

				__newindex = function(tab,ind,new)
					local ind = (type(ind) ~= "table" and typeof(ind) ~= "userdata") and ind or "Potentially dangerous index"

					local topEnv = doChecks and get and get(2)
					local setRan = doChecks and pcall(settings)
					if doChecks and (setRan or (get ~= getfenv or getMeta ~= getmetatable or pc ~= pcall) or (not topEnv or type(topEnv) ~= "table" or getMeta(topEnv) ~= unique)) then
						ErrorHandler("ReadError", "Tampering with Client [write wt0003]", `[{ind} {topEnv} {topEnv and getMeta(topEnv)}]\n{debug.traceback()}`)
					elseif not (excluded and (excluded[ind] or excluded[tabl[ind]])) then
						if killOnError then
							ErrorHandler("ReadError", "Tampering with Client [write wt0005]", `[{ind} {topEnv} {topEnv and getMeta(topEnv)}]\n{debug.traceback()}`)
						end

						warn(`Something attempted to set index {ind} in a read-only table.`)
					else
						rawset(tabl, ind, new)
					end
				end;

				__metatable = if Main.Core and Main.Core.DebugMode then unique else "ReadOnly_Table"; -- Allow ReadOnly table's metadata to be modified if DebugMode is enabled
			}
		end;
		HasItem = function(Object: Instance | userdata, Property: string?) return pcall(function() return Object[Property] end) end;
		IsDestroyed = function(object)
			if type(object) ~= "userdata" then
				return false;
			end;

			local HasItem, Parent = Service.HasItem(object, "Parent");

			if not HasItem then
				return false;
			end

			if Parent == nil then
				local Success, Error = pcall(function()
					object.Parent = game;
					object.Parent = nil;
				end);

				if not Success then
					return Error and (string.match(Error, "^The Parent property of (.*) is locked, current parent: NULL,") ~= nil);
				end;
			end;

			return false;
		end;
		OutfitCache = {},
		UnallowedCache = {},
		Insert = function(id, rawModel)
			if Service.UnallowedCache and Service.UnallowedCache[id] then return end
			local model = Service.InsertService:LoadAsset(id)
			if not rawModel and model:IsA("Model") and model.Name == "Model" then
				local asset = model:GetChildren()[1]
				asset.Parent = model.Parent
				model:Destroy()
				return asset
			end
			return model
		end,
		SecureAccessory = function(plr, itemId)
			if not plr.Character then return end

			local function reject()
				Service.UnallowedCache[tonumber(itemId)] = true
				error("Item not supported")
			end

			local success, item = pcall(function() return Service.Insert(tonumber(itemId)) end)
			if not success then return reject() end
			if not item then return reject() end
			if not item:IsA("Accoutrement") then return reject() end
			if not item:FindFirstChild("Handle") then return reject() end
			if #item:GetDescendants() > 250 then return reject() end
			item.Name = "CustomAdonisAccessory"
			item:SetAttribute("AssetId", itemId)

			-- No classes except those in whitelistedClasses are allowed
			local whitelistedClasses = {"Accoutrement", "BasePart", "SpecialMesh", "Attachment", "Weld", "WeldConstraint", "Motor6D", "Folder", "ValueBase", "ParticleEmitter", "Sparkles", "Fire"}
			local blacklistedClasses = {"LuaSourceContainer", "Model", "Tool", "Hopperbin"} -- extra security

			for i,v in item:GetDescendants() do
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end

			-- If a blacklisted class is found, cancel the command
			for i,v in item:GetDescendants() do
				local blacklisted = false
				for _,x in blacklistedClasses do
					if v:IsA(x) then
						blacklisted = true
						break
					end
				end
				if blacklisted then
					return reject()
				end
			end

			-- If a non-whitelisted class is found, delete it
			for i,v in item:GetDescendants() do 
				local allowed = false
				for _,x in whitelistedClasses do
					if v:IsA(x) then
						allowed = true
						break
					end
				end
				if not allowed then
					v:Destroy()
				end
			end

			plr.Character.Humanoid:AddAccessory(item)
		end,
		GetPlayers = function() return Service.Players:GetPlayers() end;
		IsAdonisObject = function(obj) for i,v in CreatedItems do if v == obj then return true end end end;
		GetAdonisObjects = function() return CreatedItems end;
	}

	Service = setmetatable({
		Variables = function() return ServiceVariables end;
		Running = true;
		Pcall = Pcall;

		DataModel = game;
		MarketPlace = game:GetService("MarketplaceService");
		GamepassService = game:GetService("GamePassService");
		ChatService = game:GetService("Chat");
		Gamepasses = game:GetService("GamePassService");
		Delete = function(obj,num) game:GetService("Debris"):AddItem(obj,(num or 0)) pcall(obj.Destroy, obj) end;
		RbxEvent = function(signal, func) local event = signal:Connect(func) table.insert(RbxEvents, event) return event end;
		SelfEvent = function(signal, func) local rbxevent = Service.RbxEvent(signal, function(...) func(...) end) end;
		DelRbxEvent = function(signal) for i,v in RbxEvents do if v == signal then v:Disconnect() table.remove(RbxEvents, i) end end end;
		SanitizeString = function(str) str = Service.Trim(str) local new = "" for i = 1,#str do if string.sub(str,i,i) ~= "\n" and string.sub(str,i,i) ~= "\0" then new = new..string.sub(str,i,i) end end return new end;
		Trim = function(str) return string.match(str,"^%s*(.-)%s*$") end;
		Localize = function(obj, readOnly) local Localize = Service.Localize local ReadOnly = Service.ReadOnly if type(obj) == "table" then local newTab = {} for i in obj do newTab[i] = Localize(obj[i], readOnly) end return (readOnly and ReadOnly(newTab)) or newTab else return obj end end;
		RawEqual = function(obj1, obj2) return Service.UnWrap(obj1) == Service.UnWrap(obj2) end;
		CheckProperty = function(obj,prop) return pcall(function() return obj[prop] end) end;
		NewWaiter = function() local event = Service.New("BindableEvent") return {Wait = event.wait; Finish = event.Fire} end;
	},{
		__index = function(tab, index)
			local found = (fenceSpecific and fenceSpecific[index]) or Wrapper[index] or Events[index] or Helpers[index]

			if found then
				return found
			else
				local ran, serv = pcall(function()
					local gameService = game:GetService(index)
					return (Client ~= nil and Service.Wrap(gameService, true)) or gameService
				end)

				if ran and serv then
					Service[index] = serv
					return serv
				end
			end
		end;
		__tostring = "Service";
		__metatable = if Main.Core and Main.Core.DebugMode then nil else "Service";
	})

	Service.GoodSignal = require(script.Parent.GoodSignal)

	if Client ~= nil then
		for Index, Value in Service do
			if type(Value) == "userdata" then
				Service[Index] = Service.Wrap(Value, true)
			end
		end
	end

	if Service.RunService:IsClient() then
		task.spawn(xpcall, function()
			local LocalizationService = Service.LocalizationService
			local Translator = LocalizationService:GetTranslatorForPlayerAsync(Service.Players.LocalPlayer)

			Translator:GetPropertyChangedSignal("LocaleId"):Connect(function()
				ChangedLocale = Translator.LocaleId
			end)
		end, warn)
	end

	return Service
end
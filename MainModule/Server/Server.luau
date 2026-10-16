----------------------------------------------------------------------------------------
--						   	Astra Admin (public version) v3						 	  --
----------------------------------------------------------------------------------------
--		 							By: krampuszc	   		 						  --
--		 				  8ch_32bit was here lololololololololololo		   		 	  --
----------------------------------------------------------------------------------------

--// Module LoadOrder List; Core modules need to be loaded in a specific order; If you create new "Core" modules make sure you add them here or they won't load
local CORE_LOADING_ORDER = table.freeze({
	--// Nearly all modules rely on these to function
	"Logs";
	"Variables";
	"Functions";

	--// Core functionality
	"Core";
	"Remote";
	"Process";

	--// Misc
	"Permissions";
	"Admin";
	"HTTP";
	"Anti";
	"Commands";
})

--// Todo:
--//  Win.

--// Holiday roooaaAaaoooAaaooOod
--// I WANT SUMMER
--// ITS TOO COLD
--// WHEN I SAID I WANTED SUMMER I DIDN'T MEAN THIS

local SERVICES_WE_USE = table.freeze({
	"Workspace";
	"Players";
	"Lighting";
	"ServerStorage";
	"ReplicatedStorage";
	"JointsService";
	"ReplicatedFirst";
	"ScriptContext";
	"ServerScriptService";
	"LogService";
	"Teams";
	"SoundService";
	"StarterGui";
	"StarterPack";
	"StarterPlayer";
	"GroupService";
	"MarketplaceService";
	"TestService";
	"HttpService";
	"RunService";
	"InsertService";
	"NetworkServer";
})

local unique = {};
local origEnv = {};

local locals
local server
local service
local RbxEvents = {}
local ErrorLogs = {}
local HookedEvents = {}
local ServiceSpecific = {}
local oldReq = require
local Folder = script.Parent
local oldInstNew = Instance.new


local print = function(...)
	print("Astra Server :: ", ...)
end

local warn = function(...)
	warn("Astra Server :: ", ...)
end;

local function CloneTable(tab, recursive)
	if not recursive then
		return table.clone(tab);
	end;

	local clone = {};

	for index, value in tab do
		if typeof(value) == "table" then
			clone[index] = CloneTable(value, recursive);
		end;
	end;

	return clone;
end;

local LogError = function(Player, Error)
	if not Error then
		Error = Player
		Player = nil
	end

	if server.Core.DebugMode then
		warn(`Astra Server Error: {Player}: {Error}`)
	end

	local Logs = server.Logs

	if Logs then

		--if not Logs.Errors then
			Logs.Errors = server.DLL.new()
		--end -- broke and im lazy
		Logs.AddLog("Errors", {
			Text = `{if Error and Player then `{Player}: ` else ''}{Error}`,
			Desc = Error,
			Player = Player,
		});
	end
end;

local function Pcall(func, ...)
	local Success, Error = pcall(func, ...)

	if not Success then
		warn(Error); LogError(Error);
	end;

	return Success, Error;
end;

local function GetEnv(env, repl)
	local scriptEnv = setmetatable({}, {
		__index = function(tab, ind)
			return (locals[ind] or (env or origEnv)[ind])
		end;

		__metatable = unique;
	});

	if repl and typeof(repl) == "table" then
		for ind, val in (repl) do
			scriptEnv[ind] = val;
		end;
	end;

	return scriptEnv
end

local function GetVargTable()
	return {
		Server = server;
		Service = service;
	};
end;

local function LoadModule(module, yield, envVars, _, isCore)
	local isFunc = type(module) == "function"
	local _module = (isFunc and service.New("ModuleScript", {Name = "Non-Module Loaded"})) or module
	local plug = (isFunc and module) or require(module)

	if server.Modules and type(module) ~= "function" then
		table.insert(server.Modules,module)
	end

	if type(plug) == "function" then
		-- local args = debug.info(plug, "a")
		-- if args == 0 then
		-- 	error("Plugins enforce a NoEnv policy, make sure your plugin has the 2nd argument defined!")
		-- end
		if isCore then
			local _ran, err = service.TrackTask(
				`CoreModule: {module}`,
				plug,
				function(err)
					warn(`Module encountered an error while loading: {module}\n{err}\n{debug.traceback()}`)
				end,
				GetVargTable(),
				GetEnv
			)
			return err
		else
			local _ran, err = service.TrackTask(
				`Plugin: {module}`,
				plug,
				function(err)
					warn(`Module encountered an error while loading: {module}\n{err}\n{debug.traceback()}`)
				end,
				GetVargTable()
			)
			return err
		end
	else
		server[module.Name] = plug
	end

	if server.Logs then
		server.Logs.AddLog(server.Logs.Script,{
			Text = `Loaded Module: {module}`;
			Desc = "Astra loaded a core module or plugin";
		})
	end

	return
end

local function CleanUp()
	print("Beginning Astra cleanup process...")

	local data = service.UnWrap(server.Data)
	
	if type(data) == "table" and typeof(service.UnWrap(data.Config)) == "Instance" then
		local Settings: ModuleScript = service.UnWrap(data.Config):FindFirstChild("Settings")
		if typeof(Settings) == "Instance" and Settings:IsA("ModuleScript") then
			pcall(function()
				table.clear(require(Settings))
			end)
		end
	end

	server.Model.Name = "Astra_Loader"
	server.Model.Parent = service.ServerScriptService
	server.Running = false

	server.Logs.SaveCommandLogs()
	server.Core.GAME_CLOSING = true;
	server.Core.SaveAllPlayerData()

	pcall(function()
		for i, v in (RbxEvents) do
			print("Disconnecting event")
			v:Disconnect()
			table.remove(RbxEvents, i)
		end
	end)
	
	if server.Core and server.Core.RemoteEvent then
		pcall(server.Core.DisconnectEvent)
	end

	print("Unloading complete.")
end;

server = {
	Running = true;
	Modules = {};
	Pcall = Pcall;
	LogError = LogError;
	ErrorLogs = ErrorLogs;
	ServerStartTime = os.time();
	CommandCache = {};
};

locals = {
	server = server;
	CodeName = "";
	Settings = server.Settings;
	HookedEvents = HookedEvents;
	ErrorLogs = ErrorLogs;
	logError = LogError;
	origEnv = origEnv;
	Folder = Folder;
	GetEnv = GetEnv;
	Pcall = Pcall;
};

local Shared = Folder.Parent.Shared
Shared.Parent = Folder
service = require(Shared.Service)(function(eType, msg, desc, ...)
	local extra = {...}
	if eType == "MethodError" then
		if server and server.Logs and server.Logs.AddLog then
			server.Logs.AddLog("Script", {
				Text = `Cached method doesn't match found method: {extra[1]}`;
				Desc = `Method: {extra[1]}`
			})
		end
	elseif eType == "ServerError" then
		LogError("Server", msg)
	elseif eType == "TaskError" then
		LogError("Task", msg)
	end
end, ServiceSpecific, GetEnv(nil, {server = server}))

--// Wrap
local Instance = {
	new = function(obj, parent)
		return oldInstNew(obj, service.UnWrap(parent))
	end,
};

local require = function(obj)
	return oldReq(service.UnWrap(obj));
end;

local rawequal = service.RawEqual

server.Folder = Folder
server.Deps = Folder.Dependencies;
server.CommandModules = Folder.Commands;
server.Client = Folder.Parent.Client;
server.Dependencies = Folder.Dependencies;
server.PluginsFolder = Folder.Plugins;
server.Service = service
server.Typechecker = require(Shared.Typechecker)
server.GroupService = oldReq(Shared.GroupService)
-- server.SwitchNet = oldReq(Shared.SwitchNet) -- Actually can't be bothered to port over the support rn lol
server.DLL = oldReq(Shared.DoubleLinkedList)

--// Setting things up
for ind, loc in ipairs({
	_G = _G;
	game = game;
	spawn = task.spawn;
	script = script;
	workspace = workspace;
	getmetatable = getmetatable;
	setmetatable = setmetatable;
	loadstring = loadstring;
	coroutine = coroutine;
	rawequal = rawequal;
	typeof = typeof;
	print = print;
	math = math;
	warn = warn;
	error = error;
	assert = assert;
	pcall = pcall;
	xpcall = xpcall;
	select = select;
	rawset = rawset;
	rawget = rawget;
	ipairs = ipairs;
	pairs = pairs;
	next = next;
	Rect = Rect;
	Axes = Axes;
	os = os;
	time = time;
	Faces = Faces;
	unpack = unpack;
	string = string;
	Color3 = Color3;
	newproxy = newproxy;
	tostring = tostring;
	tonumber = tonumber;
	Instance = Instance;
	TweenInfo = TweenInfo;
	BrickColor = BrickColor;
	NumberRange = NumberRange;
	ColorSequence = ColorSequence;
	NumberSequence = NumberSequence;
	ColorSequenceKeypoint = ColorSequenceKeypoint;
	NumberSequenceKeypoint = NumberSequenceKeypoint;
	PhysicalProperties = PhysicalProperties;
	Region3int16 = Region3int16;
	Vector3int16 = Vector3int16;
	require = require;
	table = table;
	type = type;
	wait = task.wait;
	Enum = Enum;
	UDim = UDim;
	UDim2 = UDim2;
	Vector2 = Vector2;
	Vector3 = Vector3;
	Region3 = Region3;
	CFrame = CFrame;
	Ray = Ray;
	task = task;
	service = service
}) do
	locals[ind] = loc
end

--// Init
return service.NewProxy({
	__call = function(_, data)
		
		local mutex = service.RunService:FindFirstChild("__Adonis_MODULE_MUTEX")
		local OtherMutex = _G["__Kronos_MODULE_MUTEX"] and type(_G["__Kronos_MODULE_MUTEX"])=="string" -- why not
		-- you never know.
		if mutex or OtherMutex then
			warn("\n-----------------------------------------------"
				.."\nAstra server is already running! Aborting..."
				.."\n-----------------------------------------------")
			script:Destroy()
			return "FAILED"
		else
			mutex = service.New("StringValue", {Name = "__Adonis_MODULE_MUTEX", Value = "Running"})
			local mutexBackup = mutex:Clone()
			local function makePersistent(m)
				local connection1, connection2 = nil, nil
				connection1 = m:GetPropertyChangedSignal("Parent"):Connect(function()
					if not m or m.Parent ~= service.RunService then
						connection1:Disconnect()
						connection2:Disconnect()
						warn("Adonis module mutex removed; Regenerating...")
						mutex = mutexBackup:Clone()
						mutex.Archivable = false
						mutex.Parent = service.RunService
						makePersistent(mutex)
					end
				end)
				connection2 = m:GetPropertyChangedSignal("Name"):Connect(function()
					if m and m.Name ~= "__Adonis_MODULE_MUTEX" then
						warn("Adonis module mutex renamed; Refreshing...")
						m.Name = "__Adonis_MODULE_MUTEX"
					end
				end)
			end
			makePersistent(mutex)
			mutex.Archivable = false
			mutex.Parent = service.RunService
		end
		
		if not (data and data.Loader) then
			warn("WARNING: MainModule loaded without using the loader!")
		end

		--// Server Variables
		local setTab = require(server.Deps.DefaultSettings);

		server.Defaults = setTab
		server.Settings = data.Settings or setTab.Settings or {}
		server.OriginalSettings = CloneTable(server.Settings, true)
		server.Descriptions = data.Descriptions or setTab.Descriptions or {}
		server.Messages = data.Messages or setTab.Settings.Messages or {}
		server.Order = data.Order or setTab.Order or {}
		server.Data = data or {}
		server.Model = data.Model or service.New("Model")
		server.ModelParent = data.ModelParent or service.ServerScriptService;
		server.Loader = data.Loader
		server.Runner = data.Runner
		server.LoadModule = LoadModule
		server.ServiceSpecific = ServiceSpecific

		server.Shared = Shared
		server.ServerPlugins = data.ServerPlugins
		server.ClientPlugins = data.ClientPlugins
		server.Client = Folder.Parent.Client

		locals.Settings = server.Settings
		locals.CodeName = server.CodeName

		--// THIS NEEDS TO BE DONE **BEFORE** ANY EVENTS ARE CONNECTED
		if server.Settings.HideScript and data.Model then
			data.Model.Parent = nil
			script:Destroy()
		end

		--// Copy client themes, plugins, and shared modules to the client folder
		local shared = Shared:Clone()
		shared.Parent = server.Client
		
		for _, module in ipairs(data.ClientPlugins or {}) do
			module:Clone().Parent = server.Client.Plugins
		end

		for _, theme in ipairs(data.Themes or {}) do
			theme:Clone().Parent = server.Client.UI
		end

		for setting, value in (server.Defaults.Settings) do
			if server.Settings[setting] == nil then
				server.Settings[setting] = value
			end
		end

		for desc, value in (server.Defaults.Descriptions) do
			if server.Descriptions[desc] == nil then
				server.Descriptions[desc] = value
			end
		end

		--// Bind cleanup
		game:BindToClose(CleanUp)

		--// Load services
		for ind, serv in (SERVICES_WE_USE) do
			local _temp = service[serv]
		end

		--// Load core modules
		for _, load in (CORE_LOADING_ORDER) do
			local CoreModule = Folder.Core:FindFirstChild(load)
			if CoreModule then
				LoadModule(CoreModule, true, nil, nil, true) --noenv, CoreModule
			end
		end

		--// Server Specific Service Functions
		ServiceSpecific.GetPlayers = server.Functions.GetPlayers

		--// Initialize Cores
		local runLast = {}
		local runAfterInit = {}
		local runAfterPlugins = {}

		for _, name in (CORE_LOADING_ORDER) do
			local core = server[name];

			if core then
				if type(core) == "table" or (type(core) == "userdata" and getmetatable(core) == "ReadOnly_Table") then
					if core.RunLast then
						table.insert(runLast, core.RunLast)
						core.RunLast = nil
					end

					if core.RunAfterInit then
						table.insert(runAfterInit, core.RunAfterInit)
						core.RunAfterInit = nil
					end

					if core.RunAfterPlugins then
						table.insert(runAfterPlugins, core.RunAfterPlugins)
						core.RunAfterPlugins = nil
					end

					if core.Init then
						core.Init(data)
						core.Init = nil
					end;
				end;
			end;
		end;


		--// Load any afterinit functions from modules (init steps that require other modules to have finished loading)
		for _, f in (runAfterInit) do
			f(data)
		end

		--// Load Plugins; enforced NoEnv policy, make sure your plugins has the 2nd argument defined!
		for _, module in (server.PluginsFolder:GetChildren()) do
			LoadModule(module, false, {script = module}, nil, true)
		end

		for _, module in ipairs(data.ServerPlugins or {}) do
			task.defer(xpcall, LoadModule, function(reason)
				warn(`The plugin {type(module) == "string" and string.sub(module, 1, 15) or module} failed to load! Reason: {reason}`)
				LogError(`The plugin {type(module) == "string" and string.sub(module, 1, 15) or module} failed to load! Reason: {reason}`)
				table.insert(server.Messages, {
					Title = `The plugin {type(module) == "string" and string.sub(module, 1, 15) or module} failed to load!`,
					Icon = "maticon://Dangerous",
					Message = string.match(reason, "Requested module experienced an error while loading") and "The plugin has invalid code or the code fails before return!" or string.match(reason, "Module code did not return exactly one value") and "The plugin returns an invalid amount of values or returns nothing at all!" or `Reason {reason}`,
					Time = 15
				})
			end, module, false, {script = module, cPcall = server.cPcall})
		end

		--// We need to do some stuff *after* plugins are loaded (in case we need to be able to account for stuff they may have changed before doing something, such as determining the max length of remote commands)
		for _, f in (runAfterPlugins) do
			f(data)
		end

		--// Below can be used to determine when all modules and plugins have finished loading; service.Events.AllModulesLoaded:Connect(function() doSomething end)
		server.AllModulesLoaded = true
		service.Events.AllModulesLoaded:Fire(os.time())

		--// Stuff to run after absolutely everything else has had a chance to run and initialize and all that
		for _, f in (runLast) do
			f(data)
		end;

		local Loader = data.Loader;

		print(`Loading complete; {if Loader then `Required by {Loader:GetFullName()}` else 'No loader location provided'}`);

		local Logs = server.Logs;

		if Logs then
			Logs.AddLog(Logs.Script, {
				Text = "Finished Loading";
				Desc = "Astra has finished loading";
			});
		else
			warn("CRITICAL ERROR! SERVER.LOGS TABLE IS MISSING. THIS SHOULDN'T HAPPEN! SOMETHING WENT WRONG WHILE LOADING CORE MODULES(?)");
		end;

		service.Events.ServerInitialized:Fire();

		Logs.Errors = server.DLL.new()

		return "SUCCESS"
	end;

	__tostring = function()
		return "Astra"
	end;

	__metatable = nil; -- This is now set in __call if DebugMode isn't enabled.
});
----------------------------------------------------------------------------------------
--						   	Astra Remotely Integrated Defense v3 (ARIDe)		 	  --
----------------------------------------------------------------------------------------
--		 					By: krampsuzc - Engineering the future.				   	  --
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
--//   Fix a loooootttttttt of bugged commands
--//   Probably a lot of other stuff idk
--//   Transform from Sceleratis into Dr. Sceleratii; Evil alter-ego; Creator of bugs, destroyer of all code that is good
--//   Maybe add a celery command at some point (wait didn't we do this?)
--//   Say hi to people reading the script
--//   ...
--//   "Hi." - Me
--//	Your mom
--//	Astra will win.
--//	"ARIDe" was a joke release of this admin system with some features a lot of people requested
--// 	but werent useful for our usecase of the system

--// Holiday roooaaAaaoooAaaooOod

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
local origEnv = getfenv();

local locals = {}
local server = {}
local service = {}
local RbxEvents = {}
local ErrorLogs = {}
local HookedEvents = {}
local ServiceSpecific = {}
local oldReq = require
local Folder = script.Parent
local oldInstNew = Instance.new

local __Modules = server.Modules;

local isModule = function(module)
	for ind, modu in (__Modules) do
		if module == modu then
			return true
		end
	end

	return false
end

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

local function LoadModule(module, yield, envVars, noEnv, isCore)
	noEnv = true --// Seems to make loading take longer when true (?)
	local isFunc = type(module) == "function"
	local module = (isFunc and service.New("ModuleScript", {Name = "Non-Module Loaded"})) or module
	local plug = (isFunc and module) or require(module)

	if server.Modules and type(module) ~= "function" then
		table.insert(server.Modules,module)
	end

	if type(plug) == "function" then
		if isCore then
			local ran, err = service.TrackTask(
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
			local ran, err = service.TrackTask(
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
end

local function CleanUp()
	print("Beginning Astra cleanup process...")
	print('Bailing out, you are on your own now. Good luck.')

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


--// Localize
local os = service.Localize(os)
local math = service.Localize(math)
local table = service.Localize(table)
local string = service.Localize(string)
local coroutine = service.Localize(coroutine)
local Instance = service.Localize(Instance)
local Vector2 = service.Localize(Vector2)
local Vector3 = service.Localize(Vector3)
local CFrame = service.Localize(CFrame)
local UDim2 = service.Localize(UDim2)
local UDim = service.Localize(UDim)
local Ray = service.Localize(Ray)
local Rect = service.Localize(Rect)
local Faces = service.Localize(Faces)
local Color3 = service.Localize(Color3)
local NumberRange = service.Localize(NumberRange)
local NumberSequence = service.Localize(NumberSequence)
local NumberSequenceKeypoint = service.Localize(NumberSequenceKeypoint)
local ColorSequenceKeypoint = service.Localize(ColorSequenceKeypoint)
local PhysicalProperties = service.Localize(PhysicalProperties)
local ColorSequence = service.Localize(ColorSequence)
local Region3int16 = service.Localize(Region3int16)
local Vector3int16 = service.Localize(Vector3int16)
local BrickColor = service.Localize(BrickColor)
local TweenInfo = service.Localize(TweenInfo)
local Axes = service.Localize(Axes)
local task = service.Localize(task)

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

--service.Players = service.Wrap(service.Players)
--Folder = service.Wrap(Folder)

server.Folder = Folder
server.Deps = Folder.Dependencies;
server.CommandModules = Folder.Commands;
server.Client = Folder.Parent.Client;
server.Dependencies = Folder.Dependencies;
server.PluginsFolder = Folder.Plugins;
server.Service = service
server.Typechecker = require(Shared.Typechecker)
server.GroupService = oldReq(Shared.GroupService)
server.DLL = oldReq(Shared.DoubleLinkedList)
--// Setting things up
for ind, loc in ipairs({
	_G = _G;
	game = game;
	spawn = spawn;
	script = script;
	getfenv = getfenv;
	setfenv = setfenv;
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
	wait = wait;
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

local RunService = service.RunService;

--// Init
return service.NewProxy({
	__call = function(_, data)
		--// Begin Script Loading
		--data = service.Wrap(data or {})

		if not (data and data.Loader) then
			warn("WARNING: MainModule loaded without using the loader!")
		end

		--if data and data.DebugMode == true then
		--	local ARIDeDebugEnabled = service.New("BoolValue");
		--	ARIDeDebugEnabled.Name = "ASTRA_DEBUGMODE_ENABLED";
		--	ARIDeDebugEnabled.Value = true;
		--	ARIDeDebugEnabled.Parent = Folder.Parent.Client;
		--end

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
		local packagesToRunWithPlugins = {}
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
			local temp = service[serv]
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
		--// Experimental, may have issues with ARIDe tables that are protected metatables
		--ServiceSpecific.CloneTable = CloneTable

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

		--// Variables that rely on core modules being initialized
		--server.Logs.Errors = ErrorLogs

		--// Load any afterinit functions from modules (init steps that require other modules to have finished loading)
		for _, f in (runAfterInit) do
			f(data)
		end

		--// Load Plugins; enforced NoEnv policy, make sure your plugins has the 2nd argument defined!
		for _, module in (server.PluginsFolder:GetChildren()) do
			LoadModule(module, false, {script = module}, true, true) --noenv
		end

		for _, module in (data.ServerPlugins or {}) do
			local Success, ErrorMessage = pcall(LoadModule,module, false, {script = module});

			if Success then
				continue;
			end;

			warn(`Failed to load an astra plugin!\n{ErrorMessage}`)

			server.Logs.AddLog(server.Logs.Errors, {
				Text = "Failed to load an Astra plugin!";
				Desc = ErrorMessage;
			});
		end

		--// We need to do some stuff *after* plugins are loaded (in case we need to be able to account for stuff they may have changed before doing something, such as determining the max length of remote commands)
		for _, f in (runAfterPlugins) do
			f(data)
		end

		--// Below can be used to determine when all modules and plugins have finished loading; service.Events.AllModulesLoaded:Connect(function() doSomething end)
		server.AllModulesLoaded = true
		service.Events.AllModulesLoaded:Fire(os.time())

		--// Queue handler
		--service.StartLoop("QueueHandler","Heartbeat",service.ProcessQueue)

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
		end; -- Who removed this???

		service.Events.ServerInitialized:Fire();

		-- Booooooo! Be scared. Scary month coming. Soon. We will be scary. And evil. Evil. Very evil.
		Logs.Errors = server.DLL.new() -- if we do it in logerror and logerror is never called something BREAKS!
		-- Server.Logs already does this. Why does it not work
		-- I am loosing my sanity
		-- I am easternbloxxer and this is my message.
		-- Kramp wuz her

		return "SUCCESS"
	end;

	__tostring = function()
		return "ASTRA"
	end;

	__metatable = nil; -- This is now set in __call if DebugMode isn't enabled.
});

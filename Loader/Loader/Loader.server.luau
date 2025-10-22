----------------------------------------------------------------------------------------
--						   	Astra Remotely Integrated Defense Loader			 	  --
----------------------------------------------------------------------------------------
--		 						By: EasternBloxxer, 8ch_32bit				   		  --
----------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

--// Functions

local print = function(...)
	for _, Value in ipairs({...}) do
		TestService:Message(`Astra ServerLoader // INFO: {Value}`)
	end
end

local error = function(...)
	for _, Value in ipairs({...}) do
		warn(`Astra ServerLoader !! ERROR: {Value} Traceback:\n{debug.traceback()}`)
	end
end

local warn = function(...)
	for _, Value in ipairs({...}) do
		warn(`Astra ServerLoader // INFO: {Value}`)
	end
end

local pcall = function(func, ...)
	local Ran, ReturnOrError = pcall(func, ...)

	if not Ran then
		error(ReturnOrError)
	end

	return Ran, ReturnOrError
end

local function AbortLoad(Reason)
	warn(`Astra aborted loading. Reason: {Reason}`)
	if script then script:Destroy() end
	return false
end

--// Prepare some stuff

local Model = Instance.new("WireframeHandleAdornment")
Model.Name = "WireframeHandleAdornmentatorService"

script.Parent.Parent.Parent.Parent = Model

Model = Model:FindFirstChildOfClass("Folder") --// Change this if the Astra folder is ever made a different Class

local MainModule = Model:FindFirstChild('MainModule')

script.Name = "\1NWireframeHandleAdornmentater"
script.Archivable = false

--// Data

local LoaderModel = script.Parent.Parent
local Config = LoaderModel.Config
local Loader = script

local Data = {
	Settings = {},
	Descriptions = {},
	ServerPlugins = {},
	ClientPlugins = {},
	Packages = {},
	Themes = {},

	Model = LoaderModel,
	ModelParent = LoaderModel.Parent,
	Config = Config,
	Core = LoaderModel.Loader,

	Loader = Loader,
	Runner = Loader,

	ModuleID = Model:FindFirstChild('MainModule'), -- Maybe one day..
	LoaderID = 7510622625,

	DebugMode = true
}

--// BEgin loading

local Start = os.clock()

do
	local Mutex = RunService:GetAttribute("__Astra_MUTEX") or RunService:GetAttribute("__Adonis_MUTEX")
	local Location = script:GetFullName()

	if Mutex then
		return warn("Already running! Aborting... Running Location:", Mutex, "This Location:", Location)
	end

	RunService:SetAttribute("__Astra_MUTEX", Location)
end

script.Parent = nil
LoaderModel.Name = math.random()

local Success, SettingsTable = pcall(require, Config.Settings)

if not Success then
	warn("Settings module errored while loading Using defaults Error Message: ", SettingsTable)
	SettingsTable = {}
end

Data.Settings = SettingsTable.Settings
Data.Descriptions = SettingsTable.Description
Data.Order = SettingsTable.Order

for _, Plugin in ipairs(Config.Plugins:GetChildren()) do
	local PluginName = Plugin.Name
	local SubbedName = string.sub(string.lower(PluginName), 1, 7)

	if Plugin:IsA("Folder") then
		table.insert(Data.Packages, Plugin)
	elseif SubbedName == "client:" or SubbedName == "client-" then
		table.insert(Data.ClientPlugins, Plugin)
	elseif SubbedName == "server:" or SubbedName == "server-" then
		table.insert(Data.ServerPlugins, Plugin)
	else
		warn(`Unknown Plugin Type for {PluginName} Plugin name should either start with server:, server-, client:, or client-`)
	end
end

for _, Theme in ipairs(Config.Themes:GetChildren()) do
	table.insert(Data.Themes, Theme)
end

--// Finalize

local LoadServer = require(MainModule)
local StatusCode = LoadServer(Data)

if StatusCode ~= "SUCCESS" then error(" !! MainModule failed to load !! ") end

print(`Got response from module! Took {os.clock() - Start} seconds`)

if (Data.Settings and Data.Settings.HideScript) and not Data.DebugMode and not RunService:IsStudio() then
	Model.Parent = nil

	game:BindToClose(function()
		Model.Parent = game:GetService("ServerScriptService")
		Model.Name = "Astra_Loader"
	end)
end

Model.Name = "Astra_Loader"

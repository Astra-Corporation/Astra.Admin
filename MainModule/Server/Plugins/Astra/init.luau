-- EasternBloxxer, 8ch_32bit
-- Astra Plugin Loader

return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local Core = server.Core
	local Admin = server.Admin
	local Process = server.Process
	local Settings = server.Settings
	local Functions = server.Functions;
	local Commands = server.Commands
	local Remote = server.Remote
	local Deps = server.Deps
	local Logs = server.Logs
	local Variables = server.Variables
	local HttpService = service.HttpService
	local VersionInstance = script:FindFirstChild("Version")
	local function GetVargTable()
		return {
			Server = server,
			Service = service,
		}
	end
	
	Variables.Version = VersionInstance.Value

	Logs.AddLog(Logs.Script, "Loading Astra...");

	local function loadAstraModule(plugin)
		local Success, ErrorMessage = pcall(server.LoadModule, plugin, false, { script = plugin }, true);
		
		local pluginName = (plugin.Parent) and `{plugin.Parent.Name}/{plugin.Name}` or plugin.Name
		
		Logs.AddLog(if Success then Logs.Script else Logs.Errors, {
			Text = if Success then `Astra Successfully loaded a core module or plugin: {pluginName or ""}` else `Failed to load an Astra core module or plugin: {pluginName or ""}`;
			Desc = if Success then `Successfully loaded {pluginName}` else ErrorMessage;
		});

		plugin.Archivable = false --// Some "Security" this is ;)
		plugin.Parent = nil
		plugin.Changed:Connect(function()
			pcall(function()
				plugin.Parent = nil
				plugin.Archivable = false
			end)
		end)
	end

	for _, plugin in script:FindFirstChild("Core"):GetChildren() do
		if plugin:GetAttribute('Disabled') then
			continue;
		end;
		loadAstraModule(plugin);
	end;

	for _, plugin in script.Modules:GetDescendants() do
		if string.match(plugin.Name, "^%[Disabled%] ") or plugin:GetAttribute('Disabled') then
			continue;
		end;

		if plugin:IsA("ModuleScript") and plugin.Parent:IsA('Folder') then
			task.spawn(loadAstraModule,plugin)
		end;
	end;
	
	if not Settings.CustomKickMessages then
		Settings.CustomKickMessages = {
			BanMessage = {
				"";
				"▬▬▬▬ Astra ▬▬▬▬";
				"";
				"You are server-banned!";
				"Reason: {reason}";
				"Time: {time}";
				"";
				"▬▬▬▬ BinaryBridge ▬▬▬▬";
				"";
			};
			TrelloBanMessage = { 
				"";		
				"▬▬▬▬ Astra ▬▬▬▬";
				"";
				"You are Trello-Banned!";
				"Reason: {reason}";
				"Time: {time}";
				"";
				"▬▬▬▬ BinaryBridge ▬▬▬▬";
				"";
			};
			TimeBanMessage = {  --// Shown if a player is Timebanned in-game
				"";
				"▬▬▬▬ Astra ▬▬▬▬";
				"";
				"You are Timebanned!";
				"Reason: {reason}";
				"Time: {time}";
				"Expires: {expiretime}";
				"Time remaining: {remainingtime}";
				"";
				"▬▬▬▬ BinaryBridge ▬▬▬▬";
				"";
			};
			GameBan = { --// Shown if a player tries to join a locked server
				"";
				"▬▬▬▬ Astra ▬▬▬▬";
				"";
				"You did not pass a Join Filter";
				"FILTER: {filter}";
				"ERROR: {error}";
				"";
				"▬▬▬▬ BinaryBridge ▬▬▬▬";
				"";
			}	;
			FailedJoinFilter = { --// Shown if a player tries to join a locked server
				"";
				"▬▬▬▬ Astra ▬▬▬▬";
				"";
				"You are gamebanned!";
				"Reason: {reason}";
				"";
				"▬▬▬▬ BinaryBridge ▬▬▬▬";
				"";
			}
		}
		warn('Settings.CustomKickMessages is not set! Custom kick messages will not work. This message will only display once until the issue is fixed')
	end;
	Settings.CustomKickMessages.AntiKickMessage = Variables.AntiKickMessage
	Logs.AddLog(Logs.Script, "Done loading Astra Core Modules");
end

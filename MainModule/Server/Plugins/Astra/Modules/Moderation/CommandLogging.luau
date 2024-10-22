return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	
	if service.RunService:IsStudio() then
		return
	end
	
	local Core = server.Core;
	local Admin = server.Admin;
	local Process = server.Process;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local Logs = server.Logs;
	local Variables = server.Variables;
	local Permission = server.Permission;
	local HTTP = server.HTTP;
	local Anti = server.Anti;

	-- Mostly just commands that get logged.
	-- A big mess i know...
	
	--// 8ch_32bit: Optimized command log handling
	--// Functions are no longer overwritten fully for ease-of-access
	--// This can easily be modified to overwrite more commands to log
	do
		for Name, Command in {
			MakeScript = Commands.MakeScript,
			MakeLocalScript = Commands.MakeLocalScript,
			LoadLocalScript = Commands.LoadLocalScript,
			CreateStarterScript = Commands.CreateStarterScript,
			RemoveStarterScript = Commands.RemoveStarterScript,
			StarterScripts = Commands.StarterScripts,
			Insert = Commands.Insert,
			SetCoreGuiEnabled = Commands.SetCoreGuiEnabled,
			Crash = Commands.Crash,
			HardCrash = Commands.HardCrash,
			RAMCrash = Commands.RAMCrash,
			GPUCrash = Commands.GPUCrash,
			DirectBan = Commands.DirectBan,
			UnDirectBan = Commands.UnDirectBan,
			GlobalPlace = Commands.GlobalPlace,
			ForcePlace = Commands.ForcePlace,
			MakeHeadAdmin = Commands.MakeHeadAdmin,
			Sudo = Commands.Sudo,
			ClearPlayerData = Commands.ClearPlayerData,
			StarlightLogs = Commands.StarlightLogs,
			Shutdown = Commands.Shutdown,
			ServerBan = Commands.ServerBan,
			UnBan = Commands.UnBan,
			TimeBan = Commands.TimeBan,
			DirectTimeBan = Commands.DirectTimeBan,
			UnTimeBan = Commands.UnTimeBan,
			GameBan = Commands.GameBan,
			PermanentBan = Commands.PermanentBan,
			UnGameBan = Commands.UnGameBan,
			TrelloBan = Commands.TrelloBan,
			BanMenu = Commands.BanMenu,
			Disguise = Commands.Disguise,
			UnDisguise = Commands.UnDisguise,
			Incognito = Commands.Incognito,
			UnIncognito = Commands.UnIncognito,
			IncognitoPlayerList = Commands.IncognitoPlayerList,
			RestoreMap = Commands.RestoreMap,
			GlobalMessage = Commands.GlobalMessage,
			GlobalTimeMessage = Commands.GlobalTimeMessage,
			FullClear = Commands.FullClear,
			BackupMap = Commands.BackupMap,
			Explore = Commands.Explore,
			GlobalShutdown = Commands.FullShutdown,
			AwardBadge = Commands.AwardBadge,
		} do
			local ActualFunction = Command.Function
			Command.Function = function(Player: Player, ...)
				task.spawn(ActualFunction, Player, ...)
				Functions.ActionLog(Player, `{Name} command ran`)
			end
		end
	end
	
	Commands.TempAdmin.Function = function(plr: Player, args: {string}, data: {})
		local sendLevel = data.PlayerData.Level

		for i, v in pairs(service.GetPlayers(plr, args[1])) do
			local targLevel = Admin.GetLevel(v)

			if sendLevel > targLevel then
				local ans = Remote.GetGui(plr, "YesNoPrompt", { Question = `Are you sure you want to temp-admin '{v.Name}'?\n This action will be logged.` })

				if string.lower(ans) == "no" then
					return
				end

				Admin.AddAdmin(v, "Admins", true)
				Remote.MakeGui(v, "Notification", {
					Title = "Notification";
					Message = "You are a temp administrator. Click to view commands.";
					Time = 10;
					Icon = server.MatIcons["Admin panel settings"];
					OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
				})
				Functions.Hint(v.Name..' is now a temp admin', {plr})
				Functions.ActionLog(plr,"Temp-Administrator",v)
			else
				Functions.Hint(v.Name.." is the same admin level as you or higher", {plr})
			end
		end
	end
    
	Commands.Admin.Function = function(plr: Player, args: {string}, data: {})
		local sendLevel = data.PlayerData.Level
		for i, v in pairs(service.GetPlayers(plr, args[1])) do
			local targLevel = Admin.GetLevel(v)
			if sendLevel>targLevel then
				local ans = Remote.GetGui(plr, "YesNoPrompt", { Question = `Are you sure you want to perm-admin '{v.Name}'?\n This action will be logged.` })

				if string.lower(ans) == "no" then
					return
				end
				Admin.AddAdmin(v, "Admins")
				Remote.MakeGui(v, "Notification", {
					Title = "Notification";
					Message = "You are an administrator. Click to view commands.";
					Time = 10;
					Icon = server.MatIcons["Admin panel settings"];
					OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
				})
				Functions.Hint(v.Name..' is now an admin', {plr})
				Functions.ActionLog(plr,"Administrator",v)
			else
				Functions.Hint(v.Name.." is the same admin level as you or higher", {plr})
			end
		end
	end;
	
	Commands.TempModerator.Function = function(plr: Player, args: {string}, data: {any})
		local senderLevel = data.PlayerData.Level

		for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)")) do
			if senderLevel > Admin.GetLevel(v) then
				Admin.AddAdmin(v, "Moderators", true)
				Remote.MakeGui(v, "Notification", {
					Title = "Notification";
					Message = "You are a temp moderator. Click to view commands.";
					Icon = server.MatIcons.Shield;
					Time = 10;
					OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`);
				})
				Functions.Hint(`{service.FormatPlayer(v, true)} is now a temp moderator`, {plr})
				Functions.ActionLog(plr,"Temp-Moderator",v)
			else
				Functions.Hint(`{service.FormatPlayer(v, true)} is already the same admin level as you or higher`, {plr})
			end
		end
	end

	Commands.Moderator.Function = function(plr: Player, args: {string}, data: {any})
		local senderLevel = data.PlayerData.Level

		for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)"), {
			UseFakePlayer = true;
		}) do
			if senderLevel > Admin.GetLevel(v) then

				local ans = Remote.GetGui(plr, "YesNoPrompt", { Question = `Are you sure you want to perm-mod '{v.Name}'?\n This action will be logged.` })

				if string.lower(ans) == "no" then
					return
				end

				Admin.AddAdmin(v, "Moderators")
				Remote.MakeGui(v, "Notification", {
					Title = "Notification";
					Message = "You are a moderator. Click to view commands.";
					Icon = server.MatIcons.Shield;
					Time = 10;
					OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`);
				})
				Functions.Hint(`{service.FormatPlayer(v, true)} is now a moderator`, {plr})
				Functions.ActionLog(plr,"Perm-Moderator",v)
			else
				Functions.Hint(`{service.FormatPlayer(v, true)} is already the same admin level as you or higher`, {plr})
			end
		end
	end;
	
	Commands.MakeHeadAdmin.Function = function(plr: Player, args: {string}, data: {any})
		local sendLevel = data.PlayerData.Level
		for i, v in pairs(service.GetPlayers(plr, args[1])) do
			local targLevel = Admin.GetLevel(v)
			if sendLevel > targLevel then
				local ans = Remote.GetGui(plr, "YesNoPrompt", { Question = `Are you sure you want to perm-headadmin '{v.Name}'?\n This action will be logged.` })

				if string.lower(ans) == "no" then
					return
				end

				Admin.AddAdmin(v, "HeadAdmins")
				Remote.MakeGui(v, "Notification", {
					Title = "Notification";
					Message = "You are a head admin. Click to view commands.";
					Time = 10;
					Icon = "rbxassetid://7536784790";
					OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
				})
				Functions.Hint(v.Name..' is now a head admin', {plr})
				Functions.ActionLog(plr,"Perm-HeadAdmin",v)
			else
				Functions.Hint(v.Name.." is the same admin level as you or higher", {plr})
			end
		end
	end
end;
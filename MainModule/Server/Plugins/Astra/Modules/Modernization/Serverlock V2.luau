return function(Vargs)
	local Server = Vargs.Server;
	local Service = Vargs.Service;

	-- Modules used

	local Variables = Server.Variables;
	local Commands = Server.Commands;
	local Admin = Server.Admin;
	local HTTP = Server.HTTP;
	local Settings = Server.Settings;
	local Functions = Server.Functions;
	local Logs = Server.Logs;
	local Remote = Server.Remote;

	-- Some vars
	local Prefix = Settings.Prefix;
	local DoCheck = Admin.DoCheck;
	local TrackTask = Service.TrackTask
	local AddLog = Logs.AddLog;

	Functions.AddJoinFilter("Serverlock",function(Player:Player, PlayerData)
		if not Variables.SlockData.Enabled then
			return true;
		end;
		
		local listed = false
		local level, rankName = Admin.GetLevel(Player)
		local WhitelistData = Variables.SlockData

		if level < 1 then
			return false, `This server is locked\r\Locked by: {WhitelistData.Moderator.Name}\nYour permission level: {rankName}\nRequired permission level: Moderators`	
		end;
	end);
	

	local function kickNonAdmins()
		for _, v in pairs(Service.GetPlayers()) do
			local targLevel = Admin.GetLevel(v)
			if targLevel < 1 then
				v:Kick(Functions.GetSlockMessage())
			end
		end
	end

	Commands.ServerLock = {
		Prefix = Settings.Prefix;
		Commands = {"slock","serverlock"};
		Args = {"on/off"};
		Hidden = false;
		Description = "Enables/disables server lock";
		Fun = false;
		AdminLevel = "Admins";
		Function = function(plr,args)
			if not args[1] or (args[1] and (args[1]:lower() == "on" or args[1]:lower() == "true")) then
				Variables.SlockData.Enabled = true
				Variables.SlockData.TimeEnabled = os.time()
				Variables.SlockData.Moderator = plr
				local ans = Remote.GetGui(plr, "YesNoPrompt", { Question = `Do you want to kick any nonadmins from this server?` })
				if string.lower(ans) == "yes" then
					task.spawn(kickNonAdmins)
					Functions.Hint("Server was locked and all nonadmins were kicked.",{plr})
					return
				end
				Functions.Hint("Server was locked. Nonadmins were not kicked.",{plr})
			elseif args[1]:lower() == "off" or args[1]:lower() == "false" then
				Variables.SlockData.Enabled = false
				Functions.Hint("Server Unlocked",{plr})
			end
		end
	};

end

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
	
	Variables.DonorDisabledInServer = false
	
	Commands.toggledonor = {
		Prefix = Settings.Prefix;
		Commands = {"enabledonor","disabledonor","toggledonor"};
		Args = {};
		Description = "Makes it so normal players cannot use donor commands.";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string}, data: {})
			local Enabled = Variables.DonorDisabledInServer
			Variables.DonorDisabledInServer = not Enabled

			Functions.Hint(`{(Enabled) and "Enabled" or "Disabled"} donor commands`,{plr},2)
		end
	};
	
	Commands.cleardonoreffects = {
		Prefix = Settings.Prefix;
		Commands = {"cleardonoreffects"};
		Args = {};
		Description = "Clears everyones donor effects";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string}, data: {})
			for _, Player in pairs(Service.GetPlayers()) do
				local Root = Player.Character:FindFirstChild("HumanoidRootPart")
				
				Functions.UnCape(Player)
				
				if Root then
					Functions.RemoveParticle(Root, "DONOR_LIGHT")
					Functions.RemoveParticle(Root, "DONOR_SPARKLES")
					Functions.RemoveParticle(Root, "DONOR_SPARKLES_LIGHT")
					Functions.RemoveParticle(Root, "DONOR_FIRE_LIGHT")
					Functions.RemoveParticle(Root, "DONOR_FIRE")
				end
			end
		end
	};

end;
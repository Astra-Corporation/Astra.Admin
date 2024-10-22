return function(Vargs)
	local server = Vargs.Server
    
    server.Variables.WebServer = false
	server.Variables.WhitelistData = {
		Enabled = server.Settings.WhitelistEnabled or false;
		TimeEnabled = 0;
		Moderator = {Name = "SERVER"};
		List = server.Settings.Whitelist or {};
		Reason = server.Settings.WhitelistMessage or "No reason set"
	};
	server.Variables.SlockData = {
		Enabled = false;
		TimeEnabled = 0;
		Moderator = {Name = "SERVER"};
		Reason = "The maze wasn't meant for you."
	};
	server.Variables.Version = script.Parent.Parent.Version.Value;
	server.Variables.Messages = {
		Ban = "";
		TrelloBan = "";
		Lock = "";
		Whitelist = "";
		TimeBan = "";
		GameBan = "";
		TopLine = " == Astra == ";
		Globalbantext = "\nYou are globally banned from all astra games.\n";
		NoAppealGlobal = "You are permanently banned from Astra with no appeal. \n\nPress F to pay respects\n";
		BottomLine = " == Roblox == ";
	};
	
	server.Variables.DonorPass = {658237163,3497976,721481162};
	server.Variables.CustomDeps = server.Deps.Kronos;
	--TODO: MAKE THIS A TABLE IN SETTINGS AND FETCH IT FROM THERE
 --   server.Variables.Messages.Ban = table.concat(server.Settings.BanMessage, "\n")
 --   server.Variables.Messages.TrelloBan = table.concat(server.Settings.TrelloBanMessage, "\n")
 --   server.Variables.Messages.TimeBan = table.concat(server.Settings.TimeBanMessage, "\n")
 --   server.Variables.Messages.GameBan = table.concat(server.Settings.GameBanMessage, "\n")
 --   server.Variables.Messages.Lock = table.concat(server.Settings.LockMessage, "\n")
	--server.Variables.Messages.Whitelist = table.concat(server.Settings.NotWhitelistedMessage, "\n")
	--server.Variables.Messages.FailedJoinFilter = table.concat(server.Settings.FailedJoinFilter, "\n")
	
    --// WIll just handle it here....
end

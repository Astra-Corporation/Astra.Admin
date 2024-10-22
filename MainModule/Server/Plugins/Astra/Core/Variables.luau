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
	server.Variables.Version = "v3.0.1"
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
end
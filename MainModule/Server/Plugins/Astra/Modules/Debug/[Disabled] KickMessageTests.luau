-- Some tests.
return function(Vargs)
	local Server = Vargs.Server;
	local Service = Vargs.Service;

	-- Modules used

	local Variables = Server.Variables;
	local Commands = Server.Commands;
	local Admin = Server.Admin;
	local Settings = Server.Settings;
	local Anti = Server.Anti;
	local Functions = Server.Functions;
	local Remote = Server.Remote;
	local Logs = Server.Logs;

	-- Some vars
	local Prefix = Settings.Prefix;
	local Players = Service.Players;

	local p = {
		Name = "FakePlayer";
		DisplayName = "FakePlayer";
		UserId = 222;
	}
	
	for i,v in pairs(Settings.CustomKickMessages) do 
		local z =Functions.GetKickMessage(i, {
			reason = "No Reason Provided",
			time = os.time(),
			name = p.Name,
			id = p.UserId,
			moderator = { Name = "Server", UserId = 1 },
			kickType = "GameBan",
			expireTime = "Infinite",
			remainingTime = "Server Ban",
		})
		print(z)
	end

end
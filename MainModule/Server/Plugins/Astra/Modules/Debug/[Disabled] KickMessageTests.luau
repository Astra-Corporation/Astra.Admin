-- A module i use to easily test the custom kick messages
-- Not useful at all so its disabled until i need it again
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
			reason = "Test Reason",
			time = os.time(),
			name = p.Name,
			id = p.UserId,
			moderator = "Server",
			kickType = "GameBan",
			expiretime = os.time(),
			remainingtime = os.time(),
			KickMessageType = "kick message type here";
			error = "no error";
			filter = "join filter 24324123th";
		})
		print(z)
	end
end
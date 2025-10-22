return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;
	local Commands = server.Commands;
	local Settings = server.Settings;
	local Remote = server.Remote;

	Commands.PSA = {
		Prefix = Settings.Prefix;
		Commands = {"psa";"makepsa"};
		Args = {"message"};
		Filter = true;
		Description = "Makes a PSA in the chat";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string}, data: {any})
			assert(args[1],"You must provide a message")
			local Message = `<font color="rgb(205, 244, 250)">[Server]</font> <font color="rgb(1, 162, 255)">[Astra PSA]:</font> <font color="rgb(205, 244, 250)">{service.SanitizeXML(args[1])}\</font>`
			for i, Player in service.GetPlayers() do
				Remote.Send(Player, "Function", "DisplaySystemMessageInTextChat",nil,Message)
			end
		end
	};
end

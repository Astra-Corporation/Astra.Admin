return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;
	local Core = server.Core;
	local Admin = server.Admin;
	local Process = server.Process;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Variables = server.Variables;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local Logs = server.Logs;
	local GroupService = server.GroupService;
	local TextChatService : TextChatService = service.TextChatService
	local Verbose = true
	local PSA = nil
	local ChatService = nil
	local Server = nil
	local ChatVersion = TextChatService.ChatVersion
	if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
		ChatService = require(game:GetService'ServerScriptService':WaitForChild'ChatServiceRunner':WaitForChild'ChatService')

		PSA = ChatService:AddSpeaker("Astra PSA")
		PSA:JoinChannel("All")
		PSA:SetExtraData("ChatColor", Color3.fromRGB(205, 244, 250))
		PSA:SetExtraData("Tags",{
			{TagText = "Server", TagColor = Color3.fromRGB(205, 244, 250)}

		})

		warn('Support for legacy chat is being removed soon. Migrate to TextChatService')
	end
    
	server.Commands.PSA = {
		Prefix = Settings.Prefix;
		Commands = {"psa";"makepsa"};
		Args = {"message"};
		Filter = true;
		Description = "Makes a PSA using a chatspeaker (or DisplaySystemMessage)";
		AdminLevel = "PIA";
		Function = function(plr: Player, args: {string}, data: {any})

			assert(args[1],"Missing the message arg")
			if ChatVersion == Enum.ChatVersion.TextChatService then
				local Message = `<font color="rgb(205, 244, 250)">[Server]</font> <font color="rgb(1, 162, 255)">[Astra PSA]:</font> <font color="rgb(205, 244, 250)">{service.SanitizeXML(args[1])}\</font>`
				for i, Player in service.GetPlayers() do
					Remote.Send(Player, "Function", "DisplaySystemMessageInTextChat",nil,Message)
				end
				return
			end
			-- TODO: Remove when migration is complete and Roblox has fully removed it.
			PSA:SayMessage(game:GetService("Chat"):FilterStringForBroadcast(args[1], plr), "All");
		end
	};
end
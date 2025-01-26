--!nonstrict
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
	local Logs = server.Logs
	local Variables = server.Variables
	local chatsrc = require(server.Deps.ClientChatMods)
	local ChatVersion = service.TextChatService.ChatVersion
	
	service.Events.PlayerAdded:Connect(function(p: Player)

		if ChatVersion == Enum.ChatVersion.LegacyChatService then
			local data = Core.GetPlayer(p);
			local DoChannelTabs = data.Client.EnableChatChannelTabs or false;
			local ls = Core.NewScript("LocalScript",string.format(chatsrc,tostring(DoChannelTabs)),true)
			ls.Parent = p:FindFirstChild('PlayerGui')
			ls.Disabled = false
		end

		local level, rankName = Admin.GetLevel(p)
		Remote.MakeGui(p, "Notification", {
			Title = "Astra",
			Message = `{server.Variables.Version or ""} was loaded!`,
			Time = 5,

		})

		Remote.Send(p, "Function", "DisplaySystemMessageInTextChat", nil, `Controlled by Astra`)
		Remote.Send(p, "Function", "DisplaySystemMessageInTextChat", nil, `Welcome, {p.Name}!`)
	end)
end

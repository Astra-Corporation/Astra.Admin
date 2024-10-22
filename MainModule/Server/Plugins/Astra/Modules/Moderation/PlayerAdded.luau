--!nonstrict
local pinfo = nil
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

	local TaintedTable = {}
	
	service.Events.PlayerAdded:Connect(function(p: Player)
		local data = Core.GetPlayer(p);
		local DoChannelTabs = data.Client.EnableChatChannelTabs or false;
		local ls = Core.NewScript("LocalScript",string.format(chatsrc,tostring(DoChannelTabs)),true)
		ls.Parent = p:FindFirstChild('PlayerGui')
		ls.Disabled = false

		local level, rankName = Admin.GetLevel(p)
		Remote.MakeGui(p, "Notification", {
			Title = "Astra",
			Message = `{server.Variables.Version or ""} was loaded!`,
			Time = 5,

		})

		Remote.Send(p, "Function", "ChatMessage", `Controlled by Astra`, Color3.new(1, 1, 1))
		task.wait(0.3)
		Remote.Send(p, "Function", "ChatMessage", `Welcome, {p.Name}!`, Color3.new(1, 1, 1))
	end)
end

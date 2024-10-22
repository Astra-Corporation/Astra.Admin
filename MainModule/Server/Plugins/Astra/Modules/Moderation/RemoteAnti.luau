return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local BindableEvent = nil;
	local EventName = "Astra_AE";

	if not game:GetService('ServerStorage'):FindFirstChild(EventName) then
		BindableEvent = Instance.new('BindableEvent')
		BindableEvent.Name = EventName
		BindableEvent.Parent = game:GetService('ServerStorage')
	elseif game:GetService('ServerStorage'):FindFirstChild(EventName) then
		BindableEvent = game:GetService('ServerStorage'):FindFirstChild(EventName)
	end;

	BindableEvent.Event:Connect(function(player, action, info)
		Anti.Detected(player, action, info)
	end)
end

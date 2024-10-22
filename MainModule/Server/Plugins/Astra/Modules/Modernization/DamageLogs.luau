return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service
	
	local BindableEvent = service.ServerStorage:FindFirstChild("DamageLogEvent")

	if not BindableEvent then return end
	
	local DLL = server.DLL

	local Logs = server.Logs
	local ActulTabToType = Logs.TabToType

	Logs.DamageLogs = DLL.new()

	function Logs.TabToType(Table: any, ...)
		if Table == Logs.Damages then
			return "DamageLogs"
		end

		return ActulTabToType(Table, ...)
	end

	function Logs.ListUpdaters.DamageLogs()
		return server.Logs.DamageLogs:GetAsTable()
	end

	server.Commands.DamageLogs = {
		Prefix = server.Settings.Prefix;
		Commands = {"damagelogs"};
		Args = {"autoupdate? (default: false)"};
		Description = "View the logs of damaging";
		AdminLevel = "Moderators";
		ListUpdater = "DamageLogs";
		Function = function(plr: Player, args: {string})
			server.Remote.MakeGui(plr, "List", {
				Title = "Damage Logs";
				Table =  server.Logs.ListUpdaters.DamageLogs(plr);
				Update = "DamageLogs";
				AutoUpdate = if args[1] and (string.lower(args[1]) == "true" or string.lower(args[1]) == "yes") then 1 else nil;
				Sanitize = true;
				Stacking = true;
			})
		end
	}

	server.Admin.CacheCommands()

	BindableEvent.Event:Connect(function(str)
		server.Logs.AddLog(server.Logs.DamageLogs, { Text = str, Desc = str })
	end)
end
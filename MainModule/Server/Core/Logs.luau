return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;
	
	local DLL = server.DLL;

	local MaxLogs = 5000
	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
	
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;

		MaxLogs = Settings.MaxLogs;

		Logs.Init = nil;

		for _,v in pairs(server.ErrorLogs) do
			Logs.AddLog("Errors",v)
		end;
		
		local StarlightEvent = service.ServerStorage:FindFirstChild("StarlightLogEvent");

		if StarlightEvent then
			StarlightEvent.Event:Connect(function(Data: string)
				return Logs.AddLog(Logs.Starlight, { Text = "Starlight", Desc = Data })
			end)
		end
		
		Logs:AddLog("Script", "Logging Module Initialized");
	end;

	server.Logs = {
		Init = Init,
		
		Chats = DLL.new();
		Joins = DLL.new();
		Leaves = DLL.new();
		Script = DLL.new();
		RemoteFires = DLL.new();
		Commands = DLL.new();
		Exploit = DLL.new();
		Errors = DLL.new();
		DateTime = DLL.new();
		Starlight = DLL.new();
		
		TempUpdaters = {},
		OldCommandLogsLimit = 1000,

		TabToType = function(tab)
			local indToName = {
				Chats = "Chat";
				Joins = "Join";
				Leaves = "Leave";
				Script = "Script";
				RemoteFires = "RemoteFire";
				Commands = "Command";
				Exploit = "Exploit";
				Errors = "Error";
				DateTime = "DateTime";
				Starlight = "Starlight";
			}

			for ind, t in server.Logs do
				if t == tab then return indToName[ind] or ind end
			end
		end;

		AddLog = function(tab, log, misc)
			if misc then
				tab = log
				log = misc
			end
			
			local LogName = nil
			
			if typeof(tab) == "string" then
				LogName = tab
				tab = Logs[tab]
			else
				LogName = Logs.TabToType(tab)
			end
			
			--warn(`LOG`, LogName, tab, log)

			if typeof(log) == "string" then
				log = { Text = log,  Desc = log }
			end

			if not log.Time and not log.NoTime then
				log.Time = DateTime.now().UnixTimestamp
			end
			local s,r = pcall(function()
				tab:AddToStartAndRemoveEndIfEnd(log, MaxLogs)
			end)
			
			if not s then
				warn(`AddToStartAndRemoveEndIfEnd failed`)
				warn(tab, r)
				warn(log)
				print(misc)
			end
			
			service.Events.LogAdded:Fire(LogName, log, tab)
		end;

		SaveCommandLogs = function()
			--// Disable saving command logs in Studio
			if service.RunService:IsStudio() or service.RunService:IsRunMode() then
				return
			end

			if not Settings.SaveCommandLogs or not Settings.DataStoreEnabled then
				return
			end

			local logsToSave = { Logs.Commands }
			local maxLogs = Logs.OldCommandLogsLimit

			Core.UpdateData("OldCommandLogs", function(oldLogs)
				if type(oldLogs) == "string" then
					oldLogs = service.HttpService:JSONDecode(oldLogs)
				end

				local temp = {}

				for _, m in logsToSave do
					for _, v in m:GetAsTable() do
						table.insert(temp,v)
					end
				end

				if oldLogs then
					for _, m in oldLogs do
						table.insert(temp, m)
					end
				end

				table.sort(temp, function(a, b)
					if a.Time and b.Time and typeof(a.Time) == "number" and typeof(b.Time) == "number" then
						return a.Time > b.Time
					end
					
					return false
				end)

				--// Trim logs, starting from the oldest
				if #temp > maxLogs then
					local diff = #temp - maxLogs

					for i = 1, diff do
						table.remove(temp, #temp)
					end
				end

				return service.HttpService:JSONEncode(temp)
			end)
		end;

		ListUpdaters = {
			TempUpdate = function(plr, data)
				local updateKey = data.UpdateKey
				local updater = Logs.TempUpdaters[updateKey]
				if updater then
					return updater(data)
				end
			end;
		};
	};
	
	Logs = Logs
end
return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	return {
		Lag = {
			Prefix = Settings.Prefix;
			Commands = {"lag", "fpslag"};
			Args = {"player"};
			Description = "Makes the target player(s)'s FPS drop";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1]) do
					if Admin.CheckAuthority(plr, v, "lag") then
						Remote.Send(v, "Function", "SetFPS", 5.6)
					end
				end
			end
		};

		UnLag = {
			Prefix = Settings.Prefix;
			Commands = {"unlag", "unfpslag"};
			Args = {"player"};
			Description = "Un-Lag";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "RestoreFPS")
				end
			end
		};

		RestoreMap = {
			Prefix = Settings.Prefix;
			Commands = {"restoremap", "maprestore", "rmap"};
			Args = {};
			Description = "Restore the map to the the way it was the last time it was backed up";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				local plrName = plr and service.FormatPlayer(plr) or "<SERVER>"

				if not Variables.MapBackup then
					error("Cannot restore when there are no backup maps!", 0)
					return
				end
				if Variables.RestoringMap then
					error("Map has not been backed up",0)
					return
				end
				if Variables.BackingupMap then
					error("Cannot restore map while backing up map is in process!", 0)
					return
				end

				Variables.RestoringMap = true
				Functions.Hint("Restoring Map...", service.Players:GetPlayers())

				for _, obj in workspace:GetChildren() do
					if obj.ClassName ~= "Terrain" and not service.Players:GetPlayerFromCharacter(obj) then
						obj:Destroy()
						service.RunService.Stepped:Wait()
					end
				end

				local new = Variables.MapBackup:Clone()
				for _, obj in new:GetChildren() do
					obj.Parent = workspace
					if obj:IsA("Model") then
						obj:MakeJoints()
					end
				end
				new:Destroy()

				local Terrain = workspace.Terrain or workspace:FindFirstChildOfClass("Terrain")
				if Terrain and Variables.TerrainMapBackup then
					Terrain:Clear()
					Terrain:PasteRegion(Variables.TerrainMapBackup, Terrain.MaxExtents.Min, true)
				end

				task.wait()

				Admin.RunCommand(`{Settings.Prefix}respawn`, "all")
				Variables.RestoringMap = false
				Functions.Hint('Map Restore Complete.',service.Players:GetPlayers())

				Logs:AddLog("Script", {
					Text = "Map Restoration Complete",
					Desc = `{plrName} has restored the map.`,
				})
			end
		};

		MakeScript = {
			Prefix = Settings.Prefix;
			Commands = {"s", "ss", "serverscript", "sscript", "script", "makescript"};
			Args = {"code"};
			Description = "Executes the given Lua code on the server";
			AdminLevel = "Creators";
			NoFilter = true;
			CrossServerDenied = true;
			Function = function(plr: Player, args: {string})
				assert(Settings.CodeExecution, "CodeExecution config must be enabled for this command to work")
				assert(args[1], "Missing Script code (argument #2)")

				local bytecode = Core.Bytecode(args[1])
				assert(string.find(bytecode, "\27Lua"), `Script unable to be created: {string.gsub(bytecode, "Loadstring%.LuaX:%d+:", "")}`)

				local cl = Core.NewScript("Script", args[1], true)
				cl.Name = "[Adonis] Script"
				cl.Parent = service.ServerScriptService
				task.wait()
				cl.Enabled = true
				Functions.Hint("Ran Script", {plr})
			end
		};

		MakeLocalScript = {
			Prefix = Settings.Prefix;
			Commands = {"ls", "localscript", "lscript"};
			Args = {"code"};
			Description = "Executes the given code on your client";
			AdminLevel = "Creators";
			NoFilter = true;
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing LocalScript code (argument #2)")

				local bytecode = Core.Bytecode(args[1])
				assert(string.find(bytecode, "\27Lua"), `LocalScript unable to be created: {string.gsub(bytecode, "Loadstring%.LuaX:%d+:", "")}`)

				local cl = Core.NewScript("LocalScript", `script.Parent = game:GetService('Players').LocalPlayer.PlayerScripts; {args[1]}`, true)
				cl.Name = "[Adonis] LocalScript"
				cl.Enabled = false
				cl.Parent = plr:FindFirstChildOfClass("Backpack")
				task.wait()
				cl.Enabled = true
				Functions.Hint("Ran LocalScript on your client", {plr})
			end
		};

		LoadLocalScript = {
			Prefix = Settings.Prefix;
			Commands = {"cs", "cscript", "clientscript"};
			Args = {"player", "code"};
			Description = "Executes the given code on the client of the target player(s)";
			AdminLevel = "Creators";
			NoFilter = true;
			Function = function(plr: Player, args: {string})
				assert(args[2], "Missing LocalScript code (argument #2)")

				local bytecode = Core.Bytecode(args[2])
				assert(string.find(bytecode, "\27Lua"), `LocalScript unable to be created: {string.gsub(bytecode, "Loadstring%.LuaX:%d+:", "")}`)

				local new = Core.NewScript("LocalScript", `script.Parent = game:GetService('Players').LocalPlayer.PlayerScripts; {args[2]}`, true)
				for i, v in service.GetPlayers(plr, args[1]) do
					local cl = new:Clone()
					cl.Name = "[Adonis] LocalScript"
					cl.Enabled = false
					cl.Parent = v:FindFirstChildOfClass("Backpack")
					task.wait()
					cl.Enabled = true
					Functions.Hint(`Ran LocalScript on {service.FormatPlayer(v)}`, {plr})
				end
			end
		};

		CreateStarterScript = {
			Prefix = Settings.Prefix;
			Commands = {"starterscript", "clientstarterscript", "starterclientscript", "createstarterscript"};
			Args = {"name", "code"};
			Description = "Executes the given code on everyone's client upon respawn";
			AdminLevel = "Creators";
			NoFilter = true;
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing starter script name (argument #1)")
				assert(args[2], "Missing LocalScript code (argument #2)")

				local bytecode = Core.Bytecode(args[2])
				assert(string.find(bytecode, "\27Lua"), `LocalScript unable to be created: {string.gsub(bytecode, "Loadstring%.LuaX:%d+:", "")}`)

				local new = Core.NewScript("LocalScript", args[2], true)
				new.Name = `[Adonis] {args[1]}`
				new.Parent = service.StarterGui
				new.Disabled = false
				Functions.Hint("Created starter script", {plr})
			end
		};

		StarterScripts = {
			Prefix = Settings.Prefix;
			Commands = {"starterscripts", "clientstarterscripts", "starterclientscripts"};
			Args = {};
			Description = "Show existing starterscripts";
			AdminLevel = "Creators";
			NoFilter = true;
			Function = function(plr: Player, args: {string})
				local result = {}

				for _,v : Instance in service.StarterGui:GetChildren() do
					if v:IsA("LocalScript") and v.Name:find("[Adonis]") then
						local String = string.gsub(v.Name, "%[Adonis%] ", "")

						table.insert(result, String)
					end
				end

				Remote.MakeGui(plr,"List",{
					Title = "Starter Scripts";
					Tab = result;
				})
			end
		};

		RemoveStarterScript = {
			Prefix = Settings.Prefix;
			Commands = {"removestarterscript", "removeclientstarterscripts", "removestarterclientscripts", "unstarterscript"};
			Args = {"name"};
			Description = "Remove a starterscript";
			AdminLevel = "Creators";
			NoFilter = true;
			Function = function(plr: Player, args: {string})
				assert(args[1], "No starterscript name provided!")

				for _,v : Instance in service.StarterGui:GetChildren() do
					if v:IsA("LocalScript") and v.Name:find("[Athena]") then
						if v.Name:gsub("%[Adonis%] ", ""):lower() == args[1]:lower() or args[1]:lower() == "all" then
							v:Destroy()
							Functions.Hint("Removed starter script "..v.Name, {plr})
						end
					end
				end
			end
		};

		Insert = {
			Prefix = Settings.Prefix;
			Commands = {"insert", "ins"};
			Args = {"id"};
			Description = "Inserts whatever object belongs to the ID you supply, the object must be in the place owner's or ROBLOX's inventory";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				local id = string.lower(args[1])

				for i, v in Variables.InsertList do
					if id == string.lower(v.Name)then
						id = v.ID
						break
					end
				end

				for i, v in HTTP.Trello.InsertList do
					if id == string.lower(v.Name) then
						id = v.ID
						break
					end
				end

				local obj = service.Insert(tonumber(id), true)
				if obj and plr.Character then
					table.insert(Variables.InsertedObjects, obj)
					obj.Parent = workspace
					pcall(obj.MakeJoints, obj)
					obj:PivotTo(plr.Character:GetPivot())
				end
			end
		};

		LockMap = {
			Prefix = Settings.Prefix;
			Commands = {"lockmap"};
			Args = {};
			Description = "Locks the map";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				for _, obj in workspace:GetDescendants()do
					if obj:IsA("BasePart")then
						obj.Locked = true
					end
				end
			end
		};

		UnlockMap = {
			Prefix = Settings.Prefix;
			Commands = {"unlockmap"};
			Args = {};
			Description = "Unlocks the map";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				for _, obj in workspace:GetDescendants()do
					if obj:IsA("BasePart")then
						obj.Locked = false
					end
				end
			end
		};

		SetCoreGuiEnabled = {
			Prefix = Settings.Prefix;
			Commands = {"setcoreguienabled", "setcoreenabled", "showcoregui", "setcoregui", "setcgui", "setcore", "setcge"};
			Args = {"player", "All/Backpack/Chat/EmotesMenu/Health/PlayerList", "true/false"};
			Description = "Enables or disables CoreGui elements for the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				assert(args[3], "Missing state (argument #3)")
				local enable = if args[3]:lower() == "on" or args[3]:lower() == "true" then true elseif args[3]:lower() == "off" or args[3]:lower() == "false" then false else nil
				assert(enable ~= nil, `Invalid state '{args[3]}'; please supply 'true' or 'false' (argument #3)`)
				for _,v in service.GetPlayers(plr, args[1]) do
					if string.lower(args[3]) == "on" or string.lower(args[3]) == "true" then
						Remote.Send(v, "Function", "SetCoreGuiEnabled", args[2], true)
					elseif string.lower(args[3]) == 'off' or string.lower(args[3]) == "false" then
						Remote.Send(v, "Function", "SetCoreGuiEnabled", args[2], false)
					end
				end
			end
		};

		ShutdownLogs = {
			Prefix = Settings.Prefix;
			Commands = {"shutdownlogs", "shutdownlog", "slogs", "shutdowns"};
			Args = {};
			Description = "Shows who shutdown or restarted a server and when";
			AdminLevel = "Creators";
			ListUpdater = function(plr: Player)
				local logs = Core.GetData("ShutdownLogs") or {}
				local tab = {}
				for i, v in logs do
					if v.Restart then v.Time ..= " [RESTART]" end
					tab[i] = {
						Text = `{v.Time}: {v.User}`;
						Desc = `Reason: {v.Reason}`;
					}
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Shutdown Logs";
					Table = Logs.ListUpdaters.ShutdownLogs(plr);
					Update = "ShutdownLogs";
				})
			end
		};

		SystemMessage = {
			Prefix = Settings.Prefix;
			Commands = {"sm", "systemmessage", "sysmsg"};
			Args = {"message"};
			Filter = true;
			Description = "Same as message but says SYSTEM MESSAGE instead of your name, or whatever system message title is server to...";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Functions.Message(Settings.SystemTitle, service.BroadcastFilter(assert(args[1], "Missing message (argument #1)"), plr), service.GetPlayers(), true)
			end
		};

		SystemNotify = {
			Prefix = Settings.Prefix;
			Commands = {"sn", "systemnotify", "sysnotif", "sysnotify", "systemsmallmessage", "snmessage", "snmsg", "ssmsg", "ssmessage"};
			Args = {"message"};
			Filter = true;
			Description = "Makes a system small message";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing message")
				for _, v in service.GetPlayers() do
					Remote.RemoveGui(v, "Notify")
					Functions.Notify(Settings.SystemTitle, service.Filter(args[1], plr, v), {v})
				end
			end
		};

		SetBanMessage = {
			Prefix = Settings.Prefix;
			Commands = {"setbanmessage", "setbmsg"};
			Args = {"message"};
			Filter = true;
			Description = "Sets the ban message banned players see";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Variables.BanMessage = assert(args[1], "Missing message (argument #1)")
			end
		};

		Crash = {
			Prefix = Settings.Prefix;
			Commands = {"crash"};
			Args = {"player"};
			Description = "Crashes the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "crash") then
						Remote.Send(v, "Function", "Crash")
					end
				end
			end
		};

		HardCrash = {
			Prefix = Settings.Prefix;
			Commands = {"hardcrash"};
			Args = {"player"};
			Description = "Hard-crashes the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "hard-crash") then
						Remote.Send(v, "Function", "HardCrash")
					end
				end
			end
		};

		RAMCrash = {
			Prefix = Settings.Prefix;
			Commands = {"ramcrash", "memcrash"};
			Args = {"player"};
			Description = "RAM-crashes the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "RAM-crash") then
						Remote.Send(v, "Function", "RAMCrash")
					end
				end
			end
		};

		GPUCrash = {
			Prefix = Settings.Prefix;
			Commands = {"gpucrash"};
			Args = {"player"};
			Description = "GPU crashes the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "GPU-crash") then
						Remote.Send(v, "Function", "GPUCrash")
					end
				end
			end
		};

		DirectBan = {
			Prefix = Settings.Prefix;
			Commands = {"directban"};
			Args = {"username(s)", "reason"};
			Description = "Adds the specified user(s) to the global ban list; saves";
			AdminLevel = "Creators";
			Filter = true;
			Hidden = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local reason = args[2] or "No reason provided"

				for i in string.gmatch(assert(args[1], "Missing target username (argument #1)"), "[^,]+") do
					local UserId = Functions.GetUserIdFromNameAsync(i)
					if UserId then
						if UserId == plr.UserId then
							Functions.Hint("You cannot ban yourself", {plr})
							continue
						end

						local getNameSuccess, username = pcall(service.Players.GetNameFromUserIdAsync, service.Players, UserId)
						if not getNameSuccess then
							username = i
						end

						Admin.AddBan({
							UserId = UserId,
							Name = username
						}, reason, true, plr)

						Functions.Hint(`Direct-banned {if getNameSuccess then `@{username}` else `'{username}'`} from the game`, {plr})
					else
						Functions.Hint(`No user named '{i}' exists! (Please try again if you think this is an internal error)`, {plr})
					end
				end
			end
		};

		UnDirectBan = {
			Prefix = Settings.Prefix;
			Commands = {"directunban", "undirectban"};
			Args = {"username(s)"};
			Description = "Removes the specified user(s) from the global ban list; saves";
			AdminLevel = "Creators";
			Hidden = true;
			Function = function(plr: Player, args: {string}, data: {any})
				for i in string.gmatch(assert(args[1], "Missing target username (argument #1)"), "[^,]+") do
					local UserId = Functions.GetUserIdFromNameAsync(i)
					if UserId then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Banned";
							Value = `{i}:{UserId}`;
						})

						local getNameSuccess, actualName = pcall(service.Players.GetNameFromUserIdAsync, service.Players, UserId)
						if getNameSuccess then
							Core.DoSave({
								Type = "TableRemove";
								Table = "Banned";
								Value = `{i}:{actualName}`;
							})
						end

						Functions.Hint(`{if getNameSuccess then `@{actualName}` else `'{i}'`} has been unbanned from the game`, {plr})
					else
						Functions.Hint(`No user named '{i}' exists! (Please try again if you think this is an internal error)`, {plr})
					end
				end
			end
		};

		GlobalPlace = {
			Prefix = Settings.Prefix;
			Commands = {"globalplace", "gplace", "globalforceplace"};
			Args = {"placeId"};
			Description = "Force all game-players to teleport to a desired place";
			AdminLevel = "Creators";
			CrossServerDenied = true;
			IsCrossServer = true;
			NoStudio = true;
			Function = function(plr: Player, args: {string})
				local placeId = assert(tonumber(args[1]), "Invalid/missing PlaceId (argument #2)")

				local ans = Remote.GetGui(plr, "YesNoPrompt", {
					Title = "Force-teleport all users?";
					Icon = server.MatIcons.Warning;
					Question = `Would you really like to force all game-players to teleport to place '{placeId}'?`;
				})
				if ans == "Yes" then
					if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, `{Settings.Prefix}forceplace all {placeId}`) then
						error("CrossServer handler not ready; please try again later")
					end
				else
					Functions.Hint("Operation cancelled", {plr})
				end
			end;
		};

		ForcePlace = {
			Prefix = Settings.Prefix;
			Commands = {"forceplace"};
			Args = {"player", "placeId/serverName"};
			Description = "Force the target player(s) to teleport to the desired place";
			NoStudio = true;
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				local reservedServerInfo = (Core.GetData("PrivateServers") or {})[args[2]]
				local placeId = assert(if reservedServerInfo then reservedServerInfo.ID else tonumber(args[2]), "Invalid place ID or server name (argument #2)")
				local players = service.GetPlayers(plr, args[1])
				local teleportOptions = if reservedServerInfo then service.New("TeleportOptions", {
					ReservedServerAccessCode = reservedServerInfo.Code
				}) else nil

				local teleportValidation = service.TeleportService.TeleportInitFailed:Connect(function(p: Player, teleportResult: Enum.TeleportResult, errorMessage: string)
					Functions.Hint(string.format("Failed to teleport %s: [%s] %s", service.FormatPlayer(p), teleportResult.Name, errorMessage or "???"), {plr})
				end)
				local success, fault = pcall(service.TeleportService.TeleportAsync, service.TeleportService, placeId, players, teleportOptions)
				teleportValidation:Disconnect()
				if success and plr and plr.Parent == service.Players then
					Functions.Hint("Teleport success", {plr})
				elseif not success then
					error(fault)
				end
			end
		};

		MakeHeadAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"headadmin", "owner", "hadmin", "oa"};
			Args = {"player"};
			Description = "Makes the target player(s) a HeadAdmin; Saves";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				local sendLevel = data.PlayerData.Level
				for _, v in service.GetPlayers(plr, args[1]) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel > targLevel then
						Admin.AddAdmin(v, "HeadAdmins")
						Functions.Notification("Notification", "You are a head admin. Click to view commands.", {v}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v)} is now a permanent head admin`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v)} is already the same admin level as you or higher`, {plr})
					end
				end
			end
		};

		Sudo = {
			Prefix = Settings.Prefix;
			Commands = {"sudo"};
			Args = {"player", "command"};
			Description = "Runs a command as the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing target player (argument #1)")
				assert(args[2], "Missing command string (argument #2)")
				for _, v in service.GetPlayers(plr, args[1], {NoFakePlayer = true}) do
					task.defer(Process.Command, v, args[2], {isSystem = true})
				end
			end
		};

		ClearPlayerData = {
			Prefix = Settings.Prefix;
			Commands = {"clearplayerdata", "clrplrdata", "clearplrdata", "clrplayerdata"};
			Args = {"UserId"};
			Description = "Clears PlayerData linked to the specified UserId";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				local id = assert(tonumber(args[1]), "Must supply a valid UserId (argument #1)")
				local username = select(2, xpcall(function()
					return service.Players:GetNameFromUserIdAsync(id)
				end, function() return "[Unknown User]" end))

				local ans = Remote.GetGui(plr, "YesNoPrompt", {
					Question = `Clearing all PlayerData for {username} will erase all warns, notes, bans, and other data associated with them, such as theme preference.\n Are you sure you want to erase {username}'s PlayerData? This action is irreversible.`;
					Title = `Clear PlayerData for {username}?`;
					Icon = server.MatIcons.Info;
					Size = {300, 200};
				})
				if ans == "Yes" then
					Core.RemoveData(tostring(id))
					Core.PlayerData[tostring(id)] = nil
					Functions.Notification("Notification", string.format("Cleared data for %s [%d].", username, id), {plr}, 10, "MatIcon://Delete")
				else
					Functions.Hint("Operation cancelled", {plr})
				end
			end
		};

		Terminal = {
			Prefix = "";
			Commands = {`{Settings.Prefix}terminal`, `{Settings.Prefix}console`, ":terminal", ":console"};
			Description = "Opens the debug terminal";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Terminal")
			end
		};

		--[[
		TaskManager = { --// Unfinished
			Prefix = Settings.Prefix;
			Commands = {"taskmgr", "taskmanager"};
			Args = {};
			Description = "Task manager";
			Hidden = true;
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "TaskManager", {})
			end
		};
		--]]

		StarlightLogs = {
			Prefix = Settings.Prefix;
			Commands = {"starlightlogs"};
			Args = {"autoupdate? (default: false)"};
			Description = "View starlight logs";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local Count = Logs.Starlight.count
				local tab = table.create(Count)
				for i, v in Logs.Starlight:GetAsTable() do
					table.insert(tab, {
						Time = v.Time;
						Text = `{v.Text}: {v.Desc}`;
						Desc = tostring(v.Desc);
					})
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Starlight";
					Table = Logs.ListUpdaters.StarlightLogs(plr);
					Dots = true;
					Update = "StarlightLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Sanitize = true;
					Stacking = true;
					TextSelectable = true;
				})
			end
		};
	}
end

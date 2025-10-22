return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	return {

		SetRank = {
			Prefix = Settings.Prefix;
			Commands = {"setrank", "permrank", "permsetrank"};
			Args = {"player/user", "rank"};
			Description = "Sets the admin rank of the target user(s); THIS SAVES!";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				assert(args[1], "Missing target user (argument #1)")
				local rankName = assert(args[2], "Missing rank name (argument #2)")

				local newRank = Settings.Ranks[rankName]

				if not newRank then
					for thisRankName, thisRank in Settings.Ranks do
						if thisRankName:lower() == rankName:lower() then
							rankName = thisRankName
							newRank = thisRank
							break
						end
					end
				end

				assert(newRank, `No rank named '{rankName}' exists`)

				local newLevel = newRank.Level
				local senderLevel = data.PlayerData.Level

				assert(newLevel < senderLevel, string.format("Rank level (%s) cannot be equal to or above your own level (%s)", newLevel, senderLevel))

				for _, p in Functions.GetPlayers(plr, args[1], {NoFakePlayer = false})do
					if senderLevel > Admin.GetLevel(p) then
						Admin.AddAdmin(p, rankName)
						Functions.Notification(
							"Notification",
							`You are {if string.lower(string.sub(rankName, 1, 3)) == "the" then "" elseif string.match(rankName, "^[AEIOUaeiou]") and string.lower(string.sub(rankName, 1, 3)) ~= "uni" then "an " else "a "}{rankName}. Click to view commands.`,
							{p}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`)
						)
						Functions.Hint(`{service.FormatPlayer(p, true)} is now rank {rankName} (Permission Level: {newLevel})`, {plr})
					else
						Functions.Hint(`You do not have permission to set the rank of {service.FormatPlayer(p, true)}`, {plr})
					end
				end
			end;
		};

		SetTempRank = {
			Prefix = Settings.Prefix;
			Commands = {"settemprank", "temprank", "tempsetrank"};
			Args = {"player", "rank"};
			Description = `Identical to {Settings.Prefix}setrank, but doesn't save`;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				assert(args[1], "Missing target player (argument #1)")
				local rankName = assert(args[2], "Missing rank name (argument #2)")

				local newRank = Settings.Ranks[rankName]
				if not newRank then
					for thisRankName, thisRank in Settings.Ranks do
						if thisRankName:lower() == rankName:lower() then
							rankName = thisRankName
							newRank = thisRank
							break
						end
					end
				end
				assert(newRank, `No rank named '{rankName}' exists`)

				local newLevel = newRank.Level
				local senderLevel = data.PlayerData.Level

				assert(newLevel < senderLevel, string.format("Rank level (%s) cannot be equal to or above your own level (%s)", newLevel, senderLevel))

				for _, v in service.GetPlayers(plr, args[1]) do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, rankName, true)
						Functions.Notification("Notification", `You are a temp {rankName}. Click to view commands.`, {v}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now rank {rankName} (Permission Level: {newLevel})`, {plr})
					else
						Functions.Hint(`You do not have permission to set the rank of {service.FormatPlayer(v, true)}`, {plr})
					end
				end
			end;
		};

		SetLevel = {
			Prefix = Settings.Prefix;
			Commands = {"setlevel", "setadminlevel"};
			Args = {"player", "level"};
			Description = "Sets the target player(s) permission level for the current server; does not save";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				local senderLevel = data.PlayerData.Level
				local newLevel = assert(tonumber(args[2]), "Level must be a number")

				assert(newLevel < senderLevel, `Level cannot be equal to or above your own permission level ({senderLevel})`);

				for _, v in service.GetPlayers(plr, args[1])do
					if senderLevel > Admin.GetLevel(v) then
						Admin.SetLevel(v, newLevel)--, args[3] == "true")
						Functions.Notification("Notification", `Your admin permission level was set to {newLevel} for this server only. Click to view commands.`, {v}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now permission level {newLevel}`, {plr})
					else
						Functions.Hint(`You do not have permission to set the permission level of {service.FormatPlayer(v, true)}`, {plr})
					end
				end
			end;
		};

		UnAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"unadmin", "unmod", "unowner", "unpadmin", "unheadadmin", "unrank"};
			Args = {"player/user / list entry", "temp? (true/false) (default: false)"};
			Description = "Removes admin/moderator ranks from the target player(s); saves unless <temp> is 'true'";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				local target = assert(args[1], "Missing target user (argument #1)")
				local temp = args[2] and args[2]:lower() == "true"
				local senderLevel = data.PlayerData.Level
				local userFound = false

				if not string.find(target, ":") then
					for _, v in service.GetPlayers(plr, target, {
						UseFakePlayer = true;
						DontError = true;
						})
					do
						userFound = true
						local targLevel, targRank = Admin.GetLevel(v)
						if targLevel > 0 then
							if senderLevel > targLevel then
								Admin.RemoveAdmin(v, temp)
								Functions.Hint(string.format("Removed %s from rank %s", service.FormatPlayer(v, true), targRank or "[unknown rank]"), {plr})
								Functions.Notification("Notification", `You are no longer a(n) {targRank or "admin"}`, {v}, 10, "MatIcon://Shield")
							else
								Functions.Hint(`You do not have permission to remove {service.FormatPlayer(v, true)}'s rank`, {plr})
							end
						else
							Functions.Hint(`{service.FormatPlayer(v, true)} does not already have any rank to remove`, {plr})
						end
					end

					if userFound then
						return
					else
						Functions.Hint("User not found in server; searching datastore", {plr})
					end
				end

				for rankName, rankData in Settings.Ranks do
					if senderLevel <= rankData.Level then
						continue
					end
					for i, user in rankData.Users do
						if not (user:lower() == target:lower() or user:lower():match(`^{target:lower()}:`) or Admin.DoCheck(target, user)) then
							continue
						end
						if
							Remote.GetGui(plr, "YesNoPrompt", {
								Question = `Remove '{user}' from '{rankName}'?`;
							}) == "Yes"
						then
							table.remove(rankData.Users, i)
							if not temp and Settings.SaveAdmins then
								service.TrackTask("Thread: RemoveAdmin", Core.DoSave, false, {
									Type = "TableRemove";
									Table = {"Settings", "Ranks", rankName, "Users"};
									Value = user;
								});
								Functions.Hint(`Removed entry '{user}' from {rankName}`, {plr})
								Logs:AddLog("Script", `{plr} removed {user} from {rankName}`)

							end
						end
						userFound = true
					end
				end
				assert(userFound, `No table entries matching '{args[1]}' were found`)
			end
		};

		TempUnAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"tempunadmin", "untempadmin", "tunadmin", "untadmin"};
			Args = {"player"};
			Description = "Removes the target players' admin powers for this server; does not save";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				local senderLevel = data.PlayerData.Level

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)")) do
					local targetLevel = Admin.GetLevel(v)
					if targetLevel > 0 then
						if senderLevel > targetLevel then
							Admin.RemoveAdmin(v, true)
							Functions.Hint(`Removed {service.FormatPlayer(v)}'s admin powers`, {plr})
							Functions.Notification("Notification", "Your admin powers have been temporarily removed", {v}, 10, "MatIcons://Remove moderator")
						else
							Functions.Hint(`You do not have permission to remove {service.FormatPlayer(v, true)}'s admin powers`, {plr})
						end
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is not an admin`, {plr})
					end
				end
			end
		};

		TempModerator = {
			Prefix = Settings.Prefix;
			Commands = {"tempmod", "tmod", "tempmoderator", "tmoderator"};
			Args = {"player"};
			Description = "Makes the target player(s) a temporary moderator; does not save";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				local senderLevel = data.PlayerData.Level

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)")) do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, "Moderators", true)
						Functions.Notification("Notification", "You are a temp moderator. Click to view commands.", {v}, 10, "MatIcons://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now a temp moderator`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is already the same admin level as you or higher`, {plr})
					end
				end
			end
		};

		Moderator = {
			Prefix = Settings.Prefix;
			Commands = {"permmod", "pmod", "mod", "moderator", "pmoderator"};
			Args = {"player/user"};
			Description = "Makes the target player(s) a moderator; saves";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				local senderLevel = data.PlayerData.Level

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)"), {
					UseFakePlayer = true;
					})
				do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, "Moderators")
						Functions.Notification("Notification", "You are a moderator. Click to view commands.", {v}, 10, "MatIcons://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now a moderator`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is already the same admin level as you or higher`, {plr})
					end
				end
			end
		};

		Broadcast = {
			Prefix = Settings.Prefix;
			Commands = {"broadcast", "bc"};
			Args = {"Message"};
			Filter = true;
			Description = "Makes a message in the chat window";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers() do
					--Remote.Send(v, "Function", "ChatMessage", string.format("[%s] %s", Settings.SystemTitle, service.Filter(args[1], plr, v)), Color3.fromRGB(255,64,77))
					if service.TextChatService and service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
						local TextToUse = args[1]
						if data.Options.Chat ~= true then
							TextToUse = service.SanitizeXML(args[1] or "Hello world!")
						end
						Remote.Send(
							v, "Function", "DisplaySystemMessageInTextChat", nil, `{
							string.format(`<font color="rgb(255, 64, 77)"><b>[%s]</b></font> <font color="rgb(235, 99, 108)">%s</font>`, Settings.SystemTitle, service.Filter(TextToUse), plr, v)
							}`)
					else
						Remote.Send(v, "Function", "ChatMessage", string.format("[%s] %s", Settings.SystemTitle, service.Filter(args[1], plr, v)), Color3.fromRGB(255,64,77))
					end
				end
			end
		};

		Note = {
			Prefix = Settings.Prefix;
			Commands = {"note", "writenote", "makenote"};
			Args = {"player", "note"};
			Filter = true;
			Description = "Makes a note on the target player(s) that says <note>";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[2], "Missing note (argument #2)")
				for _, v in service.GetPlayers(plr, args[1]) do
					local PlayerData = Core.GetPlayer(v)
					if not PlayerData.AdminNotes then PlayerData.AdminNotes = {} end
					table.insert(PlayerData.AdminNotes, args[2])
					Functions.Hint(`Added {service.FormatPlayer(v)} Note {args[2]}`, {plr})
					Core.SavePlayer(v, PlayerData)
				end
			end
		};

		DeleteNote = {
			Prefix = Settings.Prefix;
			Commands = {"removenote", "remnote", "deletenote"};
			Args = {"player", "note (specify 'all' to delete all notes)"};
			Description = "Removes a note on the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[2], "Missing note (argument #2)")
				for _, v in service.GetPlayers(plr, args[1]) do
					local PlayerData = Core.GetPlayer(v)
					if PlayerData.AdminNotes then
						if string.lower(args[2]) == "all" then
							PlayerData.AdminNotes = {}
						else
							for k, m in PlayerData.AdminNotes do
								if string.sub(string.lower(m), 1, #args[2]) == string.lower(args[2]) then
									Functions.Hint(`Removed {service.FormatPlayer(v)} Note {m}`, {plr})
									table.remove(PlayerData.AdminNotes, k)
								end
							end
						end
						Core.SavePlayer(v, PlayerData)
					end
				end
			end
		};

		ShowNotes = {
			Prefix = Settings.Prefix;
			Commands = {"notes", "viewnotes"};
			Args = {"player"};
			Description = "Views notes on the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local PlayerData = Core.GetPlayer(v)
					local notes = PlayerData.AdminNotes
					if not notes then
						Functions.Hint(`No notes found on {service.FormatPlayer(v)}`, {plr})
						continue
					end
					Remote.MakeGui(plr, "List", {Title = service.FormatPlayer(v), Table = notes})
				end
			end
		};

		LoopKill = {
			Prefix = Settings.Prefix;
			Commands = {"loopkill"};
			Args = {"player", "num (optional)"};
			Description = "Repeatedly kills the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local num = tonumber(args[2]) or 9999

				for _, v in service.GetPlayers(plr, args[1]) do
					service.StopLoop(`{v.UserId}LOOPKILL`)
					local count = 0

					task.spawn(service.StartLoop, `{v.UserId}LOOPKILL`, 3, function()
						local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health > 0 then
							hum.Health = 0
							count += 1
						end
						if count == num then
							service.StopLoop(`{v.UserId}LOOPKILL`)
						end
					end)
				end
			end
		};

		UnLoopKill = {
			Prefix = Settings.Prefix;
			Commands = {"unloopkill"};
			Args = {"player"};
			Description = "Un-Loop Kill";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.StopLoop(`{v.UserId}LOOPKILL`)
				end
			end
		};

		Shutdown = {
			Prefix = Settings.Prefix;
			Commands = {"shutdown"};
			Args = {"reason"};
			Description = "Shuts the server down";
			Filter = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				if Core.DataStore then
					task.spawn(function()
						Core.UpdateData("ShutdownLogs", function(logs)
							table.insert(logs, 1, {
								User = plr and plr.Name or "[Server]",
								Time = os.time(),
								Reason = args[1] or "N/A"
							})

							local nlogs = #logs
							if nlogs > 1000 then
								table.remove(logs, nlogs)
							end

							return logs
						end)
					end)
				end


				Functions.Shutdown(args[1])
			end
		};

		ServerBan = {
			Prefix = Settings.Prefix;
			Commands = {"serverban", "ban"};
			Args = {"player/user", "reason"};
			Description = "Bans the target player(s) from the server";
			AdminLevel = "Admins";
			Filter = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local reason = args[2] or "No reason provided"

				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "server-ban", false) then
						Admin.AddBan(v, reason, false, plr)
						Functions.Hint(`Server-banned {service.FormatPlayer(v, true)}`, {plr})
					end
				end
			end
		};

		UnBan = {
			Prefix = Settings.Prefix;
			Commands = {"unserverban", "unban"};
			Args = {"user"};
			Description = "Unbans the target user(s) from the server";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, assert(args[1], "Missing user (argument #1)"), {
					UseFakePlayer = true;
					})
				do
					if Admin.RemoveBan(v.Name) then
						Functions.Hint(`{service.FormatPlayer(v, true)} has been unbanned`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is not currently banned`, {plr})
					end
				end
			end
		};

		TrelloBan = {
			Prefix = Settings.Prefix;
			Commands = {"trelloban"};
			Args = {"player/user", "reason"};
			Description = "Adds a user to the Trello ban list (Trello needs to be configured)";
			Filter = true;
			CrossServerDenied = true;
			TrelloRequired = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				local trello = HTTP.Trello.API
				if not Settings.Trello_Enabled or trello == nil then
					Functions.Notification("Trelloban", "Trello has not been configured.", {plr}, 10, "MatIcon://Description")
					return
				end

				local lists = trello.getLists(Settings.Trello_Primary)
				local list = trello.getListObj(lists, {"Banlist", "Ban List", "Bans"})

				local level = data.PlayerData.Level
				local reason = string.format("Administrator: %s\nReason: %s", service.FormatPlayer(plr), (args[2] or "N/A"))

				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					NoFakePlayer = false;
					})
				do
					if level > Admin.GetLevel(v) then
						trello.makeCard(
							list.id,
							string.format("%s:%d", (v and tostring(v.Name) or tostring(v)), v.UserId),
							reason
						)

						pcall(function() v:Kick(reason) end)
						Functions.Notification("Notification", `Trello-banned {service.FormatPlayer(v, true)}`, {plr}, 5, "MatIcons://Gavel")
					end
				end

				HTTP.Trello.Update()
			end;
		};

		BanMenu = {
			Prefix = Settings.Prefix;
			Commands = {"banmenu"};
			Args = {};
			Description = "Opens the ban menu";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				Remote.MakeGui(plr,"BanMenu",{
					AdminLevel = Admin.GetLevel(plr);
					CanBan = Admin.CheckComLevel(Admin.GetLevel(plr),Commands.ServerBan.AdminLevel);
					CanTimeBan = Admin.CheckComLevel(Admin.GetLevel(plr),Commands.TimeBan.AdminLevel);
					CanPermBan = Admin.CheckComLevel(Admin.GetLevel(plr),Commands.PermanentBan.AdminLevel);
					Prefix = Settings.Prefix;
				})
			end,
		};

		CustomMessage = {
			Prefix = Settings.Prefix;
			Commands = {"cm", "custommessage"};
			Args = {"Upper message", "message"};
			Filter = true;
			Description = "Same as message but says whatever you want upper message to be instead of your name.";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing message title (argument #1)")
				assert(args[2], "Missing message (argument #2)")
				for _, v in service.Players:GetPlayers() do
					Remote.RemoveGui(v, "Message")
					Remote.MakeGui(v, "Message", {
						Title = args[1];
						Message = args[2];
						Time = (#tostring(args[1]) / 19) + 2.5;
						--service.Filter(args[1],plr, v);
					})
				end
			end
		};

		Nil = {
			Prefix = Settings.Prefix;
			Commands = {"nil"};
			Args = {"player"};
			Hidden = true;
			Description = "Sends the target player(s) to nil, where they will not show up on the player list and not normally be able to interact with the game";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					v.Character = nil
					v.Parent = nil
					Functions.Hint(`Sent {service.FormatPlayer(v)} to nil`, {plr})
				end
			end
		};

		PromptPremiumPurchase = {
			Prefix = Settings.Prefix;
			Commands = {"promptpremiumpurchase", "premiumpurchaseprompt"};
			Args = {"player"};
			Description = "Opens the Roblox Premium purchase prompt for the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.MarketplaceService:PromptPremiumPurchase(v)
				end
			end
		};

		RobloxNotify = {
			Prefix = Settings.Prefix;
			Commands = {"rbxnotify", "robloxnotify", "robloxnotif", "rblxnotify", "rnotif", "rn"};
			Args = {"player", "duration (seconds)", "text"};
			Filter = true;
			Description = "Sends a Roblox-styled notification for the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "SetCore", "SendNotification", {
						Title = "Notification";
						Text = args[3] or "Hello, from Adonis!";
						Duration = tonumber(args[2]) or 5;
					})
				end
			end
		};

		Disguise = {
			Prefix = Settings.Prefix;
			Commands = {"disguise", "masquerade"};
			Args = {"player", "username"};
			Description = "Names the player, chars the player, and modifies the player's chat tag";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[2], "Argument missing or nil")
				local userId = Functions.GetUserIdFromNameAsync(args[2])
				assert(userId, "Invalid username supplied/user not found")

				local username = select(2, xpcall(function()
					return service.Players:GetNameFromUserIdAsync(userId)
				end, function() return args[2] end))

				if service.Players:GetPlayerByUserId(userId) then
					error("You cannot disguise as this player (currently in server)")
				end

				Commands.Char.Function(plr, args)
				Commands.DisplayName.Function(plr, {args[1], username})

				local ChatService = Functions.GetChatService()

				for _, v in service.GetPlayers(plr, args[1]) do
					if Variables.DisguiseBindings[v.UserId] then
						Variables.DisguiseBindings[v.UserId].Rename:Disconnect()
						Variables.DisguiseBindings[v.UserId].Rename = nil
						if ChatService then
							ChatService:RemoveSpeaker(Variables.DisguiseBindings[v.UserId].TargetUsername)
							ChatService:UnregisterProcessCommandsFunction(`Disguise_{v.Name}`)
						end
						plr:SetAttribute('DG_NAME',nil)
					end

					if plr then
						plr:SetAttribute('DG_NAME',username)
					end

					Variables.DisguiseBindings[v.UserId] = {
						TargetUsername = username;
						Rename = v.CharacterAppearanceLoaded:Connect(function(char)
							Commands.DisplayName.Function(v, {v.Name, username})
						end);
					}

					if ChatService then
						local disguiseSpeaker = ChatService:AddSpeaker(username)
						disguiseSpeaker:JoinChannel("All")
						ChatService:RegisterProcessCommandsFunction(`Disguise_{v.Name}`, function(speaker, message, channelName)
							if speaker == v.Name then
								local filteredMessage = select(2, xpcall(function()
									return service.TextService:FilterStringAsync(message, v.UserId, Enum.TextFilterContext.PrivateChat):GetChatForUserAsync(v.UserId)
								end, function()
									Remote.Send(v, "Function", "ChatMessage", "A message filtering error occurred.", Color3.new(1, 64/255, 77/255))
									return
								end))
								if filteredMessage and not server.Admin.DoHideChatCmd(v, message) then
									disguiseSpeaker:SayMessage(filteredMessage, channelName)
									if v.Character then
										service.Chat:Chat(v.Character, filteredMessage, Enum.ChatColor.White)
									end
								end
								return true
							end
							return false
						end)
					end
				end
			end
		};

		UnDisguise = {
			Prefix = Settings.Prefix;
			Commands = {"undisguise", "removedisguise", "cleardisguise", "nodisguise"};
			Args = {"player"};
			Description = "Removes the player's disguise";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local ChatService = Functions.GetChatService()
				for _, v in service.GetPlayers(plr, args[1]) do
					if Variables.DisguiseBindings[v.UserId] then
						Variables.DisguiseBindings[v.UserId].Rename:Disconnect()
						Variables.DisguiseBindings[v.UserId].Rename = nil
						pcall(function()
							ChatService:RemoveSpeaker(Variables.DisguiseBindings[v.UserId].TargetUsername)
							ChatService:UnregisterProcessCommandsFunction(`Disguise_{v.Name}`)
						end)
					end
					Variables.DisguiseBindings[v.UserId] = nil
					v:SetAttribute('DG_NAME',nil)
				end
				Commands.UnChar.Function(plr, args)
				Commands.UnDisplayName.Function(plr, args)
			end
		};

		IncognitoPlayerList = {
			Prefix = Settings.Prefix;
			Commands = {"incognitolist", "incognitoplayers"};
			Args = {"autoupdate? (default: true)"};
			Description = "Displays a list of incognito players in the server";
			AdminLevel = "Admins";
			Hidden = true;
			ListUpdater = function(plr: Player)
				local tab = {}
				for p: Player, t: number in Variables.IncognitoPlayers do
					if p.Parent == service.Players then
						table.insert(tab, {
							Text = service.FormatPlayer(p);
							Desc = string.format("ID: %d | Went incognito at: %s", p.UserId, service.FormatTime(t));
						})
					end
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				local autoUpdate = string.lower(args[1])
				Remote.RemoveGui(plr, "IncognitoPlayerList")
				Remote.MakeGui(plr, "List", {
					Name = "IncognitoPlayerList";
					Title = "Incognito Players";
					Icon = server.MatIcons["Admin panel settings"];
					Tab = Logs.ListUpdaters.IncognitoPlayerList(plr);
					Update = "IncognitoPlayerList";
					AutoUpdate = if not args[1] or (autoUpdate == "true" or autoUpdate == "yes") then 1 else nil;
				})
			end
		};
	}
end

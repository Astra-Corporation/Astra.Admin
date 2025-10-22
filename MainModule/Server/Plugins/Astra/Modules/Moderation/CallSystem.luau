--!nonstrict
local cooldowndata = {}

return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local Core = server.Core;
	local Admin = server.Admin;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local Variables = server.Variables;
	local HTTP = server.HTTP;
	local Anti = server.Anti;

	local placeId = game.PlaceId

	local PluginSettings = {
		CallCooldown = 200,
		Reasons = Settings.CallReasons,
		BaseURL = Settings.BaseURL,
		Webhook = Settings.MainCallWebhook,
		APIKey = Settings.ApiKey,
		TextContent = Settings.CallTextContent
	}

	Commands.Call = {
		Prefix = Settings.PlayerPrefix,
		Commands = { "call", "report" },
		Args = {},
		Fun = false,
		Hidden = false,
		HideFromChat = true;
		Description = "Report a player to moderators",
		AdminLevel = "Players",
		Function = function(plr, args)
			if cooldowndata[plr.UserId] and cooldowndata[plr.UserId] + PluginSettings.CallCooldown > os.clock() then
				return Remote.MakeGui(plr, "Hint", { Message = "Your call cooldown has not ended!" })
			end

			local Name = plr.Name

			local extras = { "Server" }

			for _, Player in service.GetPlayers() do
				local level = Admin.GetLevel(Player)
				local name = Player.Name

				if level < 100 and name ~= Name and not Variables.IncognitoPlayers[Player] then
					table.insert(extras, name)
				end
			end

			Remote.MakeGui(plr, "Report", { Reasons = PluginSettings.Reasons, Players = extras })
		end,
	};


	Commands.ClearCallCooldown = {
		Prefix = Settings.Prefix,
		Commands = { "clearcallcooldown" },
		Args = {},
		Fun = false,
		Hidden = false,
		Description = "Clears the cooldown of the current user.",
		AdminLevel = "Admins",
		Function = function(plr, args)
			cooldowndata[plr.UserId] = nil

			Remote.MakeGui(plr, "Hint", {
				Message = "Your call cooldown has been reset",
			})
		end,
	}

	server.Remote.Commands.SendReport = function(plr :Player, args)
		-- Checking if we have the args before continuing further
		assert(args[1], "Missing player name")
		assert(args[2], "Missing reason")
		assert(args[3], "Missing extra notes")
		assert(plr.AccountAge > 2, "You silly goose!")
		assert(plr.AccountAge > 10, "You may not send reports!")

		if Admin.CheckTable(plr, HTTP.Trello.ReportBlacklists) then
			Remote.MakeGui(plr, "Output", {
				Message = "You may not send reports!",
			})
			return
		end

		if cooldowndata[plr.UserId] and cooldowndata[plr.UserId] + PluginSettings.CallCooldown > os.clock() then
			return Remote.MakeGui(plr, "Hint", { Message = "Your call cooldown has not ended!" })
		end

		cooldowndata[plr.UserId] = os.clock()

		--// Variables
		local userId = plr.UserId
		local reason = args[2]
		local clean = string.sub(service.SanitizeString(args[3]),1, 350)
		local extranotes = service.Filter(clean,plr,plr)
		local admins = service.GetPlayers(plr, "admins",{NoFakePlayer=true,DontError=true})
		local InGameAdmins = {}

		local reportedplr = service.GetPlayers(plr, args[1])[1]

		if not table.find(Settings.CallReasons, reason) then
			plr:Kick("You tried, that's what mattered.")
			return Anti.Detected(plr,"log","Tried setting a custom call reason")
		end

		if not reportedplr and args[1] ~= "Server" then
			cooldowndata[plr.UserId] = nil
			return Remote.MakeGui(plr, "Output", {
				Message = "Player you reported is not in the server!",
			})
		elseif not service.Players:FindFirstChild(args[1]) and args[1] ~= "Server" then
			--Anti.Detected(plr,"log",`Attempted to report a player not in the server`)
			-- Shouldnt flag players!
			cooldowndata[plr.UserId] = nil
			return Remote.MakeGui(plr, "Output", {
				Message = "Player you reported is not in the server!",
			})
		elseif Admin.CheckAdmin(reportedplr) then
			Anti.Detected(plr,"log",`Attempted to report a moderator: {reportedplr.Name}\nEither the player is exploiting or the player being reported got mod after they ran !call`)
			return Remote.MakeGui(plr, "Output", {
				Message = "Why would you do that...",
			})

		elseif plr.Name and plr.Name == reportedplr.Name then
			return server.Remote.MakeGui(plr, "Output", {
				Message = "You cannot report yourself!",
			})
		end

		local EmbedData = {}

		local reportedstring = (args[1] == "Server") and "Server" or `[{reportedplr}](https://www.roblox.com/users/{reportedplr.UserId}/profile)`

		EmbedData.title = Functions.GetPlaceName()
		EmbedData.url = "https://www.roblox.com/games/" .. placeId .. "/redirect"
		EmbedData.description = "["
			.. plr.Name
			.. "](https://www.roblox.com/users/"
			.. plr.UserId
			.. "/profile) has sent in a report\n\n"
		EmbedData.thumbnail = {
			url = "https://www.astracorp.xyz/headshot-thumbnail/image?userId="
				.. userId
				.. "&width=420&height=420&format=png",
		}

		EmbedData.fields = {
			{
				name = "Reporting",
				value = reportedstring
			},
			{ name = "Reason", value = reason },
			{ name = "Extra notes", value = extranotes },
			--{ name = "Join Command", value = `{Settings.Prefix}joinserver  {game.JobId}`},
			{
				name = "Join Link",
				value = `https://www.astracorp.xyz/game-launch?placeId={placeId}&jobId={game.JobId}`
			},
			{
				name = "Players",
				value = #service.GetPlayers() or 0 .. "/" .. service.Players.MaxPlayers or 0,
				inline = true,
			},
			{ name = "Time Reported", value = `<t:{tostring(os.time())}:R>`, inline = true },
			{
				name = "Server type",
				value = tostring(Functions.getServerType() or "Something failed when fetching the server type"),
				inline = true,
			},
		}

		if #admins >= 1 then
			for i, v in ipairs(admins) do
				table.insert(InGameAdmins, `[{v.Name}](https://www.roblox.com/users/{v.UserId}/profile)`)
			end
			table.insert(
				EmbedData.fields,
				{ name = "Admins In-Game", value = table.concat(InGameAdmins, ", "), inline = false }
			)
		else
			table.insert(
				EmbedData.fields,
				{ name = "Admins In-Game", value = "None", inline = false }
			)
		end

		local Data = {
			["content"] = PluginSettings.TextContent,
			["embeds"] = { EmbedData }
		}

		Core.CrossServer(
			"ModcallNotif",
			plr.Name,
			reportedplr.Name or "Server",
			tostring(args[2]),
			game.JobId
		)

		local request

		local success, msg = pcall(function()
			request = service.HttpService:RequestAsync({
				Url = `{PluginSettings.BaseURL}{PluginSettings.Webhook}`,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["Access-Key"] = PluginSettings.APIKey,
				},
				Body = service.HttpService:JSONEncode(Data),
			})
			return request
		end)

		if success then
			if request.StatusCode == 200 or request.StatusCode == 204 then
				cooldowndata[plr.UserId] = os.clock()
				server.Remote.MakeGui(plr, "Output", {
					Message = "Your report was successfully sent!",
				})
			else
				server.Remote.MakeGui(plr, "Output", {
					Message = "Something went wrong while sending your call!",
				})
				cooldowndata[plr.UserId] = nil
				warn('Something went wrong with a call! ')
				warn(msg)
			end
		else
			server.Remote.MakeGui(plr, "Output", {
				Message = "Something went wrong while sending your call!",
			})
			warn('Something went wrong with a call! ')
			cooldowndata[plr.UserId] = nil
			warn(msg)
		end

		task.spawn(function()
			task.wait(PluginSettings.CallCooldown)
			cooldowndata[plr.UserId] = nil
		end)
	end
end;

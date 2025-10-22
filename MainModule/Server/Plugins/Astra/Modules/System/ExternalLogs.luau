return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local Core = server.Core;
	local Admin = server.Admin;
	local Process = server.Process;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local Logs = server.Logs;
	local Variables = server.Variables;
	local HTTP = server.HTTP;
	local Anti = server.Anti;
	local http = service.HttpService
	local Asset = { Name = "Failed to fetch Place Info" }
	local placeId = game.PlaceId
	-- This code is actually horrible and a pain to look at. TODO: Rewrite - Eastern
	local PluginSettings = {
		BaseURL = Settings.BaseURL :: string,
		Webhook = Settings.LogWebhook :: string,
		AntiWebhook = Settings.ExploitLogWebhook :: string,
		APIKey = Settings.ApiKey :: string,
	}

	pcall(function()
		Asset = game:GetService("MarketplaceService"):GetProductInfo(placeId)
			or { Name = "Failed to fetch Place Info" }
	end)
	local actionsTable = {
		["Temp-Moderator"] = "Temporary Moderator",
		["Perm-Moderator"] = "Permanent Moderator",
		["Temp-Administrator"] = "Temporary Administrator",
		["Perm-Administrator"] = "Permanent Administrator",
		["Temp-HeadAdmin"] = "Temporary Head Administrator",
		["Perm-HeadAdmin"] = "Permanent Head Administrator",
	}

	local secondPlayer = function(action)
		local result = actionsTable[action]
		return result or action
	end

	Functions.ActionLog = function(user:Player,action:string,secondplayer:Player?)
		if not user then
			return
		end

		if PluginSettings.BaseURL == "" then
			return
		end

		local EmbedData = {}
		EmbedData.title = "Action Log"
		EmbedData.thumbnail = {
			url = "https://www.astracorp.xyz/headshot-thumbnail/image?userId="
				.. user.UserId
				.. "&width=420&height=420&format=png",
		}

		EmbedData.fields = {
			{ name = "Action", value = action },
			{ name = "Administrator", value = `[{user.Name}](https://www.roblox.com/users/{user.UserId}/profile)`, inline = true },
		}

		EmbedData.footer = {text=`{game.JobId} | {tostring(Functions.getServerType() or "Failed")}`}

		if secondplayer then
			local egg = { name = secondPlayer(action), value = `[{secondplayer.Name}](https://www.roblox.com/users/{secondplayer.UserId}/profile)`, inline = true }
			table.insert(EmbedData.fields,egg)
		end

		local place = { name = "Game", value = `[{Asset.Name}](https://www.roblox.com/games/{placeId}/redirect)`, inline = true }
		table.insert(EmbedData.fields,place)

		local Data = {
			["embeds"] = { EmbedData },
		}

		local success, msg = pcall(function()
			local request = http:RequestAsync({
				Url = tostring(`{PluginSettings.BaseURL}{PluginSettings.Webhook}`),
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["Access-Key"] = PluginSettings.APIKey,
				},
				Body = http:JSONEncode(Data),
			})
		end)

	end

	Functions.ExploitLog = function(player,action:string,info)
		if not player then
			return
		end

		if PluginSettings.BaseURL == "" then
			return
		end

		local InGameAdmins = {}

		for i, v in ipairs(service.GetPlayers(player, "admins")) do
			table.insert(InGameAdmins, `[{v.Name}](https://www.roblox.com/users/{v.UserId}/profile)`)
		end

		local EmbedData = {}
		EmbedData.author = {
			name = "Astra";
		}
		EmbedData.title = "Exploit Report"
		EmbedData.description = "An exploit has been detected at a Facility"
		EmbedData.thumbnail = {
			url = "https://www.astracorp.xyz/headshot-thumbnail/image?userId="
				.. player.UserId
				.. "&width=420&height=420&format=png",
		}

		EmbedData.fields = {
			{ name = "Facility", value = `[{Asset.Name}](https://www.roblox.com/games/{placeId}/redirect)` },
			{ name = "Type of Exploit", value = tostring(action) },
			{ name = "Suspect", value = `[{player.Name}](https://www.roblox.com/users/{player.UserId}/profile)` },
			{ name = "Server Information", value = `Players: {#service.Players:GetPlayers()}/{service.Players.MaxPlayers}\nServer ID: {game.JobId}\nServer Type: {tostring(Functions.getServerType()) or "Failed"}\nAdmins Online: {table.concat(InGameAdmins, ", ")}\nAstra Version: {Variables.Version}`,inline = true },
			{ name = "Player Information", value = `Account Age: {player.AccountAge or 0 .. " days ("..string.format("%.2f", player.AccountAge/365 or 0).." years)"}\nMembership: {player.MembershipType.Name or 'none'}`,inline = true },
		}

		local Data = {
			["embeds"] = { EmbedData },
		}

		local success, msg = pcall(function()
			local request = http:RequestAsync({
				Url = `{PluginSettings.BaseURL}{PluginSettings.AntiWebhook}`,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["Access-Key"] = PluginSettings.APIKey,
				},
				Body = http:JSONEncode(Data),
			})
		end)
		if not success then
			warn(msg)
		end

	end

end;

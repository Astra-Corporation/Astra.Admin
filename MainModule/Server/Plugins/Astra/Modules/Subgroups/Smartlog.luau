--[==[
    EasternBloxxer
    Astra Defense Network
--]==]

--// 8ch here to do some bug fixes + cleaning



--// I dont know who put that comment there but when i remove it stuff breaks. Dont get rid of it.

return function(Vargs)
	local Server = Vargs.Server;
	local Service = Vargs.Service;

	-- Modules used

	local Variables = Server.Variables;
	local Commands = Server.Commands;
	local Admin = Server.Admin;
	local Settings = Server.Settings;
	local Anti = Server.Anti;
	local Functions = Server.Functions;
	local Remote = Server.Remote;
	local Logs = Server.Logs;

	-- Some vars
	local Prefix = Settings.Prefix;
	local Players = Service.Players;
	local Asset = { Name = "Failed to fetch Place Info" } 

	pcall(function()
		Asset = Service.MarketplaceService:GetProductInfo(game.PlaceId)
	end)

	-- Variables for external use

	Variables.SmartlogStarted = false
	Variables.SmartlogData = {
		Data = {};
		Note = "";
		Creator = {};
	}

	local Prefix = Settings.Prefix
	local OpenInfo = {
		{ Text = `{Prefix}smartlog open`, Desc = "Opens this menu"},
		{ Text = `{Prefix}smartlog addpoints <player> <points>`, Desc = "Adds the specified point amount to the player's point log" },
		{ Text = `{Prefix}smartlog setpoints <player> <points>`, Desc = "Sets the specified point amount to the player's point log" },
		{ Text = `{Prefix}smartlog remove <player>`, Desc = "Removes a player from the log"},
		{ Text = `{Prefix}smartlog start`, Desc = "Starts the log"},
		{ Text = `{Prefix}smartlog download`, Desc = "Shows a list of players included and how many points they will get" },
		{ Text = `{Prefix}smartlog export`, Desc = "Saves current log data to the stores, shows them on the leaderboard" },
		{ Text = `{Prefix}smartlog end`, Desc = "Ends the log, clearing the log data" },
		{ Text = `{Prefix}smartlog leaderboard`, Desc = "Shows the points players get on leaderboard (REMOVE WHEN LEAVING WITH ;REMOVESTAT!)" },
		{ Text = `{Prefix}smartlog setnote <note>`, Desc = "Adds a note to your log" },
	}

	local function getUsersByPoints(users)
		local pointsTable = {};

		for _, user in users do
			local points = user[1];
			local username = user[3];
			if points ~= 0 then
				pointsTable[points] = pointsTable[points] or {};
				table.insert(pointsTable[points], username);
			end;
		end;

		local output = {}

		for points, usernames in pointsTable do
			table.insert(output, `{points} - {table.concat(usernames, ",")}`)
		end;

		return output;
	end;

	local Actions = {
		start = function(p: Player, Silent: string?)
			if Variables.SmartlogStarted then
				return 'Smartlog is already running!'
			end;

			local HintTargets = { p }

			for _, Player:Player in ipairs(Service.GetPlayers()) do
				if not Variables.SmartlogData.Data[Player.UserId] then
					Functions.Hint(`Added @{Player.Name} ({Player.UserId}) to the users table`,HintTargets,2)
					Variables.SmartlogData.Data[Player.UserId] = {0, false,Player.Name}
				end
			end

			if string.lower(`{Silent}`) ~= "silent" then
				Functions.Notify(`SmartLog`, `Players past this point will be marked as late.`, Service.GetPlayers())
			end

			Variables.SmartlogData.Creator = { id = p.UserId, username = p.Name }
			Variables.SmartlogData.Note = ""
			Variables.SmartlogStarted = true
		end,
		["end"] = function(Player:Player) 
			if not Variables.SmartlogStarted then
				return 'Smartlog has not been started!'
			end;

			local ans, event = Remote.GetGui(Player, "YesNoPrompt", {Question = "Do you want to let the players know that they can leave?"})

			if ans == "Yes" then
				Functions.Notify(`SmartLog`, `You are now dismissed`, Service.GetPlayers())
			end

			Variables.SmartlogStarted = false
			Variables.SmartlogData.Note = "";
			Variables.SmartlogData.Creator = {};

			table.clear(Variables.SmartlogData.Data)
		end,
		download = function(Player:Player) 
			if not Variables.SmartlogStarted then
				return 'Smartlog has not been started!'
			end;

			Remote.MakeGui(Player, "Text", { Text = table.concat(getUsersByPoints(Variables.SmartlogData.Data), "\n") });
		end,
		export = function(p:Player) 
			if not Variables.SmartlogStarted then
				return error('Smartlog has not been started!')
			end;

			assert(Server.Atlas, "Atlas hasn't initialized!")

			local ans, event = Remote.GetGui(p, "YesNoPrompt", {Question = "Are you sure you want to export?"})

			if ans ~= "Yes" then
				return	error("Exporting cancelled")
			end

			local pointsData = {
				data = {};
				notes = `Exported from [{Asset.Name}](https://www.roblox.com/games/{Asset.AssetId})\nServer: {game.JobId ~= "" and `\`{game.JobId}\`` or "\`STUDIO\`"}\nNote: {Variables.SmartlogData.Note ~= "" and Variables.SmartlogData.Note or "No note provided"}`;
				creator = Variables.SmartlogData.Creator
			}

			for playerId, data in pairs(Variables.SmartlogData.Data) do
				if data[1] ~= 0 then
					table.insert(pointsData.data, { id = tonumber(playerId), points = tonumber(data[1]) or 0, username = data[3] })
				end
			end

			local Success, Result = pcall(function()
				return Server.Atlas:Post("v1/guild/data/pointlogs/new", pointsData)
			end)

			if Result.StatusCode == 200 then
				Functions.Hint("Database work over, you may now leave.", {p}, 6)
				local ans, event = Remote.GetGui(p, "YesNoPrompt", {Question = "Do you want to show players their points?"})

				if ans == "Yes" then
					Admin.RunCommand(`{Settings.Prefix}addstat Points`)
					local Data = Variables.SmartlogData.Data

					for _, Player in ipairs(Service.Players:GetPlayers()) do
						Functions.ChangeStat(Player, "Points", `{Data[Player.UserId][1]}`)
					end
				end
				return true;
			else				
				Logs.AddLog(Logs.Errors, {
					Text = `Something went wrong while exporting a smartlog!`,
					Desc = `{Result.error.name}: {Result.error.message}`
				});
				error(`Something went wrong while exporting your smartlog; {Result.error.name}: {Result.error.message}`)
				return false;
			end
		end,
		setnote = function(p:Player,note:string) 
			if not Variables.SmartlogStarted then
				error('Smartlog has not been started!')
			end
			if not note then
				error('You did not provide a note!');
			end

			Variables.SmartlogData.Note = note
		end,
		open = function(p:Player)
			local Data  = {}

			for i, v in pairs(Variables.SmartlogData.Data) do
				if v[1] ~= 0 then
					table.insert(Data, 1, {Text = tostring(`{v[3]} - {v[1]} Points`), Desc = ``})
				end
			end

			Remote.MakeGui(p, "Smartlog", {Commands = OpenInfo, Data = Data})
		end,
		setpoints = function(Player:Player, Players:Player ,Points:string)
			if not Variables.SmartlogStarted then
				error('Smartlog has not been started!');
			end;

			assert(Player, "Argument 2 is required!")
			assert(Points, "Argument 3 is required!")

			local UseStat = string.match(Points,'stat/')
			local stat, rmi, rma = string.match(Points,'stat/(%w+)/?(%-?%d*)/?(%-?%d*)')
			local min, max = tonumber(rmi or -500000), tonumber(rma or 500000) --// A limit that should never be reached. As the defau;t.

			for _, Trainee in pairs(Service.GetPlayers(Player, Players)) do
				if not Variables.SmartlogData.Data[Trainee.UserId] then
					Variables.SmartlogData.Data[Trainee.UserId] = {0, false,Trainee.Name}
					Functions.Hint(`Added @{Trainee.Name} ({Trainee.UserId}) to the users table`,{Player},2)
				end

				if UseStat and stat then
					local leaderstats = Trainee:FindFirstChild('leaderstats') 
					if not leaderstats then
						return warn(`{Trainee.Name} did not have a leaderstat folder!`)
					end

					local Stat = leaderstats:FindFirstChild(stat)
					if not Stat then 
						return
					end;

					Points = math.clamp(Stat.Value,min,max)
				end;

				assert(tonumber(Points),"Points argument must be a number")

				Variables.SmartlogData.Data[Trainee.UserId][1] = Points
			end

		end,
		addpoints = function(Player:Player, Players:Player ,Points:string)
			if not Variables.SmartlogStarted then
				return 'Smartlog has not been started!'
			end;

			assert(Player, "Argument 2 is required!")
			assert(Points, "Argument 3 is required!")

			local UseStat = string.match(Points,'stat/')
			local stat, rmi, rma = string.match(Points,'stat/(%w+)/?(%-?%d*)/?(%-?%d*)')
			local min, max = tonumber(rmi or -500000), tonumber(rma or 500000) --// A limit that should never be reached

			for _, Trainee in pairs(Service.GetPlayers(Player, Players)) do
				if not Variables.SmartlogData.Data[Trainee.UserId] then
					Variables.SmartlogData.Data[Trainee.UserId] = {0, false,Trainee.Name}
					Functions.Hint(`Added @{Trainee.Name} ({Trainee.UserId}) to the users table`,{Player},2)
				end

				if UseStat and stat then
					local leaderstats = Trainee:FindFirstChild('leaderstats') 
					if not leaderstats then
						return warn(`{Player.Name} did not have a leaderstat folder!`)
					end

					local Stat = leaderstats:FindFirstChild(stat)
					if not Stat then 
						return
					end;

					Points = math.clamp(Stat.Value,min,max)
				end;

				assert(tonumber(Points),"Points argument must be a number")

				Variables.SmartlogData.Data[Trainee.UserId][1] += Points
			end
		end,
		remove = function(Player: Player, Targets: string?)
			if not Variables.SmartlogStarted then
				return 'Smartlog has not been started!'
			end;

			assert(Targets, "Argument 2 is required!")

			local Data = Variables.SmartlogData.Data
			local Players = Service.GetPlayers(Player, Targets)

			if #Players == 0 then return end

			for _, TargetedPlayer in ipairs(Players) do
				Data[TargetedPlayer.UserId] = nil
			end
		end,
		leaderboard = function(Player: Player)
			Admin.RunCommand(`{Settings.Prefix}addstat Points`)
			local Data = Variables.SmartlogData.Data

			for _, Player in ipairs(Service.Players:GetPlayers()) do
				Functions.ChangeStat(Player, "Points", `{Data[Player.UserId][1]}`)
				--// We should be using runcommand for this. Adonis does not have this function and the bug that made me use it has been fixed
			end
		end,
	}

	Remote.Commands.SmartlogData = function(Player:Player)
		local Data  = {}

		if not Admin.CheckAdmin(Player) then
			Anti.Detected(Player,"kick","Attempted to fetch smartlog data without access")
		end

		for i, v in pairs(Variables.SmartlogData.Data) do
			if v[1] ~= 0 then
				table.insert(Data, 1, {Text = tostring(`{v[3]} - {v[1]} Points`), Desc = ``})
			end
		end

		return {Commands = OpenInfo, Data = Data}
	end

	Commands.Smartlog = {
		Prefix = Settings.Prefix;
		Commands = {"smartlog"};
		Args = {"method", "optional argument", "optional argument"};
		Description = "Manages smartlogs";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators"; --// TODO: Custom permission checks for commands such as group ranks
		Function = function(plr,args)
			local method = string.lower(assert(args[1], "Method argument missing!"))
			local MethodFunction = assert(Actions[method], `Invalid action! Valid methods: {table.concat(Actions,"/")}`)

			table.remove(args, 1)

			MethodFunction(plr, table.unpack(args));
		end
	}

	Service.HookEvent("PlayerAdded", function(Player:Player)
		if Variables.SmartlogStarted then
			Variables.SmartlogData.Data[Player.UserId] = {0, false,Player.Name}
		end
	end)
end
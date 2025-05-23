return function(Vargs)
	local Server = Vargs.Server;
	local Service = Vargs.Service;

	-- Modules used

	local Variables = Server.Variables;
	local Commands = Server.Commands;
	local Admin = Server.Admin;
	local HTTP = Server.HTTP;
	local Settings = Server.Settings;
	local Functions = Server.Functions;
	local Logs = Server.Logs;
	local Remote = Server.Remote;

	-- Some vars
	local Prefix = Settings.Prefix;
	local DoCheck = Admin.DoCheck;
	local TrackTask = Service.TrackTask
	local AddLog = Logs.AddLog;
	
	local Actions = "on/off/add/remove/reason"
	local Required = Admin.LevelToListName(100)
	
	Functions.AddJoinFilter("Whitelist",function(Player:Player, PlayerData)
		if Variables.Whitelist.Enabled then
			local listed = false
			local level, rankName = Admin.GetLevel(Player)
			local WhitelistData = Variables.Whitelist
			
			if level >0 then
				return true
			end
			
			local CheckTable = Admin.CheckTable
			for listName, list in Variables.Whitelist.Lists do
				if CheckTable(Player, list) then
					listed = true
					break;
				end
			end

			if not listed then
				return false,`This server is whitelisted\r\nWhitelisted by: {WhitelistData.Moderator or "GAME"}\nYour permission level: {rankName or "Unknown"}\nRequired permission level: {Required} or LISTED\n Reason: {WhitelistData.Reason}`	
			end
			
			return true
		end
		
		return true
	end);
	
	
	Commands.Whitelist = {
		Prefix = Settings.Prefix,
		Commands = { "wl", "enablewhitelist", "whitelist" },
		Args = { "method", "optional argument" },
		Hidden = false,
		Description = `Enables/disables the whitelist; {Settings.Prefix}wl username to add them to the whitelist`,
		Fun = false,
		AdminLevel = "Moderators",
		Function = function(plr, args)
			if args[1]:lower() == "on" or args[1]:lower() == "enable" then
				Variables.Whitelist.Enabled = true
				Variables.Whitelist.TimeEnabled = os.time()
				Variables.Whitelist.Moderator = plr.Name or "Unknown"

				Functions.Hint("Server Whitelisted", Service.Players:GetPlayers())
			elseif args[1]:lower() == "off" or args[1]:lower() == "disable" then
				Variables.Whitelist.Enabled = false
                Functions.Hint("Server Unwhitelisted", Service.Players:GetPlayers())
			elseif args[1]:lower() == "add" then
				if args[2] then
					local plrs = Service.GetPlayers(plr, args[2])
					if #plrs > 0 then
						for i, v in pairs(plrs) do
							table.insert(Variables.Whitelist.Lists.Settings, v.Name .. ":" .. v.userId)
							Functions.Hint(`Whitelisted {v.Name}`, { plr })
						end
					else
						table.insert(Variables.Whitelist.Lists.Settings, args[2])
					end
				else
					error("Missing name to whitelist")
				end
			elseif args[1]:lower() == "remove" then
				if args[2] then
					for i, v in pairs(Variables.Whitelist.Lists.Settings) do
						if v:lower():sub(1, #args[2]) == args[2]:lower() then
							table.remove(Variables.Whitelist.Lists.Settings, i)
							Functions.Hint(`Removed {tostring(v)} from the whitelist`, { plr })
						end
					end
				else
					error(`Missing name to remove from whitelist`)
				end
			elseif args[1]:lower() == "reason" then
				if args[2] then
					local Reason = Service.Filter(args[2], plr, plr)
					Variables.Whitelist.Reason= Reason
					Functions.Hint(`Reason set "{Reason}"`, { plr })
				end
			elseif args[1]:lower() == "list" then
				local Data = {}
				
				for Key, List in Variables.Whitelist.Lists do
					local Prefix = Key == "Settings" and "" or `[{Key}] `
					for _, User in List do
						table.insert(Data, {Text = Prefix .. User, Desc = User})
					end
				end
				
				Remote.MakeGui(plr, "List", {
					Title = "Whitelist";
					Table = Data;

				})
			elseif args[1]:lower() == "open" then
				local Data  = {}

				for i, v in pairs(Variables.WhitelistData.List) do
					if v[1] ~= 0 then
						table.insert(Data, 1, {Text = tostring(v), Desc = v})
					end
				end
				Remote.MakeGui(plr, "Whitelist", {
					List = Data;
				})
			else
				error(`Invalid action; ({Actions})`)
			end
		end,
	}
end

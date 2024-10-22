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

	Functions.ChangeStat = function(plr,stat,value)	
		local statName = assert(stat, "Missing stat name (argument #2)")
		local valueToAdd = assert(tonumber(value), "Missing/invalid numerical value to add (argument #3)")

		local leaderstats = plr:FindFirstChild("leaderstats")
		if leaderstats then
			leaderstats.Name = "leaderstats"
			local absoluteMatch = leaderstats:FindFirstChild(statName)
			if absoluteMatch and (absoluteMatch:IsA("IntValue") or absoluteMatch:IsA("NumberValue")) then
				absoluteMatch.Value = valueToAdd
			else
				for _, st in leaderstats:GetChildren() do
					if (st:IsA("IntValue") or st:IsA("NumberValue")) and string.match(st.Name:lower(), `^{statName:lower()}`) then
						st.Value = valueToAdd
					end
				end
			end
		else
			Functions.Hint(`{Service.FormatPlayer(plr.Name)} doesn't have a leaderstats folder`, {plr})
		end
	end	--// Remove when RunCommand fixed and make smartlog run the command

	Functions.GetAdmins = function()
		local ret = {}
		for _,v in pairs(Service.GetPlayers()) do
			if Admin.CheckAdmin(v) then table.insert(ret,v) end
		end
		return ret
	end

	Functions.getServerType = function()
		local PrivateServerId = game.PrivateServerId
		local PrivateServerOwnerId = game.PrivateServerOwnerId
		if game:GetService("RunService"):IsStudio() then
			return "Studio"
		else
			if PrivateServerId ~= "" then
				if PrivateServerOwnerId ~= 0 then
					return "Private"
				else
					return "Reserved"
				end
			else
				return "Standard"
			end
		end
	end;

	Functions.newTeam = function(name:string,color)
		local teamName = assert(name, "Missing team name (argument #1)")
		local teamColor = Functions.ParseBrickColor(color)
		Service.New("Team", {
			Parent = Service.Teams;
			Name = teamName;
			TeamColor = teamColor;
			AutoAssignable = false;
		})
	end;

	Functions.SendJoinNotif = function(player:Player)
		for i,v in Service.GetPlayers() do
			Remote.Send(v, "Function", "ChatMessage",  `{player.Name} has joined`, Color3.new(1, 1, 1),Enum.Font.SourceSansLight,Enum.FontSize.Size10)
		end
	end;

	Functions.SendLeaveNotif = function(player:Player)
		for i,v in Service.GetPlayers() do
			Remote.Send(v, "Function", "ChatMessage",`{player.Name} has left`, Color3.new(1, 1, 1),Enum.Font.SourceSansLight,Enum.FontSize.Size10)
		end
	end;

	Functions.EpochToHuman = function(Epoch)
		local Weeks = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
		local Months = {"January"; "February"; "March"; "April"; "May"; "June"; "July"; "August"; "September"; "October"; "November"; "December"}
		local TimeTable = os.date("!*t", tonumber(Epoch))

		local Week = Weeks[TimeTable.wday]
		local Month = Months[TimeTable.month]
		local Day = TimeTable.day
		local Year = TimeTable.year

		local hour, am_pm

		if TimeTable.hour >= 12 then
			hour = TimeTable.hour - 12
			am_pm = "PM"
		else
			hour = TimeTable.hour
			am_pm = "AM"
		end

		if hour == 0 then
			hour = 12
		end

		local Hour = string.format("%02s", tostring(hour))
		local Minute = string.format("%02s", tostring(TimeTable.min))
		local Seconds = string.format("%02s", tostring(TimeTable.sec))

		local TimeString = Week.." "..Month.." "..Day.." @ "..Hour..":"..Minute..":"..Seconds.." "..am_pm.." (UTC)"
		return TimeString
	end;

	Functions.GetKickMessage = function(Type, Data)
		local Message = Settings.CustomKickMessages[Type] or Variables.DefaultKickMessage;

		if type(Message) == "table" then
			Message = table.concat(Message, "\n")	
		end

		if tonumber(Data.time) then
			Data.time = Functions.EpochToHuman(Data.time)
		end

		if tonumber(Data.expireTime) then
			Data.expireTime = Functions.EpochToHuman(Data.expireTime)
		end

		local yay, response = pcall(function()
			Message = string.gsub(Message, "{reason}", Data.reason or "No Reason Provided")
			Message = string.gsub(Message, "{time}", Data.time or "None")
			Message = string.gsub(Message, "{name}", Data.name or "nil")
			Message = string.gsub(Message, "{id}", Data.id or "nil")
			Message = string.gsub(Message, "{moderator}", Data.moderator.Name or "Server")
			Message = string.gsub(Message, "{type}", Data.kickType or "nil")
			Message = string.gsub(Message, "{expiretime}", Data.expireTime or "nil")
			Message = string.gsub(Message, "{remainingtime}", Data.remainingTime or "nil")
			Message = string.gsub(Message, "{filter}", Data.filter or "Could not receive!")
			Message = string.gsub(Message, "{error}", Data.error or "Could not receive!")
		end)

		if not yay then
			return 'SOMETHING WENT WRONG WHILE THE KICK MESSAGE WAS BEING SET'
		end

		return Message
	end;

	Functions.GetSlockMessage = function()
		local SlockData = Variables.SlockData
		local Data = {
			reason = SlockData.Reason;
			time = SlockData.TimeEnabled;
			name = "nil";
			id = 0;
			moderator = SlockData.Moderator;
			kickType = "nil";
			expireTime = "nil";
			remainingTime = "nil";
		}

		return Functions.GetKickMessage("Lock", Data)
	end;

	Functions.GetWhitelistMessage = function()
		local WhitelistData = Variables.WhitelistData
		local Data = {
			reason = WhitelistData.Reason;
			time = WhitelistData.TimeEnabled;
			name = "nil";
			id = 0;
			moderator = WhitelistData.Moderator;
			kickType = "nil";
			expireTime = "nil";
			remainingTime = "nil";
		}

		return Functions.GetKickMessage("Whitelist", Data)
	end;

	--Functions.GetJoinFilterMessage = function()
	--	local WhitelistData = Variables.WhitelistData
	--	local Data = {
	--		reason = WhitelistData.Reason;
	--		time = WhitelistData.TimeEnabled;
	--		name = "nil";
	--		id = 0;
	--		moderator = WhitelistData.Moderator;
	--		kickType = "nil";
	--		expireTime = "nil";
	--		remainingTime = "nil";
	--	}

	--	return Functions.GetKickMessage("Whitelist", Data)
	--end;

end

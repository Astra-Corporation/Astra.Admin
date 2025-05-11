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
	local UseNewChat = Service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService
	
	local function GetTextToSend(Text)
		return `<font size="15" color="rgb(255,255,255)" face="SourceSansLight">{Service.SanitizeXML(Text)}</font>`
	end
	
	Variables.JoinMessagesEnabled = true
	
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
		if not Variables.JoinMessagesEnabled then
			return
		end
		
		for i,v in Service.GetPlayers() do
			if UseNewChat then
				Remote.Send(v, "Function", "DisplaySystemMessageInTextChat", nil, GetTextToSend(`{player.Name} has joined`))
			end
			Remote.Send(v, "Function", "ChatMessage",  `{player.Name} has joined`, Color3.new(1, 1, 1),Enum.Font.SourceSansLight,Enum.FontSize.Size10)
		end
	end;

	Functions.SendLeaveNotif = function(player:Player)
		if not Variables.JoinMessagesEnabled then
			return
		end

		for i,v in Service.GetPlayers() do
			if UseNewChat then
				Remote.Send(v, "Function", "DisplaySystemMessageInTextChat", nil, GetTextToSend(`{player.Name} has left`))
			end
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
		local Message = Settings.CustomKickMessages[Type] or Variables.DefaultKickMessages[Type];

		if not Message then
			Message = Variables.DefaultKickMessage	
		end
		
		if type(Message) == "table" then
			Message = table.concat(Message, "\n")	
		end

		if tonumber(Data.time) then
			Data.time = Functions.EpochToHuman(Data.time)
		end

		if tonumber(Data.expiretime) then
			Data.expiretime = Functions.EpochToHuman(Data.expiretime)
		end
		
		if tonumber(Data.remainingtime) then
			Data.remainingtime = Functions.EpochToHuman(Data.remainingtime)
		end
		
		local placeholders = {
			reason = "No Reason Provided",
			time = "0",
			name = "nil",
			id = "nil",
			moderator = (Data.moderator and Data.moderator.Name) or "Game",
			type = Data.kickType or "nil",
			expiretime = "Not set",
			remainingtime = "Not set",
			filter = "Could not receive!",
			error = "",
			KickMessageType = Type or "Could not receive!"
		}

		for placeholder, defaultValue in pairs(placeholders) do
			local value = Data[placeholder] or defaultValue
			Message = string.gsub(Message, `\{{placeholder}\}`, value)
		end

		return Message
	end;

	Functions.GetSlockMessage = function() --TODO: Get rid of this
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
end
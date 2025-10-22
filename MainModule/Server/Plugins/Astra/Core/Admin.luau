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
	local GroupService = server.GroupService;

	local TrackTask = service.TrackTask

	Admin.AddBan = function(p, reason, doSave, moderator)
		local value = {
			Name = p.Name;
			UserId = p.UserId;
			Reason = reason;
			Moderator = if moderator then service.FormatPlayer(moderator) else "%SYSTEM%";
		}

		local banData = {
			reason = reason or "No Reason Provided";
			time = os.time();
			name = p.Name or "Unknown";
			id = p.UserId or "Unknown";
			moderator = {Name = moderator.Name or "Unknown"; UserId = moderator.UserId or "Unknown"};
			expireTime = "Game Ban";
			remainingTime = "Game Ban"
		}

		table.insert(Settings.Banned, value)--`{p.Name}:{p.UserId}`

		if type(p) ~= "table" then
			if not service.Players:FindFirstChild(p.Name) then
				Remote.Send(p,'Function','KillClient')
			else
				if p then pcall(function() p:Kick(Functions.GetKickMessage("GameBan",banData)) end) end
			end
		end

		if doSave then
			Core.DoSave({
				Type = "TableAdd";
				Table = "Banned";
				Value = value;
			})

			Core.CrossServer("RemovePlayer", p.Name, Variables.BanMessage, value.Reason or "No reason provided")
		end

		service.Events.PlayerBanned:Fire(p, reason, doSave, moderator)
	end;

	Admin.GetLevelName = function(lvl)
		if lvl > 999 then
			return "Creator";
		elseif lvl == 0 then
			return "Player";
		end

		--// Check if this is a default rank and if the level matches the default (so stuff like [Trello] Admins doesn't appear in the command list)
		for i,v in pairs(server.Defaults.Settings.Ranks) do
			local tRank = Settings.Ranks[i];
			if tRank and tRank.Level == v.Level and v.Level == lvl then
				return string.sub(i,1,-2);
			end
		end

		for i,v in pairs(Settings.Ranks) do
			if v.Level == lvl then
				return i;
			end
		end
	end;

	Admin.IsAlias = function(Player, Message)
		local PlayerAliases = Core.GetPlayer(Player).Aliases;

		if not PlayerAliases then
			return false;
		end;

		local Lowered = string.lower(Message);

		for Alias, Data in PlayerAliases do
			if string.match(Lowered, `^{Alias}%s+`) or string.match(Lowered,`^{Alias}$`) then
				return Alias, Data;
			end;
		end;

		return false;
	end;

	Admin.IsRecursiveAlias = function(Player, Alias, Exec)
		local Aliases = 0

		for Cmd in string.gmatch(Exec, `[^{Settings.BatchKey}]+`) do
			local Lowered = string.lower(Cmd);
			local Alias = string.lower(Alias)
			local noSpace = string.gsub(Cmd," ","")
			local isAlias = Admin.IsAlias(Player, noSpace)

			if isAlias then
				Aliases +=1
			end

			if string.match(Lowered, `^%s*{Alias}%s*$`) or string.match(Lowered,`^{Alias}$`)  then
				return true
			end
		end

		if Aliases >= 5 then
			return "Your alias ran more than 5 aliases and has not been run for security reasons!"
		end

		--print(`{Alias} had {Aliases} aliases in it!`)
		return false
	end

	-- if ur looking for DoHideChatCmd then i put it back in module itself. Not the plugin.

	Admin.GetAdmins = function()
		local ret = {}
		for _,v in pairs(service.GetPlayers()) do
			if Admin.CheckAdmin(v) then table.insert(ret,v) end
		end
		return ret
	end

	Admin.AddAdmin = function(p, level, temp)
		local current, rank = Admin.GetLevel(p)
		local list = rank and Settings.Ranks[rank];
		local levelName, newRank, newList;

		if type(level) == "string" then
			local newRank = Settings.Ranks[level];
			levelName = newRank and level;
			newList = newRank and newRank.Users
			level = (newRank and newRank.Level) or Admin.StringToComLevel(levelName) or level;
		else
			local nL, nLN = Admin.LevelToList(level);
			levelName = nLN;
			newRank = nLN;
			newList = nL;
		end

		Admin.RemoveAdmin(p, temp)
		Admin.SetLevel(p, level, nil, levelName)

		if temp then
			table.insert(Admin.TempAdmins,p)
		end

		if list and type(list) == "table" then
			local index,value

			for ind,ent in ipairs(list) do
				if (type(ent)=="number" or type(ent)=="string") and (ent==p.userId or string.lower(ent)==string.lower(p.Name) or string.lower(ent)==string.lower(p.Name..":"..p.userId)) then
					index = ind
					value = ent
				end
			end

			if index and value then
				table.remove(list, index)
			end
		end

		local value = p.Name ..":".. p.UserId

		if newList then
			table.insert(newList,value)

			if Settings.SaveAdmins and levelName and not temp then
				TrackTask("Thread: SaveAdmin", Core.DoSave, {
					Type = "TableAdd";
					Table = {"Settings", "Ranks", levelName, "Users"};
					Value = value
				})
			end
		end

		Admin.UpdateCachedLevel(p)

		if service.Players:FindFirstChild(p.Name) then
			pcall(function()
				local newrank = Core.GetPlayer(p).AdminLevel
				if newrank >= current then
					Remote.MakeGui(p,"Notification",{
						Title = "Admin Level";
						Message = "Raised to "..(Admin.GetLevelName(Core.GetPlayer(p).AdminLevel) or "Custom").." ("..tostring(Core.GetPlayer(p).AdminLevel)..")";
						Time = 15;
					})
				else
					Remote.MakeGui(p,"Notification",{
						Title = "Admin Level";
						Message = "Lowered to "..Core.GetPlayer(p).AdminRank.." ("..(Admin.GetLevelName(Core.GetPlayer(p).AdminLevel) or "Custom")..")";
						Time = 15;
					})
				end
				Remote.RemoveGui(p,"Console")
				Remote.MakeGui(p,"Console")
			end)
		end
	end;

end

return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local function KDR(kills, deaths)
		if deaths == 0 then return kills end
		return kills/deaths
	end

	local KOsWOs = {}
	service.HookEvent("PlayerAdded", function(player)
		if not KOsWOs[player.UserId] then
			KOsWOs[player.UserId] = {Kills = 0, Deaths = 0}
		end
		player.CharacterAdded:Connect(function()
			KOsWOs[player.UserId].Deaths = KOsWOs[player.UserId].Deaths + 1
			if player:FindFirstChild("leaderstats")then 
				if player.leaderstats:FindFirstChild("Deaths") then
					player.leaderstats.Deaths.Value = player.leaderstats.Deaths.Value + 1
				end
				if player.leaderstats:FindFirstChild("KDR") then
					player.leaderstats.KDR.Value = KDR(KOsWOs[player.UserId].Kills, KOsWOs[player.UserId].Deaths)
				end
			end
			player.Character:WaitForChild("Humanoid")
			player.Character.Humanoid.Died:Connect(function()
				for _,Child in ipairs(player.Character.Humanoid:GetChildren()) do
					if Child:IsA("ObjectValue") and Child.Value and Child.Value:IsA("Player") then
						local Killer = Child.Value
						KOsWOs[Killer.UserId].Kills = KOsWOs[Killer.UserId].Kills + 1
						if Killer:FindFirstChild("leaderstats") then 
							if Killer.leaderstats:FindFirstChild("Kills") then
								Killer.leaderstats.Kills.Value = Killer.leaderstats.Kills.Value + 1
							end
							if Killer.leaderstats:FindFirstChild("KDR") then
								Killer.leaderstats.KDR.Value = KDR(KOsWOs[Killer.UserId].Kills, KOsWOs[Killer.UserId].Deaths)
							end
						end
						return
					end
				end
			end)
		end)
	end)

	local leaderstatConnections = {}
	local statPersistence = {}
	server.Commands.AddStat = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"addstat", "addleaderstat"};	-- Commands
		Args = {"name"};	-- Command arguments
		Description = "Adds an integer as a stat in leaderstats";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Moderators";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr,args)    -- Function to run for command
			assert(args[1], "Argument missing or nil")
			local statname = table.concat(args, " ")
			for _,player in ipairs(game.Players:GetPlayers()) do
				if not player:FindFirstChild("leaderstats") then
					local stats = Instance.new("Folder")
					stats.Name = "leaderstats"
					stats.Parent = player
				end
				local statexists = false
				for _,stat in ipairs(player.leaderstats:GetChildren()) do
					if stat.Name:lower() == statname then
						statexists = true
					end
				end
				if not statexists then
					if statname:lower() == "kdr" then
						local val = Instance.new("NumberValue")
						val.Name = "KDR"
						val.Parent = player.leaderstats
						server.Commands.AddStat.Function(plr, {"Kills"})
						server.Commands.AddStat.Function(plr, {"Deaths"})
						val.Value = KDR(KOsWOs[player.UserId].Kills, KOsWOs[player.UserId].Deaths)
					elseif statname:lower() == "kills" or statname:lower() == "kos" or statname:lower() == "knockouts" then
						local val = Instance.new("IntValue")
						val.Name = "Kills"
						val.Parent = player.leaderstats
						for _,record in pairs(KOsWOs) do
							record.Kills = 0
						end
					elseif statname:lower() == "deaths" or statname:lower() == "wos" or statname:lower() == "wipeouts" then
						local val = Instance.new("IntValue")
						val.Name = "Deaths"
						val.Parent = player.leaderstats
						for _,record in pairs(KOsWOs) do
							record.Deaths = 0
						end
					else
						local val = Instance.new("IntValue")
						val.Name = statname
						val.Parent = player.leaderstats
					end
				end
				leaderstatConnections[statname] = {}
				statPersistence[statname] = {}
				leaderstatConnections[statname].Join = game.Players.PlayerAdded:Connect(function(player)
					task.wait(2)
					if not player:FindFirstChild("leaderstats") then
						local stats = Instance.new("Folder")
						stats.Name = "leaderstats"
						stats.Parent = player
					end
					if statname:lower() == "kdr" then
						local val = Instance.new("NumberValue")
						val.Name = statname
						val.Value = statPersistence[statname][tostring(player.UserId)] or 0
						val.Parent = player.leaderstats
					else
						local val = Instance.new("IntValue")
						val.Name = statname
						val.Value = statPersistence[statname][tostring(player.UserId)] or 0
						val.Parent = player.leaderstats
					end
				end)
				leaderstatConnections[statname].Leave = game.Players.PlayerRemoving:Connect(function(player)
					statPersistence[statname][tostring(player.UserId)] = player.leaderstats[statname].Value
				end)
			end
		end
	}
	server.Commands.DelStat = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"delstat", "delleaderstat", "removestat", "removeleaderstat"};	-- Commands
		Args = {"name"};	-- Command arguments
		Description = "Removes a stat in leaderstats";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Moderators";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr,args)    -- Function to run for command
			assert(args[1], "Argument missing or nil")
			local statname = table.concat(args, " ")
			local targettedstat
			for _,player in ipairs(service.GetPlayers()) do
				if player:FindFirstChild("leaderstats") then
					for _,currentstat in ipairs(player.leaderstats:GetChildren()) do
						if currentstat:IsA("IntValue") and currentstat.Name:sub(1, #statname):lower() == statname:lower() then
							targettedstat = currentstat.Name
							currentstat:Destroy()
							break
						end
					end
				end
			end
			leaderstatConnections[targettedstat].Join:Disconnect()
			leaderstatConnections[targettedstat].Leave:Disconnect()
			leaderstatConnections[targettedstat] = nil
			statPersistence[targettedstat] = nil
		end
	}
	--server.ChangeStat = {
	--	Prefix = server.Settings.Prefix;
	--	Commands = {"change";"leaderstat";"stat";};
	--	Args = {"player", "stat", "value"};
	--	Description = "Add <value> to <stat>";
	--	AdminLevel = "Moderators";
	--	Function = function(plr: Player, args: {string})
	--		local statName = assert(args[2], "Missing stat name (argument #2)")
	--		local valueToAdd = assert(tonumber(args[3]), "Missing/invalid numerical value to add (argument #3)")
	--		for _, v in service.GetPlayers(plr, args[1]) do
	--			local leaderstats = v:FindFirstChild("leaderstats")
	--			if leaderstats then
	--				leaderstats.Name = "leaderstats"
	--				local absoluteMatch = leaderstats:FindFirstChild(statName)
	--				if absoluteMatch and (absoluteMatch:IsA("IntValue") or absoluteMatch:IsA("NumberValue")) then
	--					absoluteMatch.Value = valueToAdd
	--				else
	--					for _, st in leaderstats:GetChildren() do
	--						if (st:IsA("IntValue") or st:IsA("NumberValue")) and string.match(st.Name:lower(), `^{statName:lower()}`) then
	--							st.Value = valueToAdd
	--						end
	--					end
	--				end
	--			else
	--				server.Functions.Hint(`{service.FormatPlayer(v)} doesn't have a leaderstats folder`, {plr})
	--			end
	--		end
	--	end
	--};
	--server.Commands.Change = {
	--	Prefix = server.Settings.Prefix;
	--	Commands = {"change";"leaderstat";"stat";};
	--	Args = {"player";"stat";"value";};
	--	Filter = true;
	--	Description = "Change the target player(s)'s leader stat <stat> value to <value>";
	--	AdminLevel = "Moderators";
	--	Function = function(plr,args)
	--		for i,v in pairs(service.GetPlayers(plr,args[1])) do
	--			if v:findFirstChild("leaderstats") then 
	--				for a, st in pairs(v.leaderstats:children()) do
	--					if st.Name:lower():find(args[2]:lower()) == 1 then 
	--						st.Value = args[3]
	--					end
	--				end
	--			end
	--		end
	--	end
	--}
	--server.Commands.AddToStat = {
	--	Prefix = server.Settings.Prefix;
	--	Commands = {"add";"addtostat";"addstat";};
	--	Args = {"player";"stat";"value";};
	--	Hidden = false;
	--	Description = "Add <value> to <stat>";
	--	Fun = false;
	--	AdminLevel = "Moderators";
	--	Function = function(plr,args)
	--		for i,v in pairs(service.GetPlayers(plr,args[1])) do
	--			if v:findFirstChild("leaderstats") then 
	--				for a, st in pairs(v.leaderstats:children()) do
	--					if st.Name:lower():find(args[2]:lower()) == 1 and tonumber(st.Value) then 
	--						st.Value = tonumber(st.Value)+tonumber(args[3]) 
	--					end
	--				end
	--			end
	--		end
	--	end
	--}
	--server.Commands.SubtractFromStat = {
	--	Prefix = server.Settings.Prefix;
	--	Commands = {"subtract";"minusfromstat";"minusstat";"subtractstat";};
	--	Args = {"player";"stat";"value";};
	--	Hidden = false;
	--	Description = "Subtract <value> from <stat>";
	--	Fun = false;
	--	AdminLevel = "Moderators";
	--	Function = function(plr,args)
	--		for i,v in pairs(service.GetPlayers(plr,args[1])) do
	--			if v:FindFirstChild("leaderstats") then 
	--				for a, st in pairs(v.leaderstats:children()) do
	--					if st.Name:lower():find(args[2]:lower()) == 1 and tonumber(st.Value) then 
	--						st.Value = tonumber(st.Value)-tonumber(args[3]) 
	--					end
	--				end
	--			end
	--		end
	--	end
	--}
end
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

	local TrackTask = service.TrackTask
	
	Commands.Thaw = {
		Prefix = Settings.Prefix;
		Commands = {"thaw", "unfreeze", "unice"};
		Args = {"player"};
		Description = "UnFreezes the target players, thaws them out";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1]) do
				task.spawn(function()
					local Char = v.Character;

					if not Char then
						return;
					end;

					for _, BasePart in Char:GetChildren() do
						if BasePart:IsA("BasePart") then
							BasePart.Anchored = false;
						end;
					end;
				end)
			end
		end
	};

	Commands.Refresh = {
		Prefix = Settings.Prefix;
		Commands = {"refresh", "ref"};
		Args = {"player","optional skip"};
		Description = "Refreshes the target player(s)'s character";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			local doSkip = if args[2] and (args[2]:lower() == "true" or args[2]:lower() == "yes") then true else false;
			for i, p in service.GetPlayers(plr, args[1]) do
				task.defer(function()
					local oChar = p.Character;
					local oTools, pBackpack, oHumanoid, oPrimary, oPos;

					if oChar then
						oHumanoid = oChar:FindFirstChildOfClass("Humanoid");
						oPrimary = oChar.PrimaryPart or (oHumanoid and oHumanoid.RootPart) or oChar:FindFirstChild("HumanoidRootPart");

						if oPrimary then
							oPos = oPrimary.CFrame;
						end
					end

					--// Handle tool saving
					pBackpack = p:FindFirstChildOfClass("Backpack")

					local ev
					local hasGod = oHumanoid:HasTag('ARIDe_GOD') or false
					local hasfullGod = oHumanoid:HasTag('ARIDe_FULLGOD') or false
					local hasFly = oHumanoid:HasTag('ARIDe_FLIGHT') or false
					if pBackpack then
						oTools = {};
						ev = pBackpack.ChildAdded:Connect(function(c)
							table.insert(oTools, c)
							c.Parent = nil
						end)

						if oHumanoid then oHumanoid:UnequipTools() end
						for _, child in pBackpack:GetChildren() do
							table.insert(oTools, child)
							child.Parent = nil
						end
					end

					--// Handle respawn and repositioning
					local newChar, newHumanoid, newPrimary;
					task.delay(0.1, pcall, p.LoadCharacter, p)
					if ev then ev:Disconnect() end

					--// Reposition if possible
					if oPos then
						newChar = p.Character ~= oChar and p.Character or p.CharacterAdded:Wait()

						if newChar then
							wait(); -- Let it finish loading character contents

							newHumanoid = newChar:FindFirstChildOfClass("Humanoid");
							newPrimary = newChar.PrimaryPart or (newHumanoid and newHumanoid.RootPart) or oChar:FindFirstChild("HumanoidRootPart");

							local forcefield = newChar:FindFirstChildOfClass("ForceField")
							if forcefield then
								forcefield:Destroy()
							end

							if newPrimary then
								newPrimary.CFrame = oPos
							else
								newChar:MoveTo(oPos.Position)
							end
						end
					end

					--// Bring previous tools back
					local newBackpack = p:FindFirstChildOfClass("Backpack")
					if newBackpack and oTools then
						newBackpack:ClearAllChildren();
						for _, t in oTools do
							t.Parent = newBackpack
						end
					end

					if not doSkip then
						if hasFly then
							Admin.RunCommandAsPlayer(`{Settings.Prefix}fly {p.Name}`,p)
						end
						if hasfullGod then
							Admin.RunCommandAsPlayer(`{Settings.Prefix}fullgod {p.Name}`,p)
						end
						if hasGod then
							Admin.RunCommandAsPlayer(`{Settings.Prefix}god {p.Name}`,p)
						end --// this is ugly
					end

				end)
			end
		end
	};

	Commands.FullGod = {
		Prefix = Settings.Prefix;
		Commands = {"fullgod", "totalgod"};
		Args = {"player"};
		Description = `Same as {server.Settings.Prefix}god, but also provides blast protection`;
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1]) do
				local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.MaxHealth = math.huge
					hum.Health = 9e9
					hum:AddTag('ARIDe_FULLGOD')
					service.New("ForceField", {
						Parent = hum.Parent;
						Name = "ADONIS_FULLGOD";
						Visible = false;
					})
					if Settings.CommandFeedback then
						Functions.Hint("You have been fullgodded.", {v}, 15)
					end
				end
			end
		end
	};

	Commands.God = {
		Prefix = Settings.Prefix;
		Commands = {"god", "immortal"};
		Args = {"player"};
		Description = "Makes the target player(s) immortal, makes their health so high that normal non-explosive weapons can't kill them";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1]) do
				local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:AddTag('ARIDe_GOD')
					hum.MaxHealth = math.huge
					hum.Health = 9e9
					if Settings.CommandFeedback then
						Functions.Hint("You have been godded.", {v}, 15)
					end
				end
			end
		end
	};

	Commands.UnGod = {
		Prefix = Settings.Prefix;
		Commands = {"ungod", "mortal", "unfullgod", "untotalgod"};
		Args = {"player"};
		Description = "Makes the target player(s) mortal again";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1]) do
				local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.MaxHealth = 100
					hum:RemoveTag('ARIDe_GOD')
					hum:RemoveTag('ARIDe_FULLGOD')
					hum.Health = hum.MaxHealth
					local fullGodFF = v.Character:FindFirstChild("ADONIS_FULLGOD")
					if fullGodFF and fullGodFF:IsA("ForceField") then
						fullGodFF:Destroy()
					end
					if Settings.CommandFeedback then
						Functions.Hint("You have been ungodded.", {v}, 15)
					end
				end
			end
		end
	};


	Commands.Place = {
		Prefix = Settings.Prefix;
		Commands = {"place"};
		Args = {"player", "placeID/serverName"};
		NoStudio = true;
		Description = "Teleport the target player(s) to the place belonging to <placeID> or a reserved server";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			local reservedServerInfo = (Core.GetData("PrivateServers") or {})[args[2]]
			local placeId = assert(if reservedServerInfo then reservedServerInfo.ID else tonumber(args[2]), "Invalid place ID or server name (argument #2)")
			local teleportOptions = if reservedServerInfo then service.New("TeleportOptions", {
				ReservedServerAccessCode = reservedServerInfo.Code
			}) else nil
			for _, v in service.GetPlayers(plr, args[1]) do
				task.spawn(function()
					local ans = Remote.GetGui(plr, "YesNoPrompt", { Question = if reservedServerInfo then string.format("Do you want to teleport to server %s.", args[2]) else string.format("Do you want to teleport to place %d.", placeId); })
					if 
						string.lower(ans) == "yes"
					then
						service.TeleportService:TeleportAsync(placeId, {v}, teleportOptions)
					else
						Functions.Hint(`{service.FormatPlayer(v)} declined to teleport`, {plr})
					end
				end)
			end
		end
	};

	Commands.Aliases = {
		Prefix = Settings.PlayerPrefix;
		Commands = {"aliases"};
		Args = {};
		Description = "Opens the alias manager";
		AdminLevel = "Players";
		Function = function(plr: Player, args: {string})
			Remote.MakeGui(plr, "UserPanel", {Tab = "Aliases";})
		end
	};

	Commands.AddAlias = {
		Prefix = Settings.PlayerPrefix;	-- Prefix to use for command
		Commands = {"addalias";"newalias"};	-- Commands
		Args = {"alias", "command(s)"};	-- Command arguments
		Description = "Binds a command or batch of commands to a certain chat message";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr,args)    -- Function to run for command
			assert(args[1] and args[2], "Argument missing or nil")
			for _,cmd in pairs(Admin.SearchCommands(plr,"all")) do
				for _,subcmd in ipairs(cmd.Commands) do
					if args[1]:lower() == cmd.Prefix..subcmd then
						error("Alias has built-in binding")
					end
				end
			end
			local aliases = Core.GetPlayer(plr).Aliases

			assert(aliases[args[1]:lower()] == nil, "Alias already bound to command")
			local command = string.gsub(args[2], "&", Settings.BatchKey)
			local data =  {
				Alias = args[1]:lower(),
				Args = {Names = {}, Defaults = {}},
				Command = command,
				Description = ""
			}
			--  Remote.LoadCode(plr, "client.Functions.AddAlias('"..args[1]:lower().."', '"..command.."')")
			Remote.Send(plr, "Function", "SetAlias", args[1]:lower(), data)
		end
	};

	Commands.RemoveAlias = {
		Prefix = Settings.PlayerPrefix;	-- Prefix to use for command
		Commands = {"removealias";"delalias"};	-- Commands
		Args = {"alias"};	-- Command arguments
		Description = "Unbinds a command or batch of commands from a certain chat message";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr,args)    -- Function to run for command
			assert(args[1], "Argument missing or nil")
			local aliases = Core.GetPlayer(plr).Aliases
			assert(aliases, "Alias not bound to command")
			assert(aliases[args[1]:lower()], "Alias not bound to command")
			Remote.Send(plr, "Function", "RemoveAlias", args[1]:lower())
		end
	};

	Commands.Music = {
		Prefix = server.Settings.Prefix;
		Commands = {"music";"song";"playsong";};
		Args = {"id";"noloop(true/false)";"pitch";"volume"};
		Hidden = false;
		Description = "Start playing a song";
		Fun = false;
		AdminLevel = "Moderators";
		Function = function(plr,args)
			for i, v in pairs(service.Workspace:GetChildren()) do 
				if v:IsA("Sound") and v.Name == "ADONIS_SOUND" then 
					v:Destroy() 
				end 
			end

			local id = args[1]:lower()
			local looped = args[2]
			local pitch = tonumber(args[3]) or 1
			local mp = service.MarketplaceService
			local volume = tonumber(args[4]) or 1
			local name = 'Invalid ID '

			if id ~= "0" and id ~= "off" then
				if looped then
					if looped=="true" then
						looped = false
					else
						looped = true
					end
				else
					looped = true
				end

				for i,v in pairs(server.Variables.MusicList) do 
					if id==v.Name:lower() then 
						id = v.ID
						if v.Pitch then 
							pitch = v.Pitch 
						end 
						if v.Volume then 
							volume=v.Volume 
						end 
					end 
				end

				for i,v in pairs(server.HTTP.Trello.Music) do 
					if id==v.Name:lower() then 
						id = v.ID
						if v.Pitch then 
							pitch = v.Pitch 
						end 
						if v.Volume then 
							volume = v.Volume 
						end 
					end 
				end

				pcall(function() 
					if mp:GetProductInfo(id).AssetTypeId == 3 then 
						name = 'Now playing '..mp:GetProductInfo(id).Name 
					end 
				end)

				local s = service.New("Sound") 
				s.Name = "ADONIS_SOUND"
				s.Parent = service.Workspace
				s.SoundId = "http://www.roblox.com/asset/?id=" .. id 
				s.Volume = volume 
				s.Pitch = pitch 
				s.Looped = looped
				s.Archivable = false
				task.wait(0.5)
				s:Play()
				if server.Settings.SongHint then
					Functions.Hint(name..' ('..id..')',service.Players:GetChildren())
				end
			end
		end
	}
	Commands.StopMusic = {
		Prefix = Settings.Prefix;
		Commands = {"stopmusic";"musicoff";};
		Args = {};
		Hidden = false;
		Description = "Stop the currently playing song";
		Fun = false;
		AdminLevel = "Moderators";
		Function = function(plr,args)
			for i, v in pairs(service.Workspace:GetChildren()) do 
				if v.Name=="ADONIS_SOUND" then 
					v:Destroy() 
				end 
			end
		end
	};
	server.Commands.Stretch = {
		Prefix = server.Settings.Prefix;
		Commands = {"stretch";"height"};
		Arguments = {"player";"optional num"};
		Description = "Modifies a player's height (R15)";
		AdminLevel = "Moderators";
		Function = function(plr, args)
			local num = tonumber(args[2]) or 0.1
			for _,p in ipairs(service.GetPlayers(plr, args[1])) do
				if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
					p.Character.Humanoid.BodyHeightScale.Value = num
				end
			end
		end
	}

	server.Commands.HeadScale = {
		Prefix = server.Settings.Prefix;
		Commands = {"headscale"};
		Arguments = {"player";"optional num"};
		Description = "Modifies a player's head size (R15)";
		AdminLevel = "Moderators";
		Function = function(plr, args)
			local num = tonumber(args[2]) or 0.1
			for _,p in ipairs(service.GetPlayers(plr, args[1])) do
				if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
					p.Character.Humanoid.HeadScale.Value = num
				end
			end
		end
	}

	server.Commands.Flatten = {
		Prefix = server.Settings.Prefix;
		Commands = {"flatten";"2d";"flat";"depth"};
		Args = {"player";"optional num";};
		Hidden = false;
		Description = "Flatten.";
		Fun = true;
		AdminLevel = "Moderators";
		Function = function(plr,args)
			local num = tonumber(args[2]) or 0.1	

			local function sizePlayer(p)
				local char = p.Character
				if char.Humanoid.RigType == Enum.HumanoidRigType.R6 then
					local torso = char:FindFirstChild("Torso")
					local root = char:FindFirstChild("HumanoidRootPart")
					local welds = {}

					torso.Anchored = true
					torso.BottomSurface = 0
					torso.TopSurface = 0

					for i,v in pairs(char:GetChildren()) do
						if v:IsA("BasePart") then
							v.Anchored = true
						end
					end

					local function size(part)
						for i,v in pairs(part:GetChildren()) do
							if (v:IsA("Weld") or v:IsA("Motor") or v:IsA("Motor6D")) and v.Part1 and v.Part1:IsA("Part") then
								local p1 = v.Part1
								local c0 = {v.C0:components()}
								local c1 = {v.C1:components()}

								c0[3] = c0[3]*num
								c1[3] = c1[3]*num

								p1.Anchored = true
								v.Part1 = nil

								v.C0 = CFrame.new(unpack(c0)) 
								v.C1 = CFrame.new(unpack(c1))

								if p1.Name ~= 'Head' and p1.Name ~= 'Torso' then
									p1.formFactor = 3
									p1.Size = Vector3.new(p1.Size.X,p1.Size.Y,num)
								elseif p1.Name ~= 'Torso' then
									p1.Anchored = true
									for k,m in pairs(p1:children()) do 
										if m:IsA('Weld') then 
											m.Part0 = nil 
											m.Part1.Anchored = true 
										end 
									end

									p1.formFactor = 3 
									p1.Size = Vector3.new(p1.Size.X,p1.Size.Y,num)

									for k,m in pairs(p1:children()) do 
										if m:IsA('Weld') then 
											m.Part0 = p1 
											m.Part1.Anchored = false 
										end 
									end
								end

								if v.Parent == torso then 
									p1.BottomSurface = 0 
									p1.TopSurface = 0 
								end

								p1.Anchored = false
								v.Part1 = p1

								if v.Part0 == torso then 
									table.insert(welds,v) 
									p1.Anchored = true 
									v.Part0 = nil 
								end
							elseif v:IsA('CharacterMesh') then
								local bp = tostring(v.BodyPart):match('%w+.%w+.(%w+)')
								local msh = service.New('SpecialMesh')
							elseif v:IsA('SpecialMesh') and v.Parent ~= char.Head then 
								v.Scale = Vector3.new(v.Scale.X,v.Scale.Y,num)
							end 
							size(v)
						end
					end

					size(char)

					torso.formFactor = 3
					torso.Size = Vector3.new(torso.Size.X,torso.Size.Y,num)

					for i,v in pairs(welds) do 
						v.Part0 = torso 
						v.Part1.Anchored = false 
					end

					for i,v in pairs(char:GetChildren()) do 
						if v:IsA('BasePart') then 
							v.Anchored = false 
						end 
					end

					local weld = service.New('Weld',root) 
					weld.Part0 = root 
					weld.Part1 = torso

					local cape = char:findFirstChild("KRONOS_CAPE")
					if cape then
						cape.Size = cape.Size*num
					end
				else
					char.Humanoid.BodyDepthScale.Value = num
				end
			end

			for i,v in pairs(service.GetPlayers(plr,args[1])) do
				sizePlayer(v)
			end
		end
	}


	server.Commands.Resize.Function = function(plr,args)
		if tonumber(args[2])>50 then 
			args[2] = 50 
		end

		local num = tonumber(args[2])	

		local function sizePlayer(p)
			local char = p.Character
			if char.Humanoid.RigType == Enum.HumanoidRigType.R6 then
				local torso = char:FindFirstChild("Torso")
				local root = char:FindFirstChild("HumanoidRootPart")
				local welds = {}

				torso.Anchored = true
				torso.BottomSurface = 0
				torso.TopSurface = 0

				for i,v in pairs(char:GetChildren()) do
					if v:IsA("BasePart") then
						v.Anchored = true
					end
				end

				local function size(part)
					for i,v in pairs(part:GetChildren()) do
						if (v:IsA("Weld") or v:IsA("Motor") or v:IsA("Motor6D")) and v.Part1 and v.Part1:IsA("Part") then
							local p1 = v.Part1
							local c0 = {v.C0:components()}
							local c1 = {v.C1:components()}

							for i = 1,3 do
								c0[i] = c0[i]*num
								c1[i] = c1[i]*num
							end

							p1.Anchored = true
							v.Part1 = nil

							v.C0 = CFrame.new(unpack(c0)) 
							v.C1 = CFrame.new(unpack(c1))

							if p1.Name ~= 'Head' and p1.Name ~= 'Torso' then
								p1.formFactor = 3
								p1.Size = p1.Size*num
							elseif p1.Name ~= 'Torso' then
								p1.Anchored = true
								for k,m in pairs(p1:children()) do 
									if m:IsA('Weld') then 
										m.Part0 = nil 
										m.Part1.Anchored = true 
									end 
								end

								p1.formFactor = 3 
								p1.Size = p1.Size*num

								for k,m in pairs(p1:children()) do 
									if m:IsA('Weld') then 
										m.Part0 = p1 
										m.Part1.Anchored = false 
									end 
								end
							end

							if v.Parent == torso then 
								p1.BottomSurface = 0 
								p1.TopSurface = 0 
							end

							p1.Anchored = false
							v.Part1 = p1

							if v.Part0 == torso then 
								table.insert(welds,v) 
								p1.Anchored = true 
								v.Part0 = nil 
							end
						elseif v:IsA('CharacterMesh') then
							local bp = tostring(v.BodyPart):match('%w+.%w+.(%w+)')
							local msh = service.New('SpecialMesh')
						elseif v:IsA('SpecialMesh') and v.Parent ~= char.Head then 
							v.Scale = v.Scale*num
						end 
						size(v)
					end
				end

				size(char)

				torso.formFactor = 3
				torso.Size = torso.Size*num

				for i,v in pairs(welds) do 
					v.Part0 = torso 
					v.Part1.Anchored = false 
				end

				for i,v in pairs(char:GetChildren()) do 
					if v:IsA('BasePart') then 
						v.Anchored = false 
					end 
				end

				local weld = service.New('Weld',root) 
				weld.Part0 = root 
				weld.Part1 = torso

				local cape = char:findFirstChild("KRONOS_CAPE")
				if cape then
					cape.Size = cape.Size*num
				end
			else
				if char:FindFirstChild("Humanoid") then
					if char.Humanoid:FindFirstChild("BodyDepthScale") then
						char.Humanoid.BodyDepthScale.Value = num
					else
						local scl = service.New("NumberValue", char.Humanoid)
						scl.Name = "BodyDepthScale"
						scl.Value = num
					end
					if char.Humanoid:FindFirstChild("BodyHeightScale") then
						char.Humanoid.BodyHeightScale.Value = num
					else
						local scl = service.New("NumberValue", char.Humanoid)
						scl.Name = "BodyHeightScale"
						scl.Value = num
					end
					if char.Humanoid:FindFirstChild("BodyWidthScale") then
						char.Humanoid.BodyWidthScale.Value = num
					else
						local scl = service.New("NumberValue", char.Humanoid)
						scl.Name = "BodyWidthScale"
						scl.Value = num
					end
					if char.Humanoid:FindFirstChild("HeadScale") then
						char.Humanoid.HeadScale.Value = num
					else
						local scl = service.New("NumberValue", char.Humanoid)
						scl.Name = "HeadScale"
						scl.Value = num
					end
				end
			end
		end

		for i,v in pairs(service.GetPlayers(plr,args[1])) do
			sizePlayer(v)
		end
	end
	
	Commands.Color = {
		Prefix = Settings.Prefix;
		Commands = {"Color"};
		Args = {"Player","color"};
		Description = "too lazy to write one.";
		AdminLevel = "Moderators";
		Function = function(plr,args)
		for i,v in pairs(service.GetPlayers(plr,args[1])) do
			if v.Character then
				for k,p in pairs(v.Character:children()) do
					if p:IsA("BasePart") then
						if args[2] then
							local str = BrickColor.new('Institutional white').Color
							local teststr = args[2]
							if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
							p.BrickColor = str
						end
					end
				end
			end
		end
		end
	};
	

	server.Commands.Material.Function = function(plr,args)
		for i,v in pairs(service.GetPlayers(plr,args[1])) do
			if v.Character then
				for k,p in pairs(v.Character:children()) do
					if p:IsA("Shirt") or p:IsA("Pants") or p:IsA("ShirtGraphic") or p:IsA("CharacterMesh") or p:IsA("Accoutrement") then
						p:Destroy()
					elseif p:IsA("BasePart") then
						p.Material = args[2]
						if args[3] then
							local str = BrickColor.new('Institutional white').Color
							local teststr = args[3]
							if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
							p.BrickColor = str
						end
						if p.Name=="Head" then
							local mesh=p:FindFirstChild("Mesh") 
							if mesh then mesh:Destroy() end
						end
					end
				end
			end
		end
	end

	server.Commands.Neon.Function = function(plr,args)
		server.Commands.Material.Function(plr, {args[1], "Neon"})
		server.Commands.Color.Function(plr, {args[1], args[2]})
	end

end

return function(Vargs)
	local Server = Vargs.Server;
	local Service = Vargs.Service;
	
	-- Modules used
	
	local Variables = Server.Variables;
	local Commands = Server.Commands;
	local Settings = Server.Settings;
	local Functions = Server.Functions;
	
	-- Some vars
	local Prefix = Settings.Prefix;
	
	Commands.MassBring = {
		Prefix = Settings.Prefix;
		Commands = {"massbring", "bringrows", "bringlines"};
		Args = {"player(s)", "lines (default: 3)"};
		Description = "Teleports the target player(s) to you; positioning them evenly in specified lines";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			local plrRootPart = assert(
				assert(plr.Character,"Your character is missing"):FindFirstChild("HumanoidRootPart"),
				"Your HumanoidRootPart is missing"
			)
			local players = Service.GetPlayers(plr, assert(args[1], "Missing target players (argument #1)"))
			local numPlayers = #players
			local lines = math.clamp(tonumber(args[2]) or 3, 1, numPlayers)

			for l = 1, lines do
				local offsetX = if l == 1 then 0
					elseif l % 2 == 1 then -(math.ceil((l - 2) / 2) * 4)
					else math.ceil(l / 2) * 4

				for i = (l-1) * math.floor(numPlayers/lines) + 1, l * math.floor(numPlayers/lines) do
					local char = players[i].Character
					if not char then continue end

					char:SetAttribute("ADONIS_isTeleporting", true)
					task.delay(0.5, function() if char then char:SetAttribute("ADONIS_isTeleporting", nil) end end)

					local hum = char:FindFirstChildOfClass("Humanoid")
					local root = (hum and hum.RootPart or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
						
					local FlightPos = root:FindFirstChild("ADONIS_FLIGHT_POSITION")
					local FlightGyro = root:FindFirstChild("ADONIS_FLIGHT_GYRO")

					if hum then
						if hum.SeatPart then
							Functions.RemoveSeatWelds(hum.SeatPart)
						end
						if hum.Sit then
							hum.Sit = false
							hum.Jump = true
						end
					end
					
					if FlightPos and FlightGyro then
						FlightPos.Position = root.Position
						FlightGyro.CFrame = root.CFrame
					end
					
					task.wait()

					local rootPart = char:FindFirstChild("HumanoidRootPart")
					if rootPart then
						rootPart.CFrame = (
							plrRootPart.CFrame
								* CFrame.Angles(0, math.rad(90), 0)
								* CFrame.new(5 + ((i-1) - (l-1) * math.floor(numPlayers/lines)) * 2, 0, offsetX)
						) * CFrame.Angles(0, math.rad(90), 0)
					end
				end
			end
			if numPlayers%lines ~= 0 then
				for i = lines*math.floor(numPlayers/lines)+1, lines*math.floor(numPlayers/lines) + numPlayers%lines do
					local char = players[i].Character
					if not char then continue end

					char:SetAttribute("ADONIS_isTeleporting", true)
					task.delay(0.5, function() if char then char:SetAttribute("ADONIS_isTeleporting", nil) end end)

					local r = i % (lines*math.floor(numPlayers/lines))
					local offsetX = if r == 1 then 0
						elseif r % 2 == 1 then -(math.ceil((r - 2) / 2) * 4)
						else math.ceil(r / 2) * 4

						--[[if n.Character.Humanoid.Sit then
							n.Character.Humanoid.Sit = false
							wait(0.5)
						end]]

					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Jump = true
					end
					task.wait()

					local rootPart = char:FindFirstChild("HumanoidRootPart")
					if rootPart then
						rootPart.CFrame = (
							plrRootPart.CFrame
								* CFrame.Angles(0, math.rad(90), 0)
								* CFrame.new(5 + (math.floor(numPlayers/lines)) * 2, 0, offsetX)
						) * CFrame.Angles(0, math.rad(90), 0)
					end
				end
			end
		end
	};
	
end;
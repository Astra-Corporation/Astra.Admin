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
	
	local forcefield = {}
	
	local function getModelMass(model)
		local mass = 0
		for _,p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				mass = mass + p:GetMass()
			end
		end
		return mass
	end
	
	Commands.PushField = {
		Prefix = Settings.Prefix;
		Commands = {"pushfield";"pf"};
		Args = {"player";"optional radius"};
		Hidden = false;
		Description = "Sets a forcefield that pushes nearby players away";
		Fun = false;
		AdminLevel = "Moderators";
		Function = function(plr,args)
			for _,player in ipairs(Service.GetPlayers(plr, args[1] or "me")) do
				if player.Character and not forcefield[player.UserId] then
					forcefield[player.UserId] = {}
					forcefield[player.UserId].Radius = tonumber(args[2]) or 15;
					forcefield[player.UserId].DeathConnect = player.Character.Humanoid.Died:Connect(function()
						forcefield[player.UserId].DeathConnect:Disconnect()
						forcefield[player.UserId].Push:Disconnect()
						forcefield[player.UserId] = {}
					end);
					local att0 = Instance.new("Attachment")
					att0.Name = "PushField0"
					att0.Parent = player.Character.HumanoidRootPart
					forcefield[player.UserId].Push = game:GetService("RunService").Stepped:Connect(function()
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							for _,op in ipairs(Service.GetPlayers(plr, "others")) do
								if op.Character and op.Character:FindFirstChild("HumanoidRootPart") then
									if not op.Character.HumanoidRootPart:FindFirstChild("PushField1") then
										local att1 = Instance.new("Attachment")
										att1.Name = "PushField1"
										att1.Parent = op.Character.HumanoidRootPart
									end
									if (op.Character.HumanoidRootPart.Position-player.Character.HumanoidRootPart.Position).magnitude <= forcefield[player.UserId].Radius then
										if not op.Character.HumanoidRootPart:FindFirstChild("KronosPushField") then
											local ff = Instance.new("VectorForce")
											ff.Name = "KronosPushField"
											ff.ApplyAtCenterOfMass = true
											ff.Attachment0 = op.Character.HumanoidRootPart.PushField1
											ff.Attachment1 = att0
											ff.RelativeTo = Enum.ActuatorRelativeTo.World
											ff.Parent = op.Character.HumanoidRootPart
										end
										op.Character.HumanoidRootPart.KronosPushField.Force = ((player.Character.HumanoidRootPart.Position-op.Character.HumanoidRootPart.Position).unit * -1 * getModelMass(op.Character) * 800)
									else
										if op.Character.HumanoidRootPart:FindFirstChild("KronosPushField") then
											op.Character.HumanoidRootPart:FindFirstChild("KronosPushField"):Destroy()
										end
									end
								end
							end
						end
					end)
				elseif forcefield[player.UserId] then
					forcefield[player.UserId].Radius = tonumber(args[2]) or 15
				end
			end
		end
	}
	
end;
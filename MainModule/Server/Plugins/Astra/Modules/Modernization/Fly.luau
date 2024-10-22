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

	Commands.Fly.Function = function(plr: Player, args: {string}, noclip: boolean?)
		local speed = tonumber(args[2]) or 2
		local scr = server.Deps.Assets.Fly:Clone()
		local sVal = service.New("NumberValue", {
			Name = "Speed";
			Value = speed;
			Parent = scr;
		})
		local NoclipVal = service.New("BoolValue", {
			Name = "Noclip";
			Value = noclip or false;
			Parent = scr;
		})

		scr.Name = "ADONIS_FLIGHT"

		for i, v in ipairs(service.GetPlayers(plr, args[1])) do
			local part = v.Character:FindFirstChild("HumanoidRootPart")
			if part then

				local oldp = part:FindFirstChild("ADONIS_FLIGHT_POSITION")
				local oldg = part:FindFirstChild("ADONIS_FLIGHT_GYRO")
				local olds = part:FindFirstChild("ADONIS_FLIGHT")
				if oldp then oldp:Destroy() end
				if oldg then oldg:Destroy() end
				if olds then olds:Destroy() end

				local new = scr:Clone()
				local flightPosition = service.New("BodyPosition")
				local flightGyro = service.New("BodyGyro")

				flightPosition.Name = "ADONIS_FLIGHT_POSITION"
				flightPosition.MaxForce = Vector3.new(0, 0, 0)
				flightPosition.Position = part.Position
				flightPosition.Parent = part

				flightGyro.Name = "ADONIS_FLIGHT_GYRO"
				flightGyro.MaxTorque = Vector3.new(0, 0, 0)
				flightGyro.CFrame = part.CFrame
				flightGyro.Parent = part

				new.Parent = part
				new.Disabled = false
				v.Character.Humanoid:AddTag('ARIDe_FLIGHT')
				Remote.MakeGui(v, "Hint", {
					Title = "Flight";
					Message = "You now have flight - press E to toggle flight";
					Time = 10;
				})
			end
		end
	end
	
	Commands.UnFly = {
		Prefix = Settings.Prefix;
		Commands = {"unfly", "ground"};
		Args = {"player"};
		Description = "Removes the target player(s)'s ability to fly";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1]) do
				local part = v.Character:FindFirstChild("HumanoidRootPart")
				if part then
					local oldp = part:FindFirstChild("ADONIS_FLIGHT_POSITION")
					local oldpa = part:FindFirstChild("ADONIS_FLIGHT_POSITION_ATTACHMENT")
					local oldg = part:FindFirstChild("ADONIS_FLIGHT_GYRO")
					local oldga = part:FindFirstChild("ADONIS_FLIGHT_GYRO_ATTACHMENT")
					local olds = part:FindFirstChild("ADONIS_FLIGHT")
					if oldp then oldp:Destroy() end
					if oldpa then oldpa:Destroy() end
					if oldg then oldg:Destroy() end
					if oldga then oldga:Destroy() end
					if olds then olds:Destroy() end
					v.Character.Humanoid:RemoveTag('ARIDe_FLIGHT')
				end
			end
		end
	};

end;

return function(Vargs)
	local Server = Vargs.Server;
	local Service = Vargs.Service;

	-- Modules used
	local Variables = Server.Variables;
	local Commands = Server.Commands;
	local Admin = Server.Admin;
	local Core = Server.Core;
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
	local OldDonor = Functions.Donor
	local OldNewParticle = Functions.NewParticle

	Variables.DonorDisabledInServer = false
	
	if type(Settings.BlacklistedCape) ~= "table" then
		Settings.BlacklistedCape = {}
	end
	
	local function CheckIdInTable(Table, Id)
		for _, id in ipairs(Table) do
			
			if string.find(Id, "%f[%d]" .. id .. "%f[%D]") then
				return true, id
			end
		end
	end

	Commands.ToggleDonor = {
		Prefix = Settings.Prefix;
		Commands = {"enabledonor","disabledonor","toggledonor"};
		Args = {"toggle"};
		Description = "Toggle the use of donor effects";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string}, data: {})
			local Enabled = Variables.DonorDisabledInServer
			Variables.DonorDisabledInServer = not Enabled

			Functions.Hint(`{(Enabled) and "Enabled" or "Disabled"} donor commands`,{plr},2)

			if not Enabled then
				local DoWeClear = Remote.GetGui(plr, "YesNoPrompt", {
					Question = "Clear all donor effects?";
				}) == "Yes"

				if DoWeClear then
					Commands.ClearDonorEffects.Function(plr)
				end
			end
		end
	};

	Commands.ClearDonorEffects = {
		Prefix = Settings.Prefix;
		Commands = {"cleardonoreffects"};
		Args = {};
		Description = "Clears everyones donor effects";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string}, data: {})
			for _, Player in pairs(Service.GetPlayers()) do
				local Root = Player.Character:FindFirstChild("HumanoidRootPart")

				Functions.UnCape(Player)

				if Root then
					Functions.RemoveParticle(Root, "DONOR_LIGHT")
					Functions.RemoveParticle(Root, "DONOR_SPARKLES")
					Functions.RemoveParticle(Root, "DONOR_SPARKLES_LIGHT")
					Functions.RemoveParticle(Root, "DONOR_FIRE_LIGHT")
					Functions.RemoveParticle(Root, "DONOR_FIRE")
				end
			end

			Functions.Hint("All donor effects were cleared",{plr},2)
		end
	};

	Functions.Donor = function(plr)
		if Admin.CheckDonor(plr) and Settings.DonorCapes and not Variables.DonorDisabledInServer then
			local PlayerData = Core.GetPlayer(plr) or {Donor = {}}
			local donor = PlayerData.Donor or {}
			if donor then
				if donor.Cape and donor.Cape.Image then
					if not donor.Cape.Image then end

					local Image = tostring(donor.Cape.Image)
					if table.find(Settings.BlacklistedCapes, Image) then
						donor.Cape.Image = 4181463301			
					end
				end
			end
			if donor and donor.Enabled then
				local img,color,material
				if donor and donor.Cape then
					img,color,material = donor.Cape.Image,donor.Cape.Color,donor.Cape.Material
				else
					img,color,material = '0','White','Neon'
				end
				if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					Functions.Cape(plr,true,material,color,img)
				end
			end
		end
	end;

	Functions.NewParticle = function(target, particleType, props)
		local Name = props.Name
		local IsDonor = Name and string.find(Name, "DONOR")
		if props and type(props) == "table" then
			if props.Texture then
				if CheckIdInTable(Settings.BlacklistedCapes, props.Texture) then
					props.Texture = string.gsub(props.Texture, "id=%d+", "id=4181463301")
					--Image = 4181463301

				end
			end
		end

		if IsDonor and Variables.DonorDisabledInServer then
			return
		end

		return OldNewParticle(target, particleType, props)
	end

	Remote.Returnables.UpdateDonor = function(p: Player, args: {[number]: any})
		local playerData = Core.GetPlayer(p)
		local resp = "OK"

		if Settings.DonorCapes and playerData.isDonor then
			local donor = args[1]
			if type(donor) == "table" and donor.Cape and type(donor.Cape) == "table" then
				playerData.Donor = donor

				if donor.Cape then
					if not donor.Cape.Image then end 
					local Image = tostring(donor.Cape.Image)
					if CheckIdInTable(Settings.BlacklistedCapes, Image) then
						resp = "Cape is blacklisted"
						return resp
						--Image = 4181463301

					end
				end

				if donor.Enabled then
					Functions.Donor(p)
				else
					Functions.UnCape(p)
				end

				Core.SavePlayer(p, playerData)
				resp = "Updated"
			else
				resp = "Error"
			end
		else
			resp = "Error"
		end

		return resp
	end;

	do 
		for _, Command in {
			Commands.DonorLight,
			Commands.DonorCape,
			Commands.DonorNeon,
			Commands.DonorFire,
			Commands.DonorSparkles,
			Commands.DonorParticle,
			Commands.DonorAvatarItem,
			} 
		do 
			local RealFunction = Command.Function
			Command.Function = function(Player: Player, ...)
				if Variables.DonorDisabledInServer then
					return Remote.MakeGui(Player, "Output", {
						Message = "Donor commands are disabled in this server"
					})
				end

				task.spawn(RealFunction, Player, ...)
			end


		end
	end

	Remote.Commands.GetCapeTextureId = function(p, args)
		if CheckIdInTable(Settings.BlacklistedCapes, args[1]) then
			return 4181463301
		end
		
		return args[1]
	end;

	Admin.CacheCommands()
end;
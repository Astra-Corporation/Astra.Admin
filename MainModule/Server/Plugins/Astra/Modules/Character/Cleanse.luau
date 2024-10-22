-- Hi 8ch here to do stuff

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
	
	--[==[
		Hayo!
		
		This module is public for use on Adonis admins.
		Simply plop it into the "Plugins Folder" 
		
		Rename it "Server: Cleanse" if you're adding it in the Loader -> Config -> Plugins
		Leave it named as whatever you want if you put it in the MainModule -> Server -> Plugins
		
		Please note, this may not cover all accessories of this type!
		All you need to do to add more accessories to the system is adding to the list server.Variables.BlacklistedHats with names of those hats 
		
		Cheers!
		Coaster
	]==]
	
	-- 
	Variables.CleanseEvents = {}
	
	Variables.HatExceptions = {
		-- Any exceptions
		-- (The blacklist is a match-based system)
	}
	
	-- Names of hats not allowed
	Variables.BlacklistedHats = {
		"SPMLMR";
		"MLMTiedArmband";
		"BiTiedArmband";
		"Anime Face";
		"TransTiedArmband";
		-- Names of hats you want to blacklist
	}
	
	-- Some hats have non-specific names, these require mesh id comparisons
	Variables.BlacklistedMeshes = {
		"rbxassetid://13932937384";
		"rbxassetid://14434840500";
		"rbxassetid://13618738353";
		"rbxassetid://12850325083";
		-- Any meshes
	}
	
	Commands.Cleanse = {
		Prefix = Prefix;	-- Prefix to use for command
		Commands = {"cleanse"};	-- Commands
		Args = {"on/off"};	-- Command arguments
		Description = "Cleanse the server.";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Moderators";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr, args) 
			local State = Functions.Trim(string.lower(assert(args[1], "Argument 1 is required!")));
			local IsCleansing = Variables.Cleanse;
			
			if State == 'on' then
				IsCleansing = true;
			elseif State == 'off' then
				IsCleansing = false;
			end;
			
			Variables.Cleanse = IsCleansing;
			
			local Players = Service.GetPlayers();
			
			if Variables.Cleanse then
				Functions.Cleanse(Players);
				Functions.Hint("Server has been cleansed", Players);
			end
			
			if not IsCleansing then
				local CleanseEvents = Variables.CleanseEvents;
				
				for _, Event in CleanseEvents do
					-- Adonis specific pcall; errors logged to :errorlogs
					pcall(task.defer, function()
						local Name = Event.Name;
						
						Event[Name]:Disconnect();
						Event[Name] = nil;
					end);
				end;
				
				Functions.Hint("Server cleanse has been lifted", Players);
			end;
		end;
	}	
	
	--[==[
		Functions
			.IsExceptionHat
		
		Arguments; 
			Accessory
				The hat to check
			
		Returns true if a hat is an exception, false if not 
	]==]
	
	Functions.IsExceptionHat = function(accessory) 
		local LowerAccesoryName = string.lower(accessory.Name);
		
		for _, Exception in Variables.HatExceptions do
			if string.match(LowerAccesoryName, string.lower(Exception)) then
				return true;
			end;
		end;
		
		return false
	end;
	
	--[==[
		Functions
			.CheckHat
		
		Arguments; 
			Accessory
				The hat to check
			
		Destroys a hat if it's considered bad
	]==]
	
	Functions.CheckHat = function(accessory) 
		local IsBad = false;
		local LowerAccesoryName = string.lower(accessory.Name);
		local IsExempt = Functions.IsExceptionHat(accessory)
		
		if not IsExempt then
			for _, Hat in Variables.BlacklistedHats do
				if string.match(LowerAccesoryName, string.lower(Hat)) then
					IsBad = true;
					break;
				end;
			end;
		end;
		
		-- If hat is still good, look at the meshes if any are there; recursive search
		if not IsBad then
			local specialMesh = accessory:FindFirstChildWhichIsA("SpecialMesh", true) or accessory:FindFirstChildWhichIsA("BlockMesh", true);
			-- Loop through these bad boys, comparing MeshIds 
			
			if specialMesh then
				for _, ID in Variables.BlacklistedMeshes do
					if specialMesh.MeshId == ID then
						IsBad = true;
						break;
					end;
				end;
			end;
		end;
		
		-- Finally, if the hat is bad, it will be destroyed
		-- Glory to the Cleansing
		
		if IsBad then
			-- In case replication does it's usual annoying behavior, this just loops to make sure it's not re-parented
			-- :Destroy() *should* make it not be ABLE to reparent, but it's just a failsafe at this point
			
			pcall(function()
				repeat
					accessory:Destroy();
					task.wait();
				until not accessory or accessory.Parent == nil;
			end);
		end;
	end;
	
	--[==[
		Functions
			.Cleanse
		
		Arguments; 
			Players
				Table of Player Objects
			
		Cleanses a character
	]==]
	
	Functions.Cleanse = function(Players)
		local CleanseEvents = Variables.CleanseEvents;
		
		for _, Player in Players do
			local PlayerName = Player.Name;
			
			task.defer(function()
				local Character = Player.Character or Player.CharacterAdded:Wait();
				
				for _, Child in Character:GetChildren() do
					if Child:IsA("Accessory") then
						Functions.CheckHat(Child);
					end;
				end;
				
				local Event = CleanseEvents[PlayerName];

				if Event then
					Event:Disconnect();
				end;
				
				CleanseEvents[PlayerName] = Character.ChildAdded:Connect(function(Child)
					if not Variables.Cleanse then
						return;
					end;
					
					if Child:IsA("Accessory") then
						Functions.CheckHat(Child);
					end;
				end);
			end);
		end;
	end;
	
	-- This is for each spawn, and any event they get a new hat
	-- This will run on a players CharacterAddition 
	Service.HookEvent("CharacterAdded", function(Player)
		-- Make sure their character has loaded; if not wait until it does
		if not Player:HasAppearanceLoaded() then
			Player.CharacterAppearanceLoaded:Wait();
		end;
		-- Cleanse their character then move on
		if Variables.Cleanse then
			Functions.Cleanse({ Player });
		end;
	end);
	
	-- Clear a user from the Event Cache on leave 
	Service.HookEvent("PlayerRemoving", function(Player)
		local CleanseEvents = Variables.CleanseEvents;
		local PlayerName = Player.Name;
		local Event = CleanseEvents[PlayerName];
		
		if Event then
			pcall(Event.Disconnect, Event);
			CleanseEvents[PlayerName] = nil;
		end;
	end);
end;
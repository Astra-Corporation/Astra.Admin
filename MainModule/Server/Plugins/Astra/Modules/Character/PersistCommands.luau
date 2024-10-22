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


	Variables.PersistData = {}

	local PersistData = Variables.PersistData
	-- // so other plugins can interact with the data, not used for anything RN but may be used later



	--// This is really dumb! Waste of memory!
	
	--Service.HookEvent("PlayerAdded",function(a) -- If persist data doesn't exist when someone joins, create data for them
	--	if not PersistData[a.Name] then
	--		PersistData[a.Name] = {false,false}
	--	end
	--end)

	Service.HookEvent("CharacterAdded",function(a) -- // The event that happens when a character is spawned
		if not PersistData[a.Name] then
			return
		end
		
		if PersistData[a.Name][2] then
			Commands.God.Function(a,{"me"})    --Give god if persisted
		end
		if PersistData[a.Name][1] then
			Commands.Fly.Function(a,{"me"},true) --Give fly if persisted, the bool value at the end is whether to use noclip while flying (hint you almost 100% want this with :fly)
		end
	end)


	Server.Commands.PersistFly = {
		Prefix = Server.Settings.Prefix;    
		Commands = {"persistfly";"pfly"};    
		Args = {"player"};
		Description = "Gives the specified people persistant fly, gives fly back on respawn";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators";        
		Function = function(plr,args)   
			for i,v in pairs(Service.GetPlayers(plr,args[1])) do
				
				if not PersistData[v.Name] then
					PersistData[v.Name] = {false,false}
				end
				
				PersistData[v.Name][1] = true
				Functions.Hint("You will now persist fly on death",{v})
			end
		end
	};
	Server.Commands.unPersistFly = {
		Prefix = Server.Settings.Prefix;    
		Commands = {"unpersistfly";"unpfly"};
		Args = {"player"};
		Description = "Removes persistant fly of pepole";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators";        
		Function = function(plr,args)   
			for i,v in pairs(Service.GetPlayers(plr,args[1])) do
				if not PersistData[v.Name] then
					PersistData[v.Name] = {false,false}
				end
				
				PersistData[v.Name][1] = false
				Functions.Hint("You will no longer persist fly on death",{v})
			end
		end
	};
	Server.Commands.PersistGod = {
		Prefix = Server.Settings.Prefix;    
		Commands = {"persistgod";"pgod"};    
		Args = {"player"};
		Description = "Gives the specified people persistant god, gives god back on respawn";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators";        
		Function = function(plr,args) 
			for i,v in pairs(Service.GetPlayers(plr,args[1])) do
				if not PersistData[v.Name] then
					PersistData[v.Name] = {false,false}
				end
				PersistData[v.Name][2] = true
				Functions.Hint("You will now persist god on death",{v})
			end
		end
	};
	Server.Commands.unPersistGod = {
		Prefix = Server.Settings.Prefix;    
		Commands = {"unpersistgod";"unpgod"};    
		Args = {"player"};
		Description = "Removes persistant god of pepole";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators";        
		Function = function(plr,args)   
			for i,v in pairs(Service.GetPlayers(plr,args[1])) do
				if not PersistData[v.Name] then
					PersistData[v.Name] = {false,false}
				end
				PersistData[v.Name][2] = false
				Functions.Hint("You will no longer persist god on death",{v})
			end
		end
	};
end
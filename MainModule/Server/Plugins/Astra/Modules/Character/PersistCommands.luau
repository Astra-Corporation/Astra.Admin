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

	Service.HookEvent("CharacterAdded",function(Player: Player) 		
		if Player:GetAttribute("ASTRA_PersistGod") then
			Commands.God.Function(Player,{"me"})
		end

		if Player:GetAttribute("ASTRA_PersistFly") then
			Commands.Fly.Function(Player,{"me"},true)
		end
	end)

	Commands.PersistFly = {
		Prefix = Server.Settings.Prefix;    
		Commands = {"persistfly";"pfly"};    
		Args = {"player"};
		Description = "Gives the specified people persistant fly, gives fly back on respawn";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators";        
		Function = function(plr,args)   
			for i,Player :Player in pairs(Service.GetPlayers(plr,args[1])) do

				Player:SetAttribute("ASTRA_PersistFly",true)
				Functions.Hint("You will now persist fly on next spawn",{Player})
			end
		end
	};

	Commands.unPersistFly = {
		Prefix = Server.Settings.Prefix;    
		Commands = {"unpersistfly";"unpfly"};
		Args = {"player"};
		Description = "Removes persistant fly of pepole";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators";        
		Function = function(plr,args)   
			for i,Player :Player in pairs(Service.GetPlayers(plr,args[1])) do

				Player:SetAttribute("ASTRA_PersistFly",nil)
				Functions.Hint("You will no longer persist fly on next spawn",{Player})
			end
		end
	};

	Commands.PersistGod = {
		Prefix = Server.Settings.Prefix;    
		Commands = {"persistgod";"pgod"};    
		Args = {"player"};
		Description = "Gives the specified people persistant god, gives god back on respawn";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators";        
		Function = function(plr,args) 
			for i,Player :Player in pairs(Service.GetPlayers(plr,args[1])) do

				Player:SetAttribute("ASTRA_PersistGod",true)
				Functions.Hint("You will now persist god on next spawn",{Player})
			end
		end
	};

	Commands.unPersistGod = {
		Prefix = Server.Settings.Prefix;    
		Commands = {"unpersistgod";"unpgod"};    
		Args = {"player"};
		Description = "Removes persistant god of pepole";
		Hidden = false;
		Fun = false;
		AdminLevel = "Moderators";        
		Function = function(plr,args)   
			for i,Player :Player in pairs(Service.GetPlayers(plr,args[1])) do

				Player:SetAttribute("ASTRA_PersistGod",nil)
				Functions.Hint("You will no longer persist god on next spawn",{Player})
			end
		end
	};
end
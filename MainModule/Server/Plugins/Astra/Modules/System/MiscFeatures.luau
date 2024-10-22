return function(Vargs)
	local Server = Vargs.Server;
	local Service = Vargs.Service;
	local Shared = Server.Shared;
	-- Modules used
	
	local Variables = Server.Variables;
	local Commands = Server.Commands;
	local Settings = Server.Settings;
	local Functions = Server.Functions;
	
	-- Some vars
	local Prefix = Settings.Prefix;
	
	-- Moving some things here from Server. 
	-- Mostly things that don't need to be done on the first run 
	
	do
		local MaterialIcons = require(Shared.MatIcons)
		Server.MatIcons = setmetatable({}, {
			__index = function(self, ind)
				local materialIcon = MaterialIcons[ind]
				if materialIcon then
					self[ind] = `rbxassetid://{materialIcon}`
					return self[ind]
				end
				return ""
			end,
			__metatable = "ARIDe_MatIcons"
		})
	end
	
	--// Require some dependencies
	Server.Changelog = require(Shared.Changelog)
	Server.Credits = require(Shared.Credits)


	
end;
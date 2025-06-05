return function(Vargs)
	local Server = Vargs.Server;

	local Variables = Server.Variables;
	local Commands = Server.Commands;

	local Settings = Server.Settings;
	local Functions = Server.Functions;

	Variables.OptedOutOfAdmin = {};

	Commands.ToggleAdmin = {
		Prefix = Settings.Prefix;
		Commands = {"toggleadmin";"adminstatus"};
		Args = {};
		Description = "Opt in or out of appearing as an admin";
		AdminLevel = "Moderators";
		Function = function(Player: Player, args: {string}, data: {})
			local State = table.find(Variables.OptedOutOfAdmin,Player)

			if State then
				table.remove(Variables.OptedOutOfAdmin, State)
			else 
				table.insert(Variables.OptedOutOfAdmin, Player)
			end

			Functions.Hint(`You will {(State) and "now appear" or "no longer appear"} as an admin.`,{Player},2)
		end
	};

end;
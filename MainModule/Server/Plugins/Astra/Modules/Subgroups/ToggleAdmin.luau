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
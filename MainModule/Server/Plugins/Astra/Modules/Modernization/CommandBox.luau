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
	local version = server.Version

	server.Commands.CommandBox = {
		Prefix = Settings.Prefix;
		Commands = {"cmdbox", "commandbox"};
		Args = {};
		Description = "Command Box";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			Remote.MakeGui(plr, "CommandBox")
		end;
	};
	
end;

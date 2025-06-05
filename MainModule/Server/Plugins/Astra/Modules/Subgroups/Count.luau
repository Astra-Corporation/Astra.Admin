return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local Settings = server.Settings;
	local Commands = server.Commands;
	local Remote = server.Remote;

	Commands.SelectPlayers = {
		Prefix = Settings.Prefix;
		Commands = {"select", "selectplayers", "count",  "countplayers", "getplayers"};
		Args = {"player(s)", "autoupdate? (default: false)"};
		Description = `Shows you a list and count of players selected in the supplied argument, ex: '{Settings.Prefix}select %raiders true' to monitor people in the 'raiders' team`;
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {[number]:string})
			local selection = args[1];
			local players = service.GetPlayers(plr, selection)
			local DownloadData = {}
			local tab = {
				{
					Text = `Specified: "{selection or `{Settings.SpecialPrefix}me`}"`;
				},
				{
					Text = `# Players: {#players or 0}`;
				},
				{
					Text = `―――――――――――――――――――――――`;
				}
			}

			for _, v: Player in players do
				table.insert(tab, {
					Text = `[{v.UserId}] {service.FormatPlayer(v)}`;
				})
				table.insert(DownloadData,v.Name)
			end

			Remote.MakeGui(plr, "List", {
				Title = "Count";
				--Icon = server.MatIcons.People;
				Tab = tab;
				DownloadData = DownloadData;
				TextSelectable = true;
				--Update = "SelectPlayers";
				--UpdateArg = args[1];
				AutoUpdate = false-- if args[2] and (args[2]:lower() == "true" or args[2]:lower() == "yes") then 1 else nil;
			})
		end
	};
	
	--Commands.CountDownload = {
	--	Prefix = Settings.Prefix;
	--	Commands = {"countdownload"};
	--	Args = {"player(s)"};
	--	Description = `Shows you a list and count of players selected in the supplied argument, ex: '{Settings.Prefix}select %raiders true' to monitor people in the 'raiders' team`;
	--	AdminLevel = "Moderators";
	--	RequiredGroupRank = 1;
	--	RequiredGroupId = 32365861;
	--	Function = function(plr: Player, args: {[number]:string})
	--		local players = service.GetPlayers(plr,args[1], {DontError = true; NoFakePlayer = true;})
	--		local tab = {}
	--		for _, v: Player in players do
	--			table.insert(tab, v.Name)
	--		end

	--		Remote.MakeGui(plr,"Text",{Text=table.concat(tab, ", ")})
			
	--	end
	--};
	
end
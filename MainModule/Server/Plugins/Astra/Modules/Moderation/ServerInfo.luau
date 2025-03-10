--!nonstrict
local cooldowndata = {}
--TODO: Remove useless stuff and a seperte UI only for location
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
	local Permission = server.Permission;
	local HTTP = server.HTTP;
	local Anti = server.Anti;
	
	Variables.ServerInfo = {}
	
	local _, ServerInfo = xpcall(function()
		local res = service.HttpService:JSONDecode(service.HttpService:GetAsync("https://speed.cloudflare.com/meta"))
		return {
			country = res.country or "N/A",
			city = res.city or "N/A",
			region = res.region or "N/A",
			zipcode = "";
			timezone = res.timezone or "N/A", -- not supported by cloudflare!
			query = "";
			coords = "";
		}
	end, function() return end)
	
	Variables.ServerInfo = ServerInfo
	
	Commands.ServerDetails = {
		Prefix = Settings.Prefix;
		Commands = {"refreshserverlocation"};
		Args = {};
		Description = "Refresh server location";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			local _, ServerInfo = xpcall(function()
				local res = service.HttpService:JSONDecode(service.HttpService:GetAsync("https://speed.cloudflare.com/meta"))
				return {
                    country = res.country or "N/A",
                    city = res.city or "N/A",
                    region = res.region or "N/A",
                    zipcode = "";
                    timezone = res.timezone or "N/A", -- not supported by cloudflare!
                    query = "";
                    coords = "";
				}
			end, function() return end)

			Variables.ServerInfo = ServerInfo
		end
	};
	
	Commands.ServerDetails = {
		Prefix = Settings.PlayerPrefix;
		Commands = {"serverinfo", "server", "serverdetails", "gameinfo", "gamedetails"};
		Args = {};
		Description = "Shows you details about the current server";
		AdminLevel = "Players";
		ListUpdater = function(plr: Player)
			local elevated = Admin.CheckAdmin(plr)
			local data = {}

			local donorList = {}
			for _, v in service.GetPlayers() do
				if not Variables.IncognitoPlayers[v] and Admin.CheckDonor(v) then
					table.insert(donorList, v.Name)
				end
			end

			local adminDictionary, workspaceInfo
			if elevated then
				adminDictionary = {}
				for _, v in service.GetPlayers() do
					local level, rank = Admin.GetLevel(v)
					if level > 0 then
						adminDictionary[v.Name] = rank or "Unknown"
					end
				end
				local nilPlayers = 0
				for _, v in service.NetworkServer:GetChildren() do
					if v and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
						nilPlayers += 1
					end
				end
				workspaceInfo = {
					ObjectCount = #Variables.Objects;
					CameraCount = #Variables.Cameras;
					NilPlayerCount = nilPlayers;
					HttpEnabled = false; -- TODO: Get rid of dumb things like this!
					LoadstringEnabled = false;
				}
			end

			return {Admins = adminDictionary; Donors = donorList; WorkspaceInfo = workspaceInfo;}
		end;
		Function = function(plr: Player, args: {string})
			local elevated = Admin.CheckAdmin(plr)



			Remote.MakeGui(plr, "ServerDetails", {
				CreatorId = game.CreatorId;
				PrivateServerId = game.PrivateServerId;
				PrivateServerOwnerId = game.PrivateServerOwnerId;
				ServerStartTime = server.ServerStartTime;
				ServerAge = service.FormatTime(os.time() - server.ServerStartTime);
				ServerInternetInfo = Variables.ServerInfo;
				Refreshables = Logs.ListUpdaters.ServerDetails(plr);
				CmdPrefix = Settings.Prefix;
				CmdPlayerPrefix = Settings.PlayerPrefix;
				SplitKey = Settings.SplitKey;
			})
		end
	};
end;
return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local Functions = server.Functions;
	local MarketplaceService = service.MarketplaceService
	local BadgeService = service.BadgeService

	Functions.PlayerFinders["stat"] = {
		Match = "stat/";
		Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
			local stat, rmi, rma = msg:match("stat/(%w+)/?(%-?%d*)/?(%-?%d*)")
			local min, max = tonumber(rmi), tonumber(rma)
			if stat then
				for i,v in next,parent:children() do
					local p = getplr(v)
					if p:FindFirstChild("leaderstats") then
						for _,val in pairs(p:FindFirstChild("leaderstats"):GetChildren()) do
							if val.Name:lower():sub(1, #stat) == stat:lower() then
								if val and not min and not max then
									table.insert(players,p)
									plus()
								elseif val.Value >= min and not max then
									table.insert(players,p)
									plus()
								elseif val.Value >= min and val.Value <= max then
									table.insert(players,p)
									plus()
								end
							end
						end
					end
				end
			end
		end;
	};

	Functions.PlayerFinders["hastools"] = {
		Match = "!hastools";
		Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
			for i,v in next,parent:children() do
				local p = getplr(v)
				if p:FindFirstChild("Backpack") then
					if p.Backpack:FindFirstChildOfClass("Tool") or p.Backpack:FindFirstChildOfClass("Hopperbin") then
						plus()
						table.insert(players,p)
					end
				end
			end
		end;
	};

	Functions.PlayerFinders["badge"] = {
		Match = "badge/";
		Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
			local bid = msg:match("badge/(%d+)")
			local badgeid = tonumber(bid)
			for i,v in next,parent:children() do
				local p = getplr(v)
				if BadgeService:UserHasBadgeAsync(p.UserId, badgeid) then
					table.insert(players,p)
					plus()
				end
			end
		end;
	};

	Functions.PlayerFinders["gamepass"] = {
		Match = "gamepass/";
		Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
			local gid = msg:match("gamepass/(%d+)")
			local gpid = tonumber(gid)
			for i,v in next,parent:children() do
				local p = getplr(v)
				if MarketplaceService:UserOwnsGamePassAsync(p.UserId, gpid) then
					table.insert(players,p)
					plus()
				end
			end
		end;
	};

	Functions.PlayerFinders["asset"] = {
		Match = "asset/";
		Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
			local aid = msg:match("asset/(%d+)")
			local assetid = tonumber(aid)
			for i,v in next,parent:children() do
				local p = getplr(v)
				if MarketplaceService:PlayerOwnsAsset(p.UserId, assetid) then
					table.insert(players,p)
					plus()
				end
			end
		end;
	};

	Functions.PlayerFinders["accountage"] = {
		Match = "accountage/";
		Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
			local rmi, rma = msg:match("accountage/(%d+)/(%d+)")
			local min, max = tonumber(rmi), tonumber(rma)
			for i,v in next,parent:children() do
				local p = getplr(v)
				if min and not max and p.AccountAge >= min then
					table.insert(players,p)
					plus()
				elseif min and max and p.AccountAge >= min and p.AccountAge <= max then
					table.insert(players,p)
					plus()
				end
			end
		end;
	};

end
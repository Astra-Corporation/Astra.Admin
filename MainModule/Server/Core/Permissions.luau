return function(Vargs, GetEnv)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Permissions, GroupService
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;
		Permissions = server.Permissions;
		GroupService = server.GroupService;
		Permissions.Init = nil;
		Logs:AddLog("Script", "Permissions Module Initialized")
	end;

	server.Permissions = {
		Init = Init;

		CheckPermission = function(pDat, cmd, ignoreCooldown, opts)
			opts = opts or {}

			local adminLevel = pDat.Level
			local comLevel = cmd.AdminLevel
			local Player = pDat.Player
			local CustomCheck = cmd.CustomPermissionCheck or cmd.CustomCheck

			if cmd.Disabled then
				return false, "This command has been disabled."
			end

			if Variables.IsStudio and cmd.NoStudio then
				return false, "This command cannot be used in Roblox Studio."
			end

			if opts.CrossServer and cmd.CrossServerDenied then -- Ignore when disabled then
				return false, "This command may not be run across servers (cross-server-blacklisted)."
			end

			if cmd.CrossServer and not Settings.CrossServerCommands then
				return false, "This command has been disabled due to CrossServerCommands being disabled"
			end

			if Admin.IsPlaceOwner(pDat.Player) or adminLevel >= Settings.Ranks.Creators.Level then
				return true, nil
			end

			if Admin.IsBlacklisted(pDat.Player) then
				return false, "You are blacklisted from running commands."
			end

			if (comLevel == 0 or comLevel == "Players") and adminLevel <= 0 and not Settings.PlayerCommands then
				return false, "Player commands are disabled in this game."
			end

			if cmd.Fun and not Settings.FunCommands then
				return false, "Fun commands are disabled in this game."
			end

			if opts.Chat and cmd.Chattable == false then
				return false, "This command is not permitted as chat message (non-chattable command)."
			end

			if Variables.DonorDisabledInServer and cmd.Donors then
				return false, "Donor commands are disabled in this server!"
			end

			if cmd.RequiredGroupId and cmd.RequiredGroupRank then
				local RequiredGroupId = cmd.RequiredGroupId;
				local isInGroup = GroupService:IsPlayerInGroup(pDat.Player, RequiredGroupId) or false
				local rankInGroup = GroupService:GetPlayerRankInGroup(pDat.Player, RequiredGroupId) or 0

				return isInGroup and (rankInGroup >= cmd.RequiredGroupRank)
			end

			local permAllowed = (cmd.Donors and (pDat.isDonor and (Settings.DonorCommands or cmd.AllowDonors)))
				or Admin.CheckComLevel(adminLevel, comLevel)

			if CustomCheck and type(CustomCheck) == 'function' then
				local success, result = pcall(function() return CustomCheck(Player, pDat) end)
				if success and type(result) == 'boolean' then
					if result == true then
						permAllowed = true
					end
				end
			end

			if permAllowed and not ignoreCooldown and type(pDat.Player) == "userdata" then
				local playerCooldown = tonumber(cmd.PlayerCooldown)
				local serverCooldown = tonumber(cmd.ServerCooldown)
				local crossCooldown = tonumber(cmd.CrossCooldown)

				local cmdFullName = cmd._fullName or (function()
					local aliases = cmd.Aliases or cmd.Commands or {}
					cmd._fullName = `{cmd.Prefix}{aliases[1] or `{service.HttpService:GenerateGUID(false)}-RANDOM_COMMAND`}`
					return cmd._fullName
				end)()

				local pCooldown_Cache = cmd._playerCooldownCache or (function()
					local tab = {}
					cmd._playerCooldownCache = tab
					return tab
				end)()

				local sCooldown_Cache = cmd._serverCooldownCache or (function()
					local tab = {}
					cmd._serverCooldownCache = tab
					return tab
				end)()

				local crossCooldown_Cache = cmd._crossCooldownCache or (function()
					local tab = {}
					cmd._crossCooldownCache = tab
					return tab
				end)()

				local cooldownIndex = tostring(pDat.Player.UserId)
				local pCooldown_playerCache = pCooldown_Cache[cooldownIndex]
				local sCooldown_playerCache = sCooldown_Cache[cooldownIndex]

				if playerCooldown and pCooldown_playerCache then
					local secsTillPass = os.clock() - pCooldown_playerCache
					if secsTillPass < playerCooldown then
						return false, string.format("[PlayerCooldown] You must wait %.0f seconds to run the command.", playerCooldown - secsTillPass)
					end
				end

				if serverCooldown and sCooldown_playerCache then
					local secsTillPass = os.clock() - sCooldown_playerCache
					if secsTillPass < serverCooldown then
						return false, string.format("[ServerCooldown] You must wait %.0f seconds to run the command.", serverCooldown - secsTillPass)
					end
				end

				if crossCooldown then
					local playerData = Core.GetPlayer(pDat.Player) or {}
					local crossCooldown_Cache = playerData._crossCooldownCache or (function()
						local tab = {}
						playerData._crossCooldownCache = tab
						return tab
					end)()
					local crossCooldown_playerCache = crossCooldown_Cache[cmdFullName]

					if crossCooldown_playerCache then
						local secsTillPass = os.clock() - crossCooldown_playerCache
						if secsTillPass < crossCooldown then
							return false, string.format("[CrossServerCooldown] You must wait %.0f seconds to run the command.", crossCooldown - secsTillPass)
						end
					end
				end
			end

			return permAllowed, nil
		end;
	};
end

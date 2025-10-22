return function(Vargs, GetEnv)
	local server = Vargs.Server
	local service = Vargs.Service

	local Commands, Decrypt, Encrypt, AddLog, TrackTask, Pcall
	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Defaults, Permissions, t
	local logError = server.LogError
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin
		Anti = server.Anti
		Core = server.Core
		HTTP = server.HTTP
		Logs = server.Logs
		Remote = server.Remote
		Process = server.Process
		Variables = server.Variables
		Settings = server.Settings
		Defaults = server.Defaults
		Permissions = server.Permissions
		Commands = Remote.Commands
		Decrypt = Remote.Decrypt
		Encrypt = Remote.Encrypt
		AddLog = Logs.AddLog
		TrackTask = service.TrackTask
		Pcall = server.Pcall
		t = server.Typechecker;

		--// NetworkServer Events
		if service.NetworkServer then
			service.NetworkServer.ChildAdded:Connect(server.Process.NetworkAdded);
			service.NetworkServer.DescendantRemoving:Connect(server.Process.NetworkRemoved);
		end

		--// Necessary checks to prevent first time users from bypassing bans.
		service.Events.DataStoreAdd_Banned:Connect(function(data: table | string)
			local userId = if type(data) == "string"
				then tonumber(string.match(data, ":(%d+)$"))
				elseif type(data) == "table" then data.UserId
				else nil

			local plr = userId and service.Players:GetPlayerByUserId(userId)
			if plr then
				local reason = if type(data) == "table" and data.Reason then data.Reason else "No reason provided"
				pcall(plr.Kick, plr, string.format("%s | Reason: %s", Variables.BanMessage, reason))
				AddLog("Script", {
					Text = `Applied ban on {plr.Name}`,
					Desc = `Ban reason: {reason}`,
				})
			end
		end)

		service.Events["DataStoreAdd_Core.Variables.TimeBans"]:Connect(function(data)
			local userId = if type(data) == "string"
				then tonumber(string.match(data, ":(%d+)$"))
				elseif type(data) == "table" then data.UserId
				else nil

			local plr = userId and service.Players:GetPlayerByUserId(userId)
			if plr then
				local reason = if type(data) == "table" and data.Reason then data.Reason else "No reason provided"

				pcall(
					plr.Kick,
					plr,
					string.format(
						"\n Reason: %s\n Banned until %s",
						(reason or "(No reason provided."),
						service.FormatTime(data.EndTime, { WithWrittenDate = true })
					)
				)
				AddLog("Script", {
					Text = `Applied TimeBan on {plr.Name}`,
					Desc = `Ban reason: {reason}`,
				})
			end
		end)

		Process.Init = nil
		AddLog("Script", "Processing Module Initialized")
	end

	local function RunAfterPlugins(data)
		local existingPlayers = service.Players:GetPlayers()

		--// Events
		service.Players.PlayerAdded:Connect(service.EventTask("PlayerAdded", Process.PlayerAdded))
		service.Players.PlayerRemoving:Connect(service.EventTask("PlayerRemoving", Process.PlayerRemoving))

		--// Load client onto existing players
		if existingPlayers then
			for i, p in existingPlayers do
				Core.LoadExistingPlayer(p)
			end
		end

		Process.RunAfterPlugins = nil
		AddLog("Script", "Process Module RunAfterPlugins Finished")
	end

	local function newRateLimit(rateLimit: table, rateKey: string | number)
		-- Ratelimit: table
		-- Ratekey: string or number

		local rateData = (type(rateLimit) == "table" and rateLimit) or nil

		if not rateData then
			error("Rate data doesn't exist (unable to check)")
		else
			-- RATELIMIT TABLE
			--[[

			Table:
				{
					Rates = 100; 	-- Max requests per traffic
					Reset = 1; 		-- Interval seconds since the cache last updated to reset

					ThrottleEnabled = false/true; -- Whether throttle can be enabled
					ThrottleReset = 10; -- Interval seconds since the cache last throttled to reset
					ThrottleMax = 10; -- Max interval count of throttles

					Caches = {}; -- DO NOT ADD THIS. IT WILL AUTOMATICALLY BE CREATED ONCE RATELIMIT TABLE IS CHECKING-
					--... FOR RATE PASS AND THROTTLE CHECK.
				}

		]]

			-- RATECACHE TABLE
			--[[

			Table:
				{
					Rate = 0;
					Throttle = 0; 		-- Interval seconds since the cache last updated to reset

					LastUpdated = 0; -- Last checked for rate limit
					LastThrottled = nil or 0; -- Last checked for throttle (only changes if rate limit failed)
				}

		]]
			local maxRate: number = math.abs(rateData.Rates) -- Max requests per traffic
			local resetInterval: number = math.floor(math.abs(rateData.Reset or 1)) -- Interval seconds since the cache last updated to reset

			local rateExceeded: boolean? = rateLimit.Exceeded or rateLimit.exceeded
			local ratePassed: boolean? = rateLimit.Passed or rateLimit.passed

			local canThrottle: boolean? = rateLimit.ThrottleEnabled
			local throttleReset: number? = rateLimit.ThrottleReset
			local throttleMax: number? = math.floor(math.abs(rateData.ThrottleMax or 1))

			-- Ensure minimum requirement is followed
			maxRate = (maxRate > 1 and maxRate) or 1
			-- Max rate must have at least one rate else anything below 1 returns false for all rate checks

			local cacheLib = rateData.Caches

			if not cacheLib then
				cacheLib = {}
				rateData.Caches = cacheLib
			end

			-- Check cache
			local rateCache: table = cacheLib[rateKey]
			local throttleCache
			if not rateCache then
				rateCache = {
					Rate = 0,
					Throttle = 0,
					LastUpdated = os.clock(),
					LastThrottled = nil,
				}

				cacheLib[rateKey] = rateCache
			end

			local nowOs = os.clock()

			if nowOs - rateCache.LastUpdated > resetInterval then
				rateCache.LastUpdated = nowOs
				rateCache.Rate = 0
			end

			local ratePass: boolean = rateCache.Rate + 1 <= maxRate

			local didThrottle: boolean = canThrottle and rateCache.Throttle + 1 <= throttleMax
			local throttleResetOs: number? = rateCache.ThrottleReset
			local canResetThrottle: boolean = throttleResetOs and nowOs - throttleResetOs <= 0

			rateCache.Rate += 1

			-- Check can throttle and whether throttle could be reset
			if canThrottle and canResetThrottle then
				rateCache.Throttle = 0
			end

			-- If rate failed and can also throttle, count tick
			if canThrottle and (not ratePass and didThrottle) then
				rateCache.Throttle += 1
				rateCache.LastThrottled = nowOs

				-- Check whether cache time expired and replace it with a new one or set a new one
				if not throttleResetOs or canResetThrottle then
					rateCache.ThrottleReset = nowOs
				end
			elseif canThrottle and ratePass then
				rateCache.Throttle = 0
			end

			if rateExceeded and not ratePass then
				rateExceeded:fire(rateKey, rateCache.Rate, maxRate)
			end

			if ratePassed and ratePass then
				ratePassed:fire(rateKey, rateCache.Rate, maxRate)
			end

			return ratePass, didThrottle, canThrottle, rateCache.Rate, maxRate, throttleResetOs
		end
	end

	local RateLimiter = {
		Remote = {
			Rates = 120,
			Reset = 60,
		},
		Command = {
			Rates = 20,
			Reset = 40,
		},
		Chat = {
			Rates = 10,
			Reset = 1,
		},
		CustomChat = {
			Rates = 10,
			Reset = 1,
		},
		RateLog = {
			Rates = 10,
			Reset = 2,
		},
	}

	local unWrap = service.UnWrap
	local function RateLimit(p, typ)
		local isPlayer = type(p) == "userdata" and p:IsA("Player")
		if isPlayer then
			local rateData = RateLimiter[typ]
			assert(rateData, `No rate limit data available for the given type {typ}`)
			local ratePass, didThrottle, canThrottle, curRate, maxRate = newRateLimit(rateData, p.UserId)
			return ratePass, didThrottle, canThrottle, curRate, maxRate
		else
			return true
		end
	end

	server.Process = {
		Init = Init,
		RunAfterPlugins = RunAfterPlugins,
		RateLimit = RateLimit,
		newRateLimit = newRateLimit,
		MsgStringLimit = 500, --// Max message string length to prevent long length chat spam server crashing (chat & command bar); Anything over will be truncated;
		MaxChatCharacterLimit = 250, --// Roblox chat character limit; The actual limit of the Roblox chat's textbox is 200 characters; I'm paranoid so I added 50 characters; Users should not be able to send a message larger than that;
		RemoteMaxArgCount = 5, --// The maximum argument count Adonis will take from Remote (alter if your script requires more arguments)
		RateLimits = {
			Remote = 0.01,
			Command = 0.1,
			Chat = 0.1,
			CustomChat = 0.1,
			RateLog = 10,
		},

		Remote = function(p, cliData, com, ...)
			if not service.Players:FindFirstChild(tostring(p.Name)) then
				return warn(`Player {p} wasn't in Players while sending a remote request. Ignored.`)
			end

			if not p:IsA("Player") then
				Anti.Detected(
					p,
					"Crash",
					"Received a Remote request from client but client wasn't a player(?)"
				)
			end

			if Anti.KickedPlayers[p] then
				p:Kick("▬▬▬▬ Astra ▬▬▬▬\n Communication following disconnect.\n Something wants you gone from this server but you are still sending requests. Have to remove you. Sorry.\n▬▬▬▬ BinaryBridge ▬▬▬▬\n")
				Anti.Detected(
					p,
					"Crash",
					"Communication Following Disconnect"
				)
			elseif not com or type(com) ~= "string" or #com > 50 or cliData == "WorseMemes" or com == "WorseMemes" then
				Anti.Detected(
					p,
					"Log",
					service.MaxLen((tostring(com) ~= "WorseMemes" and tostring(com)) or tostring(select(1, ...)), 150)
				) -- TODO^ CHECKS! A LOT OF CHECKS we are basically allowing anything to be sent right now and that is bad
				Anti.RemovePlayer(p);
				Anti.Detected(p, "Crash", "Invalid Remote Data")
			elseif cliData and type(cliData) ~= "table" then
				Anti.RemovePlayer(p);
				Anti.Detected(p, "Crash", "Invalid Remote Data")
				--elseif cliData and keys and cliData.Module ~= keys.Module then
				--	Anti.Detected(p, "Kick", "Invalid Client Module (r10006)")
			else
				local keys = Remote.Clients[tostring(p.UserId)]
				if keys and select("#", ...) <= Process.RemoteMaxArgCount then
					local args = { ... }
					local rateLimitCheck, _, _, curRemoteRate = RateLimit(p, "Remote")

					keys.LastUpdate = os.time()
					keys.Received += 1

					if type(com) == "string" then
						if com == `{keys.Special}GET_KEY` then
							if cliData.Mode == "Get" then
								AddLog("RemoteFires", {
									Text = `{p.Name} requested key from server`,
									Desc = "Player requested key from server",
									Player = p;
								})
								if keys.LoadingStatus == "WAITING_FOR_KEY" then
									keys.LoadingStatus = "LOADING"
									keys.RemoteReady = true
									AddLog("Script", string.format("%s requested client keys", p.Name))

									return keys.Key
									--else
									--Anti.Detected(p, "kick","Communication Key Error (r10003)")
								end
							elseif cliData.Mode == "Fire" then
								if keys.LoadingStatus == "WAITING_FOR_KEY" then
									Remote.Fire(p, `{keys.Special}GIVE_KEY`, keys.Key)
									keys.LoadingStatus = "LOADING"
									keys.RemoteReady = true

									AddLog("Script", string.format("%s requested client keys", p.Name))
									--else
									--Anti.Detected(p, "kick","Communication Key Error (r10003)")
								end

								AddLog("RemoteFires", {
									Text = `{p.Name} requested key from server`,
									Desc = "Player requested key from server",
									Player = p;
								})
							else
								Anti.Detected(p, "kick","Communication Key Error (r10003)")
							end

						elseif rateLimitCheck and string.len(com) <= Remote.MaxLen then
							local comString = Decrypt(com, keys.Key, keys.Cache)
							local command = (cliData.Mode == "Get" and Remote.Returnables[comString])
								or Remote.Commands[comString]

							AddLog("RemoteFires", {
								Text = string.format(
									"%s fired %s; Arg1: %s",
									p.Name,
									comString,
									service.MaxLen(tostring(args[1]), 50)
								),
								Desc = string.format(
									"Player fired remote command %s; %s",
									comString,
									Functions.ArgsToString(args)
								),
								Player = p,
							})

							if command then
								local rets = { TrackTask(`Remote: {p.Name}: {comString}`, command, false, p, args) }
								if not rets[1] then
									logError(p, `{comString}: {rets[2]}`)
								else
									return { table.unpack(rets, 2) }
								end
							else
								Anti.Detected(p, "Kick", "Invalid Remote Data (r10004)")
							end
						elseif rateLimitCheck and RateLimit(p, "RateLog") then
							Anti.Detected(
								p,
								"Log",
								string.format("Firing RemoteEvent too quickly (>Rate: %s/sec)", curRemoteRate)
							)
							warn(
								string.format(
									"%s is firing Adonis's RemoteEvent too quickly (>Rate: %s/sec)",
									p.Name,
									curRemoteRate
								)
							)
						end
					else
						Anti.Detected(p, "Log", "Out of Sync (r10005)")
					end

				else
					Anti.Detected(p, "Log", "Invalid Remote Data")
				end
			end
		end,

		Command = function(p, msg, opts, noYield)
			opts = opts or {}

			if not service.Players:FindFirstChild(tostring(p.Name)) and not opts.CrossServer and not opts.isWebPanel then
				return	--// Check if the player is still in the datamodel when the command is being ran
			end 		--// This should prevent users running infinite loops and then leaving

			local hasDonor = Admin.CheckDonor(p)
			local hasAdmin = Admin.CheckAdmin(p)
			local PlayerLimit = Variables.BatchCommandLimit.Player
			local DonorLimit = Variables.BatchCommandLimit.Donor
			local Limit = (hasDonor and PlayerLimit + DonorLimit) or PlayerLimit
			local Commands = 0

			for filter, func in pairs(server.Variables.CommandFilters) do
				if not string.match(msg, filter) then
					continue
				end

				local success, res, message = pcall(func, p, msg, opts, noYield)
				if success and res then
					msg = res
					continue
				elseif not success then
					Logs:AddLog(Logs.Errors, `{filter} failed for {msg}`)
				end
			end

			if #msg > Process.MsgStringLimit and type(p) == "userdata" and p:IsA("Player") and not hasAdmin then
				msg = string.sub(msg, 1, Process.MsgStringLimit)
			end

			for cmd in string.gmatch(msg, `[^{Settings.BatchKey}]+`) do
				if hasAdmin then break end;

				Commands += 1
				if Commands > Limit then
					Remote.MakeGui(p, 'Output', {
						Message = "You ran too many commands at once!";
					})
					return
				end
			end

			if
				#msg > Process.MsgStringLimit
				and type(p) == "userdata"
				and p:IsA("Player")
				and not hasAdmin
			then
				msg = string.sub(msg, 1, Process.MsgStringLimit)
			end

			msg = Functions.Trim(msg)

			if string.match(msg, Settings.BatchKey) then
				for cmd in string.gmatch(msg, `[^{Settings.BatchKey}]+`) do
					cmd = Functions.Trim(cmd)

					local waiter = `{Settings.PlayerPrefix}wait`
					if string.sub(string.lower(cmd), 1, #waiter) == waiter then
						local num = tonumber(string.sub(cmd, #waiter + 1))

						if num then
							task.wait(num)
						end
					else
						Process.Command(p, cmd, opts, false)
					end
				end
			else
				local alias,aliasData = Admin.IsAlias(p, msg)
				local pData = opts.PlayerData or (p and Core.GetPlayer(p))

				if string.match(msg, Settings.BatchKey) then
					return Process.Command(p, msg, opts, false)
				end

				local index, command, matched = Admin.GetCommand(msg)
				if not command and not alias then
					if opts.Check then
						Remote.MakeGui(p, "Output", {
							Message = if not hasAdmin
								then string.format(
									"'%s' is either not a valid command, or you do not have permission to run it.",
									msg
								)
								else string.format("'%s' is not a valid command.", msg),
						})
					end
					return
				end
				if alias then
					local exec = aliasData.Command
					local isRecursive = Admin.IsRecursiveAlias(p,alias,exec)

					if isRecursive then
						return Remote.MakeGui(p, 'Output', {
							Message = if isRecursive == true then `Your alias was inf recursive and has not been ran` else isRecursive;
						})
					end

					local suppliedArgs = string.split(msg, Settings.SplitKey)
					table.remove(suppliedArgs, 1)
					if #suppliedArgs > #aliasData.Args.Names then
						for i = #aliasData.Args.Names+1, #suppliedArgs do
							suppliedArgs[#aliasData.Args.Names] = suppliedArgs[#aliasData.Args.Names] .. Settings.SplitKey .. suppliedArgs[i]
							suppliedArgs[i] = nil
						end
					end
					exec = exec:gsub("<([^>]+)>", function(argName)
						local argIndex
						for i,v in ipairs(aliasData.Args.Names) do
							if v == argName then
								argIndex = i
							end
						end
						if argIndex then
							return suppliedArgs[argIndex] or aliasData.Args.Defaults[argIndex] or ""
						end
					end)
					Process.Command(p, exec, opts, noYield)
					return
				end
				local allowed, denialMessage = false, nil
				local isSystem = false

				local pDat = {
					Player = opts.Player or p,
					Level = opts.AdminLevel or Admin.GetLevel(p),
					isDonor = opts.IsDonor or (Admin.CheckDonor(p) and (Settings.DonorCommands or command.AllowDonors)),
				}

				if opts.isSystem or p == "SYSTEM" then
					isSystem = true
					allowed = not command.Disabled
					p = p or "SYSTEM"
				else
					allowed, denialMessage = Permissions.CheckPermission(pDat, command, false, opts)
				end

				if not allowed then
					if
						not (isSystem or opts.NoOutput)
						and (denialMessage or hasAdmin or opts.Check)
					then
						Remote.MakeGui(p, "Output", {
							Message = denialMessage
								or (
									if not hasAdmin
									then string.format(
										"'%s' is either not a valid command, or you do not have permission to run it.",
										msg
									)
									else string.format("You do not have permission to run '%s'.", msg)
								),
						})
					end
					return
				end

				local cmdArgs = command.Args or command.Arguments
				local argString = string.match(msg, `^.-{Settings.SplitKey}(.+)`) or ""
				local args = (opts.Args or opts.Arguments)
					or (#cmdArgs > 0 and Functions.Split(argString, Settings.SplitKey, #cmdArgs))
					or {}

				local taskName = string.format("Command :: %s : (%s)", p.Name, msg)

				if #args > 0 and not isSystem and command.Filter or opts.Filter then
					for i, arg in args do
						local cmdArg = cmdArgs[i]
						if cmdArg then
							if Admin.IsLax(cmdArg) == false then
								args[i] = service.LaxFilter(arg, p)
							end
						else
							args[i] = service.LaxFilter(arg, p)
						end
					end
				end

				if opts.CrossServer or (not isSystem and not opts.DontLog) then
					local noSave = command.AdminLevel == "Player" or command.Donors or command.AdminLevel == 0
					AddLog("Commands", {
						Text = `{((opts.CrossServer and "[CRS_SERVER] ") or "")}{p.Name}`,
						Desc = `{matched}{Settings.SplitKey}{table.concat(args, Settings.SplitKey)}`,
						Player = p,
						NoSave = noSave,
					})

					if Settings.ConfirmCommands then
						Functions.Hint(`Executed Command: [ {msg} ]`, { p })
					end
				end

				if noYield then
					taskName = `Thread: {taskName}`
				end

				Admin.UpdateCooldown(pDat, command)
				local ran, cmdError = TrackTask(
					taskName,
					command.Function,
					function(cmdError)
						if not opts.IgnoreErrors then
							if type(cmdError) == "string" then
								AddLog("Errors", `[{matched}] {cmdError}`)

								cmdError = cmdError:match("%d: (.+)$") or cmdError

								if not isSystem then
									Remote.MakeGui(p, "Output", {
										Message = cmdError,
									})

									Logs.AddLog(server.Logs.Errors, {
										Text = `Encountered an error while running a command: {msg}`,
										Desc = `Encountered an error while running a command: {msg}\n{cmdError}\n{debug.traceback()}`
									});
								end
							elseif cmdError ~= nil and cmdError ~= true and not isSystem then
								Remote.MakeGui(p, "Output", {
									Message = `There was an error but the error was not a string? : {cmdError}`,
								})
							end
						end
					end,
					p,
					args,
					{
						PlayerData = pDat,
						Options = opts,
					}
				)

				service.Events.CommandRan:Fire(p, {
					Message = msg,
					Matched = matched,
					Args = args,
					Command = command,
					Index = index,
					Success = ran,
					Error = if type(cmdError) == "string" then cmdError else nil,
					Options = opts,
					PlayerData = pDat,
				})
			end
		end,

		CrossServerChat = function(data)
			if data then
				for _, v in service.GetPlayers() do
					if Admin.GetLevel(v) > 0 then
						Remote.Send(v, "handler", "ChatHandler", data.Player, data.Message, "Cross")
					end
				end
			end
		end,

		Chat = function(p, msg)
			local didPassRate, didThrottle, canThrottle, curRate, maxRate = RateLimit(p, "Chat")
			if didPassRate then
				local isMuted = Admin.IsMuted(p)
				local IsShadowMuted = Admin.IsShadowMuted(p)
				local isAdmin = Admin.CheckAdmin(p) --and not isAdmin
				if utf8.len(utf8.nfcnormalize(msg)) > Process.MaxChatCharacterLimit  then
					Anti.Detected(p, "Kick", "Chatted message over the maximum character limit")
				elseif not isMuted then
					local msg = string.sub(msg, 1, Process.MsgStringLimit)
					local filtered = service.LaxFilter(msg, p)

					AddLog(Logs.Chats, {
						Text = `{p.Name}: {filtered}`,
						Desc = tostring(filtered),
						Player = p,
					})

					if Settings.ChatCommands then
						if Admin.DoHideChatCmd(p, msg) then
							--Remote.Send(p, "Function", "ChatMessage", `> {msg}`, Color3.new(1, 1, 1))
							Process.Command(p, msg, { Chat = true })
						elseif string.sub(msg, 1, 3) == "/e " then
							service.Events.PlayerChatted:Fire(p, msg)
							msg = string.sub(msg, 4)
							Process.Command(p, msg, { Chat = true })
						elseif string.sub(msg, 1, 8) == "/system " then
							service.Events.PlayerChatted:Fire(p, msg)
							msg = string.sub(msg, 9)
							Process.Command(p, msg, { Chat = true })
						else
							service.Events.PlayerChatted:Fire(p, msg)
							Process.Command(p, msg, { Chat = true })
						end
					else
						service.Events.PlayerChatted:Fire(p, msg)
					end
				elseif isMuted then
					local msg = string.sub(msg, 1, Process.MsgStringLimit)
					service.Events.MutedPlayerChat_UnFiltered:Fire(p, msg)
					local filtered = service.LaxFilter(msg, p)
					AddLog(Logs.Chats, {
						Text = `[MUTED] {p.Name}: {filtered}`,
						Desc = tostring(filtered),
						Player = p,
					})
					service.Events.MutedPlayerChat_Filtered:Fire(p, filtered)
				elseif IsShadowMuted then
					local msg = string.sub(msg, 1, Process.MsgStringLimit)
					service.Events.MutedPlayerChat_UnFiltered:Fire(p, msg)
					local filtered = service.LaxFilter(msg, p)
					AddLog(Logs.Chats, {
						Text = `[SHADOWMUTED] {p.Name}: {filtered}`,
						Desc = tostring(filtered),
						Player = p,
					})
					service.Events.ShadowMutedPlayerChat_Filtered:Fire(p, filtered)
				end

			elseif not didPassRate and RateLimit(p, "RateLog") then
				Anti.Detected(p, "Log", string.format("Chatting too quickly (>Rate: %s/sec)", curRate))
				warn(string.format("%s is chatting too quickly (>Rate: %s/sec)", p.Name, curRate))
			end
		end,

		PlayerAdded = function(p: Player)
			AddLog("Script", `Doing PlayerAdded Event for {p.Name}`)

			local key = tostring(p.UserId)
			local keyData = {
				Player = p,
				Key = service.HttpService:GenerateGUID(false),
				Cache = {},
				Sent = 0,
				Received = 0,
				LastUpdate = os.time(),
				FinishedLoading = false,
				LoadingStatus = "WAITING_FOR_KEY",
				--Special = Core.MockClientKeys and Core.MockClientKeys.Special;
				--Module = Core.MockClientKeys and Core.MockClientKeys.Module;
			}

			Core.UpdatePlayerConnection(p)
			Core.PlayerData[key] = nil
			Remote.Clients[key] = keyData

			local ran, err = Pcall(function()
				task.spawn(function()
					if Anti.UserSpoofCheck(p) then
						Remote.Clients[key] = nil
						Anti.Detected(p, "kick", "Username Spoofing")
					end
				end)

				local PlayerData = Core.GetPlayer(p)
				local level = Admin.GetLevel(p)
				local banned, reason = Admin.CheckBan(p)

				if banned then
					Remote.Clients[key] = nil
					p:Kick(Functions.GetKickMessage("GameBanMessage", {
						reason = reason or "No Reason Provided",
						time = os.time(),
						name = p.Name,
						id = p.UserId,
						moderator = { Name = "Server", UserId = 1 },
						kickType = "GameBan",
						expireTime = "Infinite",
						remainingTime = "Server Ban",
					}))
					return "REMOVED"
				end

				do
					local Removed = false
					local success, err = pcall(function()
						for filter, func in pairs(server.Variables.PlayerJoinFilters) do
							local success, res, message = pcall(func, p, PlayerData)
							if success and res == false then
								local Data = {
									filter = filter;
									error = message;
									TimeEnabled = 0;
									moderator = {Name = "SERVER"};
									Reason = "The maze wasn't meant for you"
								}
								local msg =  Functions.GetKickMessage("FailedJoinFilter", Data)
								p:Kick(
									msg
								)
								Removed = true
								Logs:AddLog(Logs.Script, `{p} failed the join filter {filter}`)
								break
							elseif not success then
								Logs:AddLog(Logs.Errors, `{filter} failed for {res}`)
							end
						end
					end)
					if Removed then
						--Remote.Clients[key] = nil
						return "REMOVED"
					end
				end

				if p.DisplayName then
					if string.match(p.DisplayName,"Latte_ImACheater") then
						Anti.Detected(p, "log", `Player has been flagged for being a likely exploiter (latte displayname)`)
					end
				end
			end)

			if not ran then
				AddLog("Errors", `{p.Name} PlayerAdded Failed: {err}`)
				warn("~! :: ASTRA :: SOMETHING FAILED DURING PLAYERADDED:")
				warn(tostring(err))
			end

			if Remote.Clients[key] then
				Core.HookClient(p)

				AddLog("Script", {
					Text = `{p.Name} loading started`,
					Desc = `{p.Name} successfully joined the server`,
				})

				AddLog("Joins", {
					Text = service.FormatPlayer(p),
					Desc = `{p.Name} joined the server`,
					Player = p,
				})


				--local test = Remote.Get(p, "Fingerprint")
				--print(`FROM SERVER: {test}`)
				--// Get chats
				p.Chatted:Connect(function(msg)
					local ran, err = TrackTask(`{p.Name}Chatted`, Process.Chat, false, p, msg)
					if not ran then
						logError(err)
					end
				end)

				--// Character added
				p.CharacterAdded:Connect(function(...)
					local ran, err = TrackTask(`{p.Name}CharacterAdded`, Process.CharacterAdded, false, p, ...)
					if not ran then
						logError(err)
					end
				end)



				task.delay(260, function()
					if
						p.Parent
						and Core.PlayerData[key]
						and Remote.Clients[key]
						and Remote.Clients[key] == keyData
						and keyData.LoadingStatus ~= "READY"
					then
						--AddLog("Script", {
						--	Text = `{p.Name} Failed to Load`,
						--	Desc = `{keyData.LoadingStatus}: Client failed to load in time (5 minutes?)`,
						--	Player = p,
						--})
						Anti.Detected(p, "kick", "Client failed to load in time (5 minutes?)");
					end
				end)
			elseif err ~= "REMOVED" then
				Anti.RemovePlayer(p, "Loading Error [Missing player, keys, or removed]")
			end
		end,

		PlayerRemoving = function(p)
			local data = Core.GetPlayer(p)
			local key = tostring(p.UserId)

			service.Events.PlayerRemoving:Fire(p)

			task.delay(1, function()
				if not service.Players:GetPlayerByUserId(p.UserId) then
					Core.PlayerData[key] = nil
				end
			end)

			AddLog("Script", {
				Text = string.format("Triggered PlayerRemoving for %s", p.Name),
				Desc = "Player left the game (PlayerRemoving)",
				Player = p,
			})

			AddLog("Leaves", {
				Text = service.FormatPlayer(p),
				Desc = `{p.Name} left the server`,
				Player = p,
			})

			for _, rateLimit in RateLimiter do
				if not rateLimit.Caches then
					continue
				end
				rateLimit.Caches[p.UserId] = nil
			end

			Core.SavePlayerData(p, data)

			Variables.TrackingTable[p.Name] = nil
			--for otherPlrName, trackTargets in Variables.TrackingTable do
			--	if trackTargets[p] then
			--		trackTargets[p] = nil
			--		local otherPlr = service.Players:FindFirstChild(otherPlrName)
			--		if otherPlr then
			--			task.defer(Remote.RemoveLocal, otherPlr, `{p.Name}Tracker`)
			--		end
			--	end
			--end

			Functions.SendLeaveNotif(p)

			if Commands.UnDisguise then
				Commands.UnDisguise.Function(p, { "me" })
			end

			Variables.IncognitoPlayers[p] = nil
		end,

		FinishLoading = function(p)
			local PlayerData = Core.GetPlayer(p)
			local level, rankName = Admin.GetLevel(p)
			local key = tostring(p.UserId)

			--// Fire player added
			service.Events.PlayerAdded:Fire(p)
			AddLog("Script", {
				Text = string.format("%s finished loading", p.Name),
				Desc = "Client finished loading",
			})

			--// Start keybind listener
			Remote.Send(p, "Function", "KeyBindListener", PlayerData.Keybinds or {})

			--// Load some playerdata stuff
			if type(PlayerData.Client) == "table" then
				if PlayerData.Client.CapesEnabled == true or PlayerData.Client.CapesEnabled == nil then
					Remote.Send(p, "Function", "MoveCapes")
				end
				Remote.Send(p, "SetVariables", PlayerData.Client)
			else
				Remote.Send(p, "Function", "MoveCapes")
			end

			--// Load all particle effects that currently exist
			Functions.LoadEffects(p)

			--// Load admin or non-admin specific things
			if level < 1 then
				if Settings.AntiSpeed and Settings.AllowClientAntiExploit then
					Remote.Send(p, "LaunchAnti", "Speed", {
						Speed = tostring(60.5 + math.random(9e8) / 9e8),
					})
				end

				if Settings.Detection and Settings.AllowClientAntiExploit then
					Remote.Send(p, "LaunchAnti", "MainDetection")

					Remote.Send(p, "LaunchAnti", "AntiAntiIdle", {
						Enabled = (Settings.AntiAntiIdle ~= false or Settings.AntiClientIdle ~= false),
					})

					if Settings.ExploitGuiDetection and Settings.AllowClientAntiExploit then
						Remote.Send(p, "LaunchAnti", "AntiCoreGui")
					end
				end

				if Settings.AntiBuildingTools and Settings.AllowClientAntiExploit then
					Remote.Send(p, "LaunchAnti", "AntiTools", { BTools = true })
				end
			end

			--// Finish things up
			if Remote.Clients[key] then
				Remote.Clients[key].FinishedLoading = true
				if p.Character and p.Character.Parent == workspace then
					local ran, err = TrackTask(
						`{p.Name} CharacterAdded`,
						Process.CharacterAdded,
						false,
						p,
						p.Character,
						{ FinishedLoading = true }
					)
					if not ran then
						logError(err)
					end
				else
					--// probably could make this RefreshGui instead of MakeGui down the road
					if Settings.Console and (not Settings.Console_AdminsOnly or level > 0) then
						Remote.MakeGui(p, "Console")
					end

					if Settings.HelpButton then
						Remote.RefreshGui(p, "HelpButton")
					end
				end

				Functions.SendJoinNotif(p)

				if PlayerData.NeedsDataWarning then
					Remote.MakeGui(p, "Notify",{
						Title = "IMPORTANT",
						Message = "Your data did not load correctly and will not be saved this session"
					})
					PlayerData.NeedsDataWarning = nil
				end

				if level > 0 then
					local oldVer = (level > 300) and Core.GetData("VersionNumber")
					local newVer = (level > 300) and tonumber(string.match(server.Changelog[1], "Version: (.*)"))

					if Settings.Notification then
						--Functions.Notification(
						--	"Welcome.",
						--	"Click here for commands.",
						--	{ p },
						--	15,
						--	"MatIcon://Verified user",
						--	Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`)
						--)

						Functions.Notification(
							p.Name,
							"Click here for commands.",
							{ p },
							15,
							"MatIcon://Verified user",
							Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`)
						)
						Functions.Notification(
							"Your Admin",
							`{rankName} ({level})`,
							{ p },
							15,
							"MatIcon://Verified user",
							Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}admins')`)
						)
						task.wait(1)

						if #server.Messages > 0 then
							for _, message in server.Messages do
								local isString = type(message) == "string"

								if level >= (not isString and message.Level or 300) then
									task.delay(
										1,
										Functions.Notification,
										not isString and message.Title or "Message",
										isString and message or not isString and message.Message or "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
										{p},
										isString and math.round((#message/19)+2.5) or not isString and message.Time or 10,
										not isString and message.Icon,
										not isString and message.onClick
									)
								end
							end
						end

						if oldVer and newVer and newVer > oldVer then
							Functions.Notification(
								"Updated!",
								"Click to view the changelog.",
								{ p },
								10,
								"MatIcon://Description",
								Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}changelog')`)
							)
						end

						--if level > 300 and Core.DebugMode == true then
						--	Functions.Notification(
						--		"Debug Mode Enabled",
						--		"Astra is currently running in Debug Mode.",
						--		{ p },
						--		10,
						--		"MatIcon://Bug report",
						--		Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}debugcmds')`)
						--	)
						--end

						if
							level > 300
							and Settings.DataStoreKey == Defaults.Settings.DataStoreKey
							and Core.DebugMode == false
						then
							Functions.Notification(
								"Warning!",
								"Using default datastore key!",
								{ p },
								"MatIcon://Description",
								Core.Bytecode([[
									local window = client.UI.Make("Window", {
										Title = "How to change the DataStore key";
										Size = {700,300};
										Icon = "rbxassetid://7510994359";
									})

									window:Add("ImageLabel", {
										Image = "rbxassetid://1059543904";
									})

									window:Ready()
								]])
							)
						end
					end

					if newVer then
						Core.SetData("VersionNumber", newVer)
					end
				end

				--// REF_1_ALBRT - 57s_Dxl - 100392_659;
				--// COMP[[CHAR+OFFSET] < INT[0]]
				--// EXEC[[BYTE[N]+BYTE[x]] + ABS[CHAR+OFFSET]]
				--// ELSE[[BYTE[A]+BYTE[x]] + ABS[CHAR+OFFSET]]
				--// VALU -> c_BYTE ; CAT[STR,x,c_BYTE] -> STR ; OUT[STR]]]
				--// [-150x261x247x316x246x243x238x248x302x316x261x247x316x246x234x247x247x302]
				--// END_ReF - 100392_659

				for v: Player in Variables.IncognitoPlayers do
					--// Check if the Player still exists before doing incognito to prevent LoadCode spam.
					if v == p or v.Parent == service.Players then
						continue
					end

					Remote.LoadCode(p, [[
							local plr = service.Players:GetPlayerByUserId(]] .. v.UserId .. [[)
							if plr then
								plr:Destroy()
								if plr.Character then
								plr.Character.Parent = nil
								end
							end
						]])
				end
			end
		end,

		CharacterAdded = function(p, char, ...)
			local key = tostring(p.UserId)
			local keyData = Remote.Clients[key]

			local args = { ... }

			if keyData then
				keyData.PlayerLoaded = true
			end

			task.wait(1 / 60)
			if char and keyData and keyData.FinishedLoading then
				local level = Admin.GetLevel(p)
				local pdata = Core.GetPlayer(p)
				local CommandBoxSettingForPlayer = pdata.Client.CommandBoxOnSpawn
				local CommandBoxOnSpawn

				if CommandBoxSettingForPlayer ~= nil then -- Player has chosen a custom setting for it so we will use that and ignore the game settings
					CommandBoxOnSpawn = CommandBoxSettingForPlayer
				else
					CommandBoxOnSpawn = Settings.CommandBoxonSpawn or false
				end

				--// Wait for UI stuff to finish
				task.wait(1)
				if not p:FindFirstChildWhichIsA("PlayerGui") then
					p:WaitForChild("PlayerGui", 9e9)
				end
				Remote.Get(p, "UIKeepAlive")

				--// GUI loading
				if Variables.NotifMessage then
					Remote.MakeGui(p, "Notif", {
						Message = Variables.NotifMessage,
					})
				end

				if Settings.TopBarShift then
					Remote.Send(p, "SetVariables", { TopBarShift = true })
				end

				if
					(
						not args[1]
							or (
								args[1] and typeof(args[1]) == "table" and args[1].FinishedLoading == nil
								or args[1].FinishedLoading == true
							)
					) and (Settings.Console and (not Settings.Console_AdminsOnly or level > 0))
				then
					Remote.RemoveGui(p, "Console")
					Remote.MakeGui(p, "Console")
				end

				if Settings.HelpButton then
					Remote.MakeGui(p, "HelpButton")
				end

				if CommandBoxOnSpawn and level > 0 then
					Remote.MakeGui(p, "CommandBox")
				end

				if level < 1 then
					if Settings.AntiNoclip and Settings.AllowClientAntiExploit then
						Remote.Send(p, "LaunchAnti", "HumanoidState")
					end
				end

				task.spawn(Functions.Donor, p)

				--// Fire added event
				service.Events.CharacterAdded:Fire(p, char, ...)

				if
					server.Commands.Track
					and char:WaitForChild("Head", 5)
					and char:WaitForChild("HumanoidRootPart", 2)
				then
					for otherPlrName, trackTargets in Variables.TrackingTable do
						if trackTargets[p] then
							server.Commands.Track.Function(service.Players[otherPlrName], { `@{p.Name}`, "true" })
						end
					end
				end
			end
		end,

		NetworkAdded = function(cli)
			task.wait(0.25)

			local p = cli:GetPlayer()

			if p then
				Core.Connections[cli] = p

				AddLog("Script", {
					Text = `{p.Name} connected`,
					Desc = `{p.Name} successfully established a connection with the server`,
					Player = p,
				})
			else
				AddLog("Script", {
					Text = "<UNKNOWN> connected",
					Desc = "An unknown user successfully established a connection with the server",
				})
			end

			service.Events.NetworkAdded:Fire(cli)
		end,

		NetworkRemoved = function(cli)
			local p = cli:GetPlayer() or Core.Connections[cli]

			Core.Connections[cli] = nil

			if p then
				Anti.KickedPlayers[p] = nil
				AddLog("Script", {
					Text = `{p.Name} disconnected`,
					Desc = `{p.Name} disconnected from the server`,
					Player = p,
				})
			else
				AddLog("Script", {
					Text = "<UNKNOWN> disconnected",
					Desc = "An unknown user disconnected from the server",
				})
			end

			service.Events.NetworkRemoved:Fire(cli)
		end,

		--[[
		PlayerTeleported = function(p,data)

		end;
		]]
	}
end

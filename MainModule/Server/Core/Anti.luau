return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;
	local antiNotificationDebounce = {}
	local antiNotificationResetTick = os.clock() + 60

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
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

		--// Client check
		service.StartLoop("ClientCheck", 30, Anti.CheckAllClients, true)

		Anti.Init = nil;
		Logs:AddLog("Script", "AntiExploit Module Initialized")
	end

	local function RunAfterPlugins(data)
		Anti.RunAfterPlugins = nil;
		Logs:AddLog("Script", "Anti Module RunAfterPlugins Finished");
	end

	server.Anti = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		ClientTimeoutLimit = 600; --// ... Five minutes without communication seems long enough right?
		SpoofCheckCache = {};
		KickedPlayers = setmetatable({}, {__mode = "k"});
		LEAK_RATE = 1;
		BUCKET_CAPACITY = 3;
		DEBUGNOCRASH = false;
		lastActionTimes = {};

		RemovePlayer = function(p, info)
			info = tostring(info) or "No Reason Given"

			local message = Functions.GetKickMessage("AntiKickMessage",{reason = info}) or '0x772'

			pcall(function() service.UnWrap(p):Kick(message) end)

			task.wait(1)

			pcall(p.Destroy, p)

			Logs.AddLog("Script",{
				Text = `Server removed {p}`;
				Desc = info;
			})
		end;

		CheckAllClients = function()
			--// Check if clients are alive
			if Settings.CheckClients and server.Running then
				Logs.AddLog(Logs.Script,{
					Text = "Checking Clients";
					Desc = "Making sure all clients are active";
				})

				for ind,p in service.Players:GetPlayers() do
					if p and p:IsA("Player") then
						local key = tostring(p.UserId)
						local client = Remote.Clients[key]
						if client and client.LastUpdate and client.PlayerLoaded then
							if os.time() - client.LastUpdate > Anti.ClientTimeoutLimit then
								Anti.Detected(p, "Kick", `Client Not Responding [>{Anti.ClientTimeoutLimit} seconds]`)
							end
						end
					end
				end
			end
		end;

		UserSpoofCheck = function(p)
			--// Supplied by BetterAccount
			if not service.RunService:IsStudio() then
				local userService = service.UserService;
				local success,err = pcall(function()
					local userInfo = Anti.SpoofCheckCache[p.UserId] or userService:GetUserInfosByUserIdsAsync({p.UserId})
					local data = userInfo and userInfo[1];

					Anti.SpoofCheckCache[p.UserId] = userInfo;

					if data and data.Id == p.UserId then
						if p.Name ~= data.Username or p.DisplayName ~= data.DisplayName then
							return true
						end
					else
						for i,user in userInfo do
							if user.Id == p.UserId then
								if p.Name ~= user.Username or p.DisplayName ~= user.DisplayName then
									return true
								end
							end
						end
					end
				end)

				if not success then
					warn(`Failed to check validity of player's name, reason: {err}`)
				end
			end
		end;

		CheckBackpack = function(p, obj)
			local ran, err = pcall(function()
				return p:WaitForChild("Backpack", 60):FindFirstChild(obj)
			end)
			return if ran then ran else false
		end;

		Detected = function(player, action, info)
			local cooldown = 3 / Anti.LEAK_RATE
			local shortenedinfo = string.sub(string.gsub(tostring(info), "\n", ""), 1, 70)
			local info = string.sub(string.gsub(tostring(info), "\n", ""), 1, 950)
			local lastActionTime = Anti.lastActionTimes[player] or 0

			if Anti.lastActionTimes[player] and lastActionTime + cooldown > os.clock() then
				local remainingActions = Anti.BUCKET_CAPACITY - (math.floor((os.clock() - lastActionTime) / cooldown) + 1)
				if remainingActions > 0 then
					Anti.lastActionTimes[player] = os.clock()
				else
					return
				end
			else
				Anti.lastActionTimes[player] = os.clock()
			end

			if Anti.KickedPlayers[player] then
				local message = Functions.GetKickMessage("AntiKickMessage",{reason = info}) or '0x772'
				player:Kick(message)
				return
			elseif service.RunService:IsStudio() then
				warn(`ANTI-EXPLOIT: {player.Name} {action} {info}`)
			elseif service.NetworkServer then
				if player then
					if string.lower(action) == "kick" then
						Anti.KickedPlayers[player] = true

						Anti.RemovePlayer(player, info)
					elseif string.lower(action) == "kill" and player.Character then
						local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

						if humanoid then
							humanoid:ChangeState(Enum.HumanoidStateType.Dead)
							humanoid.Health = 0
						end
						player.Character:BreakJoints()
					elseif string.lower(action) == "crash" then
						if Anti.DEBUGNOCRASH == true then
							return print(`SOMETHING TRIED CRASHING CLIENT BUT DEBUG MODE IS ON! {info}`)
						end

						Anti.KickedPlayers[player] = true

						Remote.Clients[tostring(player.UserId)] = nil
						pcall(function()
							local scr = server.Deps.DOnotrun:Clone()
							scr.Parent = player.Backpack
							scr.Disabled = false
						end)
						Remote.Send(player, "Function", "Kill")
						task.wait(5)
						pcall(function()
							local scr = Core.NewScript("LocalScript", [[while true do end]])
							scr.Parent = player.Backpack
							scr.Disabled = false
						end)

						Anti.RemovePlayer(player, info)
					elseif string.lower(action) ~= "log" then
						-- fake log (thonk?)
						Anti.Detected(player, "Kick", "Spoofed log")
						return;
					end
				end
			end

			Logs.AddLog(Logs.Script,{
				Text = `AE Detected {player}`;
				Desc = `The Anti-Exploit system detected strange activity from {player}`;
				Player = player;
			})

			Logs.AddLog(Logs.Exploit,{
				Text = `[Action: {action} User: ({player})] {info} (Mouse over for full info)`;
				Desc = tostring(info);
				Player = player;
			})

			local debounceIndex = `{action}{player}{info}`
			if os.clock() < antiNotificationResetTick then
				antiNotificationDebounce = {}
				antiNotificationResetTick = os.clock() + 60
			end

			if not antiNotificationDebounce[debounceIndex] then
				antiNotificationDebounce[debounceIndex] = 1
			elseif
				(string.lower(action) == "log" or string.lower(action) == "kill") and
				antiNotificationDebounce[debounceIndex] > 3
			then
				return
			end

			if os.clock() - lastActionTime < cooldown then
				return -- Dont treat it as a flag if the user seems to be spamming.
			end

			pcall(task.defer, function()
				Core.CrossServer(
					"ExploitFlagNotif",
					player.Name or "UNKNOWN",
					info,
					game.JobId
				)

				Functions.ExploitLog(player,info,{})
			end)
		end;
	};
end

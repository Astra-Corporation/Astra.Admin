--// Processing
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	local script = script
	local service = Vargs.Service
	local client = Vargs.Client
	local TextChatService = service.TextChatService

	local Anti, Core, Functions, Process, Remote, UI, Variables, log, logError
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;
		log = client.log;
		logError = client.logError
		Process.Init = nil;
	end

	local function RunLast()
		Process.RunLast = nil;
	end

	local function RunAfterLoaded(data)
		--// Events
		service.Player.Chatted:Connect(service.EventTask("Event: ProcessChat", Process.Chat))
		service.Player.CharacterRemoving:Connect(service.EventTask("Event: CharacterRemoving", Process.CharacterRemoving))
		service.Player.CharacterAdded:Connect(service.EventTask("Event: CharacterAdded", Process.CharacterAdded))
		service.LogService.MessageOut:Connect(Process.LogService) --service.EventTask("Event: MessageOut",client.Process.LogService,60))
		service.ScriptContext.Error:Connect(Process.ErrorMessage) --service.EventTask("Event: ErrorMessage",client.Process.ErrorMessage,60))
		TextChatService.OnIncomingMessage = Process.IncomingMessage
		--TextChatService.OnBubbleAdded = Process.OnBubbleAdded
		local logError = function(err)
			warn(err)
		end
		--// Get RateLimits
		Process.RateLimits = Remote.Get("RateLimits") or Process.RateLimits;

		Process.RunAfterLoaded = nil;
	end

	client.Process = {
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		RateLimits = { --// Defaults; Will be updated with server data at client run
			Remote = 0.02;
			Command = 0.1;
			Chat = 0.1;
			RateLog = 10;
		};

		Remote = function(data, com, ...)
			local args = {...}
			Remote.Received += 1
			if type(com) == "string" then
				if com == `{client.DepsName}GIVE_KEY` then
					if not Core.Key then
						log("~! Set remote key")
						Core.Key = args[1]

						log("~! Call Finish_Loading()")
						client.Finish_Loading()
					end
				elseif Core.Key then
					local comString = Remote.Decrypt(com,Core.Key)
					local command = (data.Mode == "Get" and Remote.Returnables[comString]) or Remote.Commands[comString]
					if command then
						local rets = {service.TrackTask(`Remote: {comString}`, command, false, args)}
						if not rets[1] then
							--logError(rets[2]) -- The more you go thru this the worse it gets.
							--TODO: Make this error handle better
							logError('Something in remote return was bad')
						else
							return {unpack(rets, 2)};
						end
					end
				end
			end
		end;

		LogService = function(Message, Type)
			--service.FireEvent("Output", Message, Type)
		end;

		ErrorMessage = function(Message, Trace, Script)
			--service.FireEvent("ErrorMessage", Message, Trace, Script)
			if Message and Message ~= "nil" and Message ~= "" and (string.find(Message,":: Adonis ::") or string.find(Message,script.Name) or Script == script) then
				logError(`{Message} - {Trace}`)
			end

			--if (Script == nil or (not Trace or Trace == "")) and not (Trace and string.find(Trace,"CoreGui.RobloxGui")) then
			--Anti.Detected("log",`Scriptless/Traceless error found. Script: {Script} - Trace: {Trace}`)
			--end
		end;

		Chat = function(msg)
			--service.FireEvent("Chat",msg)
			if not service.Player or service.Player.Parent ~= service.Players then
				Remote.Fire("ProcessChat",msg)
			end
		end;

		CharacterAdded = function(...)
			service.Events.CharacterAdded:Fire(...)

			task.wait()
			UI.GetHolder()
		end;

		IncomingMessage = function(message: TextChatMessage)
			if not message.TextSource then
				return nil
			end

			local Player = service.Players:GetPlayerByUserId(message.TextSource.UserId)
			local props: TextChatMessageProperties = Instance.new("TextChatMessageProperties")
			local TagText = Player:GetAttribute('ChatTagText')
			local TagColor = Player:GetAttribute('ChatTagColor')
			local ChatColor = Player:GetAttribute('ChatMessageColor')
			local TagColorHex = "#ffffff"

			if TagColor then 
				if not  type(TagColor == "Color3") then
					return warn('TagColor was not valid Color3')
				end

				TagColorHex = `#{TagColor:ToHex()}`
			end

			if TagText then
				props.PrefixText = `<font color='{TagColorHex}'>[{TagText}] </font>{message.PrefixText}`
			end

			if ChatColor then
				if not type(ChatColor == "Color3") then
					return warn('ChatMessageColor was not valid Color3')
				end
				ChatColor = ChatColor:ToHex()
				props.Text = `<font color='#{ChatColor}'>{message.Text}</font>`
			end

			return service.UnWrap(props)
		end,

		CharacterRemoving = function()
			if Variables.UIKeepAlive then
				for ind,g in client.GUIs do
					if g.Class == "ScreenGui" or g.Class == "GuiMain" or g.Class == "TextLabel" then
						if not (g.Object:IsA("ScreenGui") and not g.Object.ResetOnSpawn) and g.CanKeepAlive then
							g.KeepAlive = true
							g.KeepParent = g.Object.Parent
							g.Object.Parent = nil
						elseif not g.CanKeepAlive then
							pcall(g.Destroy, g)
						end
					end
				end
			end

			if Variables.GuiViewFolder then
				Variables.GuiViewFolder:Destroy()
				Variables.GuiViewFolder = nil
			end

			if Variables.ChatEnabled then
				service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			end

			if Variables.PlayerListEnabled then
				service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
			end

			local textbox = service.UserInputService:GetFocusedTextBox()
			if textbox then
				textbox:ReleaseFocus()
			end

			service.Events.CharacterRemoving:Fire()
		end
	}
end

client = nil
service = nil

return function(data)
	local gTable
	
	local window = client.UI.Make("Window",{
		Name  = "Bans";
		Title = "Bans";
		Size  = {300,300};
		AllowMultiple = false;
		
	})
	local playerData   = client.Remote.Get("PlayerData")
	local chatMod 	   = client.Remote.Get("Setting",{"Prefix","SpecialPrefix","BatchKey","AnyPrefix","DonorCommands","DonorCapes","PlayerPrefix"})
	local settingsData = client.Remote.Get("AllSettings")
	local player = ""
	local reason = ""

	local ranPlayers = {}

	local player = ""
	local reason = ""
    local bantype = ""
	local ranPlayers = {}

	local rframe = window:Add("ScrollingFrame", {
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
		BackgroundTransparency = 0.5;
	})

	rframe:Add("TextLabel", {
		Text = "  Player ";
		Size = UDim2.new(1, -10, 0, 30);
		Position = UDim2.new(0, 5, 0, 5);
		BackgroundTransparency = 0.4;
		TextXAlignment = "Left";
		Children = {
			{
				Class = "Dropdown";
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -125, 0, 0);
				BackgroundTransparency = 1;
				TextAlignment = "Right";
				NoArrow = false;

				Options = (function() local d = {"Select player"} for i,v in next,game.Players:GetChildren() do table.insert(d, v.Name) end return d end)();
				OnSelect = function(selection)
					player = selection
				end
			}
		}
	})
	rframe:Add("TextLabel", {
		Text = "  Ban type ";
		Size = UDim2.new(1, -10, 0, 30);
		Position = UDim2.new(0, 5, 0, 40);
		BackgroundTransparency = 0.4;
		TextXAlignment = "Left";
		Children = {
			{
				Class = "Dropdown";
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -125, 0, 0);
				BackgroundTransparency = 1;
				TextAlignment = "Right";
				NoArrow = false;

				Options = (function() local extras = {"Serverban","Gameban","Bruh"} return extras end)();
				OnSelect = function(selection)
					bantype = selection
				end
			}
		}
	})



	rframe:Add("TextLabel", {
		Text = " Reason ";
		Size = UDim2.new(1, -10, 0, 30);
		Position = UDim2.new(0, 5, 0, 75);
		BackgroundTransparency = 0.4;
		TextXAlignment = "Left";
		Children = {
			TextBox = {
				Text = "Reason";
				PlaceholderText = "Reason";
				Size = UDim2.new(0, 110, 1, 0);
				Position = UDim2.new(1, -135, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = "Right";
				TextChanged = function(text, FocusLost, new)
				
						reason = text
	
				end
			}
		}


	})

	rframe:Add("TextButton", {

		Text = "Ban";
		Position = UDim2.new(0, 5, 0, 125);
		Size = UDim2.new(1, -10, 0, 20);
		OnClicked = function(button)
			local split = " " 
			print(player.." "..reason)
			window:Destroy()
			if player == "" and reason == "" then
				client.UI.Make("Hint",{
					Message = "Please select a Player type in a reason"
				})

			elseif player == "" and reason == "" then
				client.UI.Make("Hint",{
					Message = "Please select a Player and type in a reason."
				})
			elseif player == "" then
				client.UI.Make("Hint",{
					Message = "Please select a Player."
				})

			elseif reason == "" then
				client.UI.Make("Hint",{
					Message = "Please type in a Reason."
				})
			elseif bantype == "" then
				client.UI.Make("Hint",{
					Message = "Please select a ban type."
				})
			end

			if reason ~= "" and player ~= "" then
				if bantype == "Gameban" then
					client.Remote.Send("ProcessCommand", chatMod.Prefix.."saveban".." "..player.." "..reason)
					window:Destroy()
				elseif bantype == "Serverban" then
					client.Remote.Send("ProcessCommand", chatMod.Prefix.."ban".." "..player.." "..reason)
					window:Destroy()
				end 
				
				

			end

		end
	})




	
	
	

		
 gTable = window.gTable
	window:Ready()
	end


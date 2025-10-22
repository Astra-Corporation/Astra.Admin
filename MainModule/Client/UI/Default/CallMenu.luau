return function(data, vargs)
	local client = vargs.client
	local service = vargs.service
	local UI = client.UI

	local window = UI.Make("Window", {
		Name = "Report",
		Title = "Report",
		Size = { 400, 300 },
		AllowMultiple = false,
	})
	local extranotes = "No extra notes provided."
	local Reasons = data.Reasons or {"No reasons specified!"}
	local Players  = data.Players or {"Server"}
	local player = ""
	local reason = ""
	local canclicksend = true

	local rframe = window:Add("ScrollingFrame", {

		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.new(0, 5, 0, 5),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.new(0.207843, 0.207843, 0.207843),
	})
	--// My hope is that this code is so awful I'm never allowed to write UI code again.
	-- Years later and now I'm writing UI code again.
	-- Also glad i stopped using that ugly // in the comments
	rframe:Add("TextLabel", {
		Text = "  Player: ",
		Size = UDim2.new(1, -10, 0, 30),
		Position = UDim2.new(0, 5, 0, 7),
		BackgroundTransparency = 1,

		TextXAlignment = "Center",
	--[[	Children = {
			{
				Class = "Dropdown",
				Size = UDim2.new(1, -10, 0, 30),
				Position = UDim2.new(0, 5, 0, 5),
				BackgroundTransparency = 1,
				TextAlignment = "Center",
				TextYAlignment = "Center",
				NoArrow = false,

				Options = (function()
					return Players
				end)(),
				OnSelect = function(selection)
					player = selection
				end,
			},
		},]]
	})
	rframe:Add("Dropdown",{
		Size = UDim2.new(1, -10, 0, 30),
		Position = UDim2.new(0, 5,0.012, 30),
		BackgroundTransparency = 0,
		TextAlignment = "Center",
		TextYAlignment = "Center",
		NoArrow = false,

		Options = (function()
			return Players
		end)(),
		OnSelect = function(selection)
			player = selection
		end,
	})

	rframe:Add("TextLabel", {
		Text = "  Reason: ",
		Size = UDim2.new(1, -10, 0, 30),
		Position = UDim2.new(0, 4, 0, 63),
		BackgroundTransparency = 1,
		TextXAlignment = "Center",
		--Children = {
		--	{
		--		Class = "Dropdown",
		--		Size = UDim2.new(1, -10, 0, 30),
		--		Position = UDim2.new(0, 5, 0, 5),
		--		BackgroundTransparency = 1,
		--		TextAlignment = "Center",
		--		TextYAlignment = "Center",
		--		NoArrow = false,

		--		Options = (function()
		--			return Reasons
		--		end)(),
		--		OnSelect = function(selection)
		--			reason = selection
		--		end,
		--	},
		--},
	})

	rframe:Add("Dropdown",{
		Size = UDim2.new(1, -10, 0, 30),
		Position = UDim2.new(0, 5,0, 93),
		BackgroundTransparency = 0,
		TextAlignment = "Center",
		TextYAlignment = "Center",
		NoArrow = false,

		Options = (function()
			return Reasons
		end)(),
		OnSelect = function(selection)
			reason = selection
		end,
	})

	rframe:Add("TextBox", {
		Text = "",
		PlaceholderText = "Extra Notes",
		Size = UDim2.new(1, -10, 0.317, 0),
		Position = UDim2.new(0, 5, 0,136),
		BackgroundTransparency = 0,
		ClearTextOnFocus = false,
		TextXAlignment = "Center",
		TextWrapped = true;
		TextChanged = function(text, FocusLost, new)
			extranotes = text
		end,
	})

	rframe:Add("TextButton", {

		Text = "Send Report",
		Position = UDim2.new(0, 5, 0, 225),
		Size = UDim2.new(1, -10, 0, 20),
		OnClicked = function(button)
			if canclicksend == false then
				return
			else
				canclicksend = true
				local split = " "
				if player == "" and reason == "" then
					return client.UI.Make("Hint", {
						Message = "Please select a Player and a reason",
					})
				elseif player == "" then
					return client.UI.Make("Hint", {
						Message = "Please select a Player",
					})
				elseif reason == "" then
					return client.UI.Make("Hint", {
						Message = "Please select Reason",
					})
				end
				local extranotes2 = extranotes or "No extra notes provided."
				if reason ~= "" and player ~= "" then
					canclicksend = false
					client.Remote.Send("SendReport", player, reason, extranotes2)
					window:Destroy()
				end
			end
		end,
	})

	gTable = window.gTable
	window:Ready()
end

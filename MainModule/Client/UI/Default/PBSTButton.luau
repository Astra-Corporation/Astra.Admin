client = nil
cPcall = nil
Pcall = nil
Routine = nil
service = nil
gTable = nil

--// All global vars will be wiped/replaced except script

return function(data, env)

	
	local playergui = service.PlayerGui
	local localplayer = service.Players.LocalPlayer
	local gui = service.New("ScreenGui")
	local toggle = service.New("ImageButton", gui)
	local gTable = client.UI.Register(gui)
	local UICorner = service.New("UICorner",toggle)
	if client.UI.Get("PBSTbutton", gui, true) then
		gui:Destroy()
		gTable:Destroy()
		return nil
	end

	gTable.Name = "PBSTbutton"
	gTable.CanKeepAlive = false

	toggle.Name = "Toggle"
	toggle.BackgroundTransparency = 1
	toggle.Position = UDim2.new(1, -45, 1, -45)
	toggle.Size = UDim2.new(0, 40, 0, 40)
	toggle.Image = "rbxassetid://5130794119"
	toggle.ImageTransparency = 0.5
	
	UICorner.CornerRadius = UDim.new(1, 1)

	toggle.MouseButton1Down:Connect(function()
		client.UI.Make("Notification",{text="Enabled Soon!"})
	end)

	gTable:Ready()
end

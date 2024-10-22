
client = nil
service = nil

return function(data)
	local window = client.UI.Make("Window",{
		Name  = data.Name.."Points";
		Title = "Points";
		Size  = {150,70};
		Position = UDim2.new(0, 10, 1, -80);
		AllowMultiple = false;
	})
	
	if window then
		local label = window:Add("TextLabel",{
			Text = data.Points;
			BackgroundTransparency = 1;
			TextSize = 20;
			Size = UDim2.new(1, 0, 1, 0);
			Position = UDim2.new(0, 0, 0, 0);
			--TextScaled = true;
			--TextWrapped = true;
		})
	end
	
	if game.ReplicatedStorage:FindFirstChild(data.Name.."Show") then
		game.ReplicatedStorage[data.Name.."Show"].OnClientEvent:Connect(function(newdata)
			if newdata ~= "Remove" then
				window.TextLabel.Text = newdata
			else
				window:Destroy()
			end
		end)
	end
	
	window:Ready()
end

client = nil
service = nil

return function(data)
	local window = client.UI.Make("Window",{
		Name  = "Data";
		Title = "Data";
		Size  = {401,263};
		--Position = UDim2.new(0, 10, 1, -80);
		AllowMultiple = true;
	})
	
	if window then
		local label = window:Add("TextBox",{
			Text = data.Text;
			BackgroundTransparency = 1;
			TextSize = 20;
			TextEditable = false;
			ClearTextOnFocus = false;
			Size = UDim2.new(1, 0, 1, 0);
			Position = UDim2.new(0, 0, 0, 0);
			--TextScaled = true;
			--TextWrapped = true;
		})
	end
	
	
	window:Ready()
end
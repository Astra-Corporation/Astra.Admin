
client = nil
service = nil

return function(data)
	local window = client.UI.Make("Window",{
		Name  = "Smartlog";
		Title = "Smartlog";
		Size  = {562, 300};
	})
	local tabFrame = window:Add("TabFrame",{
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	local Remote = client.Remote

	for _, tab in ipairs({
		[1] = tabFrame:NewTab("Commands", {Text = "Commands"}),
		[2] = tabFrame:NewTab("Data", {Text = "Data"})
		})
	do
		local scroller = tab:Add("ScrollingFrame",{
			List = {};
			ScrollBarThickness = 3;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 30);
			Size = UDim2.new(1, -10, 1, -35);
		})

		local search = tab:Add("TextBox", {
			Position = UDim2.new(0, 5, 0, 5);
			Size = UDim2.new(1, -10, 0, 20);
			BackgroundTransparency = 0.25;
			BorderSizePixel = 0;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "";
			PlaceholderText = "Search";
			TextStrokeTransparency = 0.8;
		})

		local function generate()
			local i = 1
			local filter = search.Text
			scroller:ClearAllChildren()
			for _,c in ipairs(data[tab.Name]) do
				if (c.Text:sub(1, #filter):lower() == filter:lower()) then
					scroller:Add("TextLabel", {
						Text = `  {c.Text}  `;
						ToolTip = c.Desc or "";
						BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
						Size = UDim2.new(1, 0, 0, 30);
						Position = UDim2.new(0, 0, 0, (30*(i-1)));
						TextXAlignment = "Left";
					})
					i += 1
				end
			end
			scroller:ResizeCanvas(false, true, false, false, 5, 0)
		end

		search:GetPropertyChangedSignal("Text"):Connect(generate)
		generate()

		task.spawn(function() --// this is horrible (idc about client code peformance)
			while true do
				data = Remote.Get("SmartlogData")
				generate()
				task.wait(5)
			end
		end)
	end



	window:Ready()
end

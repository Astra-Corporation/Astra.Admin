client = nil
service = nil

return function(data)
	local update

	local window = client.UI.Make("Window",{
		Name  = "Adminlists";
		Title = "Admins";
		Size  = {465, 325};
		AllowMultiple = false;
		OnRefresh = function()
			data.Ranks = client.Remote.Get("AdminListData").Admins
			update()
		end;
	})
	local tabFrame = window:Add("TabFrame",{
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	local Tabs = {}

	local Scrolls = {}

	local function makeTab(text)
		Tabs[text] = tabFrame:NewTab(text)

		Scrolls[text] = Tabs[text]:Add("ScrollingFrame", {
			Size = UDim2.new(1, -10, 1, -10);
			Position = UDim2.new(0, 5, 0, 5);
			BackgroundTransparency = 1;
		})
		Scrolls[text]:Add("UIListLayout",{
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAligment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder
		});
	end

	local function addEntry(list,text,optDesc,optChildren)
		local num = 1
		for _,v in pairs(list:GetChildren()) do if not v:IsA("UIListLayout") then num=num+1 end end
		list:Add("TextLabel", {
			Text = "  "..text;
			ToolTip = optDesc or nil;
			BackgroundTransparency = (num%2 == 0 and 0) or 0.2;
			Size = UDim2.new(1, 0, 0, 30);
			TextXAlignment = "Left";
			Children = optChildren or nil
		})
	end

	for i,v in pairs(data.Order or {}) do
		makeTab(v)
	end

	update = function()
		for _,v in pairs(Scrolls) do
			for _,v in pairs(v:GetChildren()) do
				if not v:IsA("UIListLayout") then v:Destroy() end
			end
		end

		for i,users in pairs(data.Ranks or {}) do
			if Scrolls[i] then
				for _,user in pairs(users) do
					addEntry(Scrolls[i],user.Text,(user.Tag or nil),(user.Tag and {
						TextLabel  = {
							Text = user.Tag;
							Size = UDim2.new(0, 100, 1, 0);
							Position = UDim2.new(1, -100, 0, 0); 
							BackgroundTransparency = 1;
						}
					}))
				end
			else 
				if #users>0 then
					makeTab(i)
					for _,user in pairs(users) do
						addEntry(Scrolls[i],user.Text,(user.Tag and user.Tag or nil),(user.Tag and {
							TextLabel  = {
								Text = user.Tag;
								Size = UDim2.new(0, 100, 1, 0);
								Position = UDim2.new(1, -100, 0, 0);
								BackgroundTransparency = 1;
							}
						} or nil))
					end
				end
			end
		end

		for _,v in pairs(Scrolls) do
			v:ResizeCanvas(false, true, false, false, 5, 5)
		end
	end

	update()


	window:Ready()
end

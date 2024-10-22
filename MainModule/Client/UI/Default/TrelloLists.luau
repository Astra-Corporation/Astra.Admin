
client = nil
service = nil

return function(data)
	local window = client.UI.Make("Window",{
		Name  = "TrelloLists";
		Title = "Ban Lists";
		Size  = {465, 325};
		AllowMultiple = false;
	})
	local tabFrame = window:Add("TabFrame",{
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})
	
	local lists = {
		Banlist = tabFrame:NewTab("Banlist", {Text = "Banlist"}), 
       -- Blacklist = tabFrame:NewTab("Blacklist", {Text = "Blacklist"}), 
        Mutes = tabFrame:NewTab("Mutes", {Text = "Mutes"}), 
	}
	
	local function makeList(list, items)
		for i = 1, #items do
			list:Add("TextLabel", {
				Text = "  "..items[i].." ";
				ToolTip = items[i];
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})
		end
		list:ResizeCanvas(false, true, false, false, 5, 5)
    end
    
	makeList(lists.Banlist, data.Banlist)
    makeList(lists.Mutes, data.Mutes)
	
	window:Ready()
end
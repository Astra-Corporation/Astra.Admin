client = nil;
service = nil;

return function(data)
	local tabs = {}
	local scrollers = {}
	local searches = {}

	local lists =  data.Lists
	local order = data.Order
	local OpenTab = data.OpenTab or data.StartingTab
	local function doSearch(tab, text)
		local found = {};
		text = string.lower(text);
		for i,v in next,tab do
			if text == "" or (type(v) == "string" and string.find(string.lower(v), text)) or (type(v) == "table" and ((v.Text and string.find(string.lower(v.Text),text) or (v.Filter and string.find(string.lower(v.Filter),text))))) then
				table.insert(found, v);
			end
		end

		return found;
	end

	local function genList(Tab, scroller, search)
		if search.Text ~= "Search" and search.Text ~= "" then
			
			scroller:GenerateList(doSearch(Tab, search.Text),{ZIndex=13;});
		else
			search.PlaceholderText = `Search ({#Tab} Items)`;
			scroller:GenerateList((Tab),{ZIndex=13;});
		end
	end

	local function gen(name,tab)
		genList(lists[tab], scrollers[name], searches[name]);
	end

	local window = client.UI.Make("Window",{
		Title  = data.Title or "Tab List";
		Name = "TabList";
		Size  = {655, 326};--{1, 0},{0, 354} --{0, 514},{0, 25} -- {0, 655},{0, 25}
		MinSize = {150, 100};
		AllowMultiple = true;
	});

	local tabFrame = window:Add("TabFrame",{
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	});

	local function makeTab(name)
		if tabs[name] then return end
		tabs[name] = tabFrame:NewTab(name, {Text = name, Transparency = 0, tabColor = Color3.fromRGB(53, 53, 53)});

		scrollers[name] = tabs[name]:Add("ScrollingFrame", {
			List = {};
			ScrollBarThickness = 2;
			FrameTransparency = 0;
			Position = UDim2.new(0, 5, 0, 30);
			Size = UDim2.new(1,-10,1,-35);
			--LabelProps = {
			--	TextXAlignment = "Left";
			--};
		});

		searches[name] = tabs[name]:Add("TextBox", {
			Size = UDim2.new(1, -10, 0, 20);
			Position = UDim2.new(0, 5, 0, 5);
			BorderSizePixel = 0;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "";
		--	PlaceholderText = `Search ({tabs} Items)`;
			TextStrokeTransparency = 0.8;
			Name = "Search";
		});


		searches[name].FocusLost:Connect(function(enter)
			gen(name,name);
		end);
	end
	if order then
		for i,v in pairs(order) do
			if lists[v] and #lists[v]>0 then
				makeTab(v)
			end
		end
	end

	for i,v in pairs(lists) do
		if #v > 0 then
			makeTab(i)
			gen(i,i)
		end
	end
	
	if OpenTab then
		if tabs[OpenTab] then
			tabs[OpenTab]:FocusTab()
		end
	end
	
	local gTable = window.gTable;
	window:Ready();


end
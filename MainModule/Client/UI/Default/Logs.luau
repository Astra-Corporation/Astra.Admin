client = nil
service = nil

return function(data)
	local Update = data.Update
	local UpdateArg = data.UpdateArg
	local UpdateArgs = data.UpdateArgs
	local AutoUpdate = data.AutoUpdate
	local LoadTime = data.LoadTime
	local gIndex = data.gIndex
	local gTable = data.gTable
	local Dots = data.Dots
	local Size = data.Size
	local Sanitize = data.Sanitize
	local Stacking = data.Stacking
	local getListTab
	local doSearch, genList
	local window
	
	local PagesEnabled = true --(data.PagesEnabled ~= nil and data.PagesEnabled) or (data.PagesEnabled == nil and true);
	local PageSize = 5--data.PageSize or 100;
	local PageNumber = 1 --  data.PageNumber or 1;
	local PageCounter = PageNumber or 1;
	local currentListTab
	local getListTab, getPage
	local doSearch, genList
	local window, scroller, search
	local lastPageButton, nextPageButton, pageCounterLabel;
	local currentListTab
	local pageDebounce
	
	local lastPageButton, nextPageButton, pageCounterLabel;
	local TimeOptions = data.TimeOptions
	local genDebounce = false;
	local RichText = data.RichTextSupported or data.RichTextAllowed or data.RichText;
	local TextSelectable = client.Variables.ForceListsSelectable or data.TextSelectable or false
	local tabs = {}
	local logs = {adminLogs = data.AdminLogs, chatLogs = data.ChatLogs, exploitLogs = data.ExploitLogs, joinLogs = data.JoinLogs, serverLogs = data.ServerLogs, clientLogs = data.ClientLogs, errorLogs = data.ErrorLogs, scriptLogs = data.ScriptLogs}
	local scrollers = {}
	local searches = {}
	
	function getPage(tab, pageNum)
		if not PagesEnabled then
			return tab;
		end

		local pageNum = pageNum or 1;
		local startPos = (pageNum-1) * PageSize;
		local endPos = pageNum *PageSize;
		local pageList = {};

		for i = startPos, endPos do
			if tab[i] ~= nil then
				table.insert(pageList, tab[i]);
			end
		end

		return pageList;
	end
	
	function getListTab(Tab)
		local newTab = {}
		local gotList = Tab;
		for i,v in next,Tab do
			if type(v) == "table" then
				newTab[i] = {
					Text = v.Text;
					Desc = v.Desc;
					Color = v.Color;
					Time = v.Time;
					Filter = v.Filter;
					Duplicates = v.Duplicates;
				}
			elseif type(v) == "string" then
				newTab[i] = {
					Text = v;
					Desc = v;
				}
			end
		end
		
		if PagesEnabled and #gotList > PageSize then


			scroller.Size = UDim2.new(1,-10,1,-60);
			nextPageButton.Visible = true;
			pageCounterLabel.Visible = true;
			if currentListTab then
				local maxPages = math.ceil(#currentListTab/PageSize);
				pageCounterLabel.Text = "Page: ".. PageCounter.."/"..maxPages;
			else
				pageCounterLabel.Text = "Page: ".. PageCounter;
			end

			if PageCounter > 1 then
				lastPageButton.Visible = true;
			else
				lastPageButton.Visible = false;
			end
		else
			scroller.Size = UDim2.new(1,-10,1,-30);
			nextPageButton.Visible = false;
			lastPageButton.Visible = false;
			pageCounterLabel.Visible = false;
		end
		
		if Stacking then
			local oldNewTab = newTab;
			newTab = {}
			local lastTab
			for ind,ent in next,oldNewTab do
				ent.Text = service.Trim(ent.Text)
				ent.Desc = service.Trim(ent.Desc)
				if not lastTab then
					lastTab = ent
					table.insert(newTab, ent)
				else
					if lastTab.Text == ent.Text and lastTab.Desc == ent.Desc then
						lastTab.Duplicates = (lastTab.Duplicates and lastTab.Duplicates+1) or 2
					else
						lastTab = ent
						table.insert(newTab, ent)
					end
				end
			end
		end

		for i,v in next,newTab do
			v.Text = (data.Sanitize and service.SanitizeString(v.Text)) or v.Text

			if v.Duplicates then
				v.Text = "(x"..v.Duplicates..") "..v.Text
			end

			if v.Time then
				v.Text = "["..(typeof(v.Time) == "number" and service.FormatTime(v.Time, TimeOptions) or v.Time).."] "..v.Text
			end
		end

		return newTab
	end

	function doSearch(tab, text)
		local found = {}
		text = string.lower(tostring(text)):gsub("%%", "%%%%"):gsub("%[", "%%["):gsub("%]", "%%]")
		for i,v in pairs(tab) do
			if text == "" or (type(v) == "string" and string.find(string.lower(v),text)) or (type(v) == "table" and ((v.Text and string.find(string.lower(tostring(v.Text)), text)) or (v.Filter and string.find(string.lower(v.Filter),text)))) then
				table.insert(found, v)
			end
		end

		return found
	end

	function genList(Tab, scroller, search)
		if search.Text ~= "Search" and search.Text ~= "" then
			currentListTab = Tab;
			scroller:GenerateList(getListTab(doSearch(Tab, search.Text)))
		else
			search.Text = ""
			search.PlaceholderText = `Search ({#Tab} Items)`;
			currentListTab = Tab;
			scroller:GenerateList(getListTab(Tab))
		end
	end

	local function format(logs)
		local val = {}
		for i,m in pairs(logs) do
			table.insert(val,{Time = m.Time;Text = m.Text..": "..m.Desc;Desc = m.Desc})
		end
		return val
	end
	
	local function gen(name)
		genList(logs[name.."Logs"], scrollers[name.."Scroller"], searches[name.."Search"])
	end

	window = client.UI.Make("Window",{
		Name  = "Logs";
		Title = "Logs";
		Size  = {736, 328};
		MinSize = {150, 100};
		AllowMultiple = false;
		OnRefresh = function()
			logs.adminLogs = client.Remote.Get("UpdateList", "CommandLogs", unpack(UpdateArgs or {UpdateArg}))
			logs.chatLogs = client.Remote.Get("UpdateList", "ChatLogs", unpack(UpdateArgs or {UpdateArg}))
			logs.exploitLogs = client.Remote.Get("UpdateList", "ExploitLogs", unpack(UpdateArgs or {UpdateArg}))
			logs.joinLogs = client.Remote.Get("UpdateList", "JoinLogs", unpack(UpdateArgs or {UpdateArg}))
			logs.serverLogs = client.Remote.Get("UpdateList", "ServerLog", unpack(UpdateArgs or {UpdateArg}))
			logs.clientLogs = client.Remote.Get("UpdateList", "ClientLog", unpack(UpdateArgs or {UpdateArg}))
			logs.errorLogs = client.Remote.Get("UpdateList", "Errors", unpack(UpdateArgs or {UpdateArg}))
			logs.scriptLogs = client.Remote.Get("UpdateList", "ScriptLogs", unpack(UpdateArgs or {UpdateArg}))
			--logs.buttonLogs = client.Remote.Get("UpdateList", "ButtonLogs", unpack(UpdateArgs or {UpdateArg}))
			--logs.ranktagLogs = client.Remote.Get("UpdateList", "RanktagLogs", unpack(UpdateArgs or {UpdateArg}))
			if logs.adminLogs then
				gen("admin")
			end
			if logs.chatLogs then
				gen("chat")
			end
			if logs.exploitLogs then
				gen("exploit")
			end
			if logs.joinLogs then
				gen("join")
			end
			if logs.serverLogs then
				gen("server")
			end
			if logs.clientLogs then
				gen("client")
			end
			if logs.errorLogs then
				gen("error")
			end
			if logs.scriptLogs then
				gen("script")
			end
			--[[if logs.buttonLogs then
				gen("button")
			end
			if logs.ranktagLogs then
				gen("ranktag")
			end]]--
		end
	})

	local tabFrame = window:Add("TabFrame",{
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})
	scroller = window:Add("ScrollingFrame", {
		List = {};
		ScrollBarThickness = 2;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 5, 0, 30);
		Size = UDim2.new(1,-10,1,-30); -- UDim2.new(1,-10,1,-60); when paging
		--LabelProps = {
		--	TextXAlignment = "Left";
		--}
	})

	pageCounterLabel = window:Add("TextLabel", {
		Size = UDim2.new(0, 60, 0, 20);
		Position = UDim2.new(0.5, -30, 1, -25);
		Text = "Page: 1";
		BackgroundTransparency = 1;
		TextTransparency = 0.5;
		TextWrapped = false;
		ClipsDescendants = false;
		TextXAlignment = "Center";
	})

	nextPageButton = window:Add("TextButton", {
		Size = UDim2.new(0, 50, 0, 20);
		Position = UDim2.new(1, -60, 1, -25);
		Text = ">";
		Visible = false;
		Debounce = true;
		OnClick = function()
			if not pageDebounce then
				pageDebounce = true;
				local origLTrans = nextPageButton.BackgroundTransparency;
				lastPageButton.BackgroundTransparency = origLTrans+0.35;

				local origNTrans = nextPageButton.BackgroundTransparency;
				nextPageButton.BackgroundTransparency = origNTrans+0.35;

				lastPageButton.TextTransparency = 0.8;
				nextPageButton.TextTransparency = 0.8;

				if currentListTab then
					local maxPages = math.ceil(#currentListTab/PageSize);
					PageCounter = math.clamp(PageCounter+1, 1, maxPages);

					pageCounterLabel.Text = "Page: ".. PageCounter.."/"..maxPages;

					if PageCounter > 1 then
						lastPageButton.Visible = true;
					end

					if PageCounter == maxPages then
						nextPageButton.Visible = false;
					end

					for i,v in next,scroller:GetChildren() do
						v:Destroy()
					end

					scroller.CanvasPosition = Vector2.new(0, 0);
					scroller:GenerateList(getPage(currentListTab, PageCounter));
				end

				lastPageButton.BackgroundTransparency = origLTrans;
				nextPageButton.BackgroundTransparency = origNTrans;

				lastPageButton.TextTransparency = 0;
				nextPageButton.TextTransparency = 0;

				pageDebounce = false;
			end
		end
	})

	lastPageButton = window:Add("TextButton", {
		Size = UDim2.new(0, 50, 0, 20);
		Position = UDim2.new(0, 10, 1, -25);
		Text = "<";
		Visible = false;
		Debounce = true;
		OnClick = function()
			if not pageDebounce then
				pageDebounce = true;
				local origLTrans = nextPageButton.BackgroundTransparency;
				lastPageButton.BackgroundTransparency = origLTrans+0.2;

				local origNTrans = nextPageButton.BackgroundTransparency;
				nextPageButton.BackgroundTransparency = origNTrans+0.2;

				lastPageButton.TextTransparency = 0.8;
				nextPageButton.TextTransparency = 0.8;

				if currentListTab then
					local maxPages = math.ceil(#currentListTab/PageSize);
					PageCounter = math.clamp(PageCounter-1, 1, maxPages);

					pageCounterLabel.Text = "Page: ".. PageCounter.."/"..maxPages;

					if PageCounter == 1 then
						lastPageButton.Visible = false;
					end

					if PageCounter == maxPages then
						nextPageButton.Visible = false;
					else
						nextPageButton.Visible = true;
					end

					for i,v in next,scroller:GetChildren() do
						v:Destroy()
					end

					scroller.CanvasPosition = Vector2.new(0, 0);
					scroller:GenerateList(getPage(currentListTab, PageCounter));
				end

				lastPageButton.BackgroundTransparency = origLTrans;
				nextPageButton.BackgroundTransparency = origNTrans;

				lastPageButton.TextTransparency = 0;
				nextPageButton.TextTransparency = 0;

				pageDebounce = false;
			end
		end
	})
	
	--search = window:Add("TextBox", {
	--	Size = UDim2.new(1, -10, 0, 20);
	--	Position = UDim2.new(0, 5, 0, 5);
	--	BackgroundTransparency = 0.5;
	--	BorderSizePixel = 0;
	--	TextColor3 = Color3.new(1, 1, 1);
	--	Text = "";
	--	--		PlaceholderText = `Search ({#Tabs} Items)`;
	--	TextStrokeTransparency = 0.8;
	--})

	--search:GetPropertyChangedSignal("Text"):Connect(function()
	--	currentListTab = Tab;
	--	genList(Tab)
	--end)
	
	local function makeTab(name)
		tabs[name.."Tab"] = tabFrame:NewTab(name:sub(1,1):upper()..name:sub(2), {Text = name:sub(1,1):upper()..name:sub(2).." Logs"})

		scrollers[name.."Scroller"] = tabs[name.."Tab"]:Add("ScrollingFrame",{
			List = {};
			ScrollBarThickness = 2;
			Position = UDim2.new(0, 5, 0, 30);
			Size = UDim2.new(1,-10,1,-35);
			LabelProps = {
				TextXAlignment = "Left";
			}
		})

		searches[name.."Search"] = tabs[name.."Tab"]:Add("TextBox", {
			Size = UDim2.new(1, -10, 0, 20);
			Position = UDim2.new(0, 5, 0, 5);
			BorderSizePixel = 0;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "Search";
			PlaceholderText = "Search";
			TextStrokeTransparency = 0.8;
		})

		local currentlog = logs[name.."Logs"]

		searches[name.."Search"].FocusLost:connect(function(enter)
			gen(name)
		end)
	end

	makeTab("admin")
	makeTab("chat")
	makeTab("exploit")
	makeTab("join")
	makeTab("server")
	makeTab("client")
	makeTab("error")
	makeTab("script")
	--makeTab("button")
	--makeTab("ranktag")

	gTable = window.gTable
	window:Ready()
	gen("admin")
	gen("chat")
	gen("exploit")
	gen("join")
	gen("server")
	gen("client")
	gen("error")
	gen("script")
	--gen("button")
	--gen("ranktag")

	if Update and AutoUpdate then
		while gTable.Active and task.wait(AutoUpdate) do
			window:Refresh()
		end
	end
end
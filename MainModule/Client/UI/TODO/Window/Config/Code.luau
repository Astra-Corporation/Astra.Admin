																																																				--[[
																																																				--[[
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--

	Window is a special UI object that can be used to easily make new Adonis UI windows.
	Refer to modules in the Default theme for examples of how Adonis windows work.

	Window Data Table Properties: [Supplied when creating] [{Name = "Window", Size = {120,70}, Title = "Some Window"}]
		[String] 	Name 		 - Name of the UI object being created [Used when finding duplicates or removing the window via client.UI.Remove()]
		[String] 	Title		 - Window title
		[String] 	Icon		 - The window's icon
		[Vector2]	CanvasSize	 - Sets the window's canvas size
		[Table]		Size		 - Size of the window in absolute X,Y values
		[UDim2] 	Position 	 - The window''s position on the screen
		[Table]		MinSize		 - The minimum AbsoluteSize of the window
		[Table]		MaxSize		 - The maximum Absolutesize of the window
		[Bool] 		NoHide		 - If true the minimize button will be removed
		[Bool] 		Walls		 - If true the window will be snapped back when dragged off the screen
		[Bool] 		NoClose		 - If true the close button will be removed
		[Bool]		CanKeepAlive - If false the window will be destroyed when the user respawns
		[Bool]		SizeLocked	 - If true the window cannot be resized
		[Bool]		NoDrag		 - If true window can't be dragged
		[Function]	OnClose		 - Called when the window closes
		[Function]	OnResize	 - Called when the window is resized by the user
		[Function]	OnReady		 - Called when window:Ready() is called
		[Function]	OnRefresh	 - Called when the window is refreshed and causes the refresh button to appear
		[Function]	OnMinimize	 - Called when the window is minimized or maximized; a bool is passed indicated whether it's opened or closed
		[Function]  IconClicked	 - Called when the window icon is clicked

	Window Properties:	[window.IsVisible]
		gTable		- The window's UI table
		Window 		- The window's ScreenGui
		Main 		- The "Main" frame inside of the drag bar
		Title		- The title TextLabel
		Dragger		- The drag bar that contains all window frames
		Object		- The ScrollingFrame that contains added elements and is returned when a window is created [Containing all window properties & methods]
	 	IsVisible 	- If window is minimized, IsVisible will be false
		Closed 		- If window is closed, Closed will be true

	Window Methods: [window:Close()]
		:Destroy()	- Closes the window
		:Close() 	- Closes the window
		:Refresh() 	- Forces a refresh as if the player clicked the refresh button
		:Ready()	- Sets the window as ready and displays it on the screen
		:Init()		- Same as window:Ready()
		:IsVisible() - Returns whether or not the window is minimized
		:IsClosed()	- Returns whether or not the window is closed

		:Add(string Class, table Data)	- Adds a new object of Class to the window with properties specified by Data
		:Hide(bool doHide)				- Forces the window to minimize or maximize
		:SetTitle(string newTitle)		- Sets the window's title
		:SetMinSize(table newMinSize)	- Sets the minimum allowed window size
		:SetMaxSize(table newMaxSize)	- Sets the maximum allowed window size
		:SetPosition(UDim2 newPos)		- Sets the window's position
		:SetSize(table newSize)			- Sets the window's size; Must be a table containing X and Y absolute sizes
		:GetPosition()					- Gets the window's position
		:GetSize()						- Gets the window's AbsoluteSize
		:BindEvent(Event, Function) 	- Binds an event to the window, disconnecting it when the window closes

	Object Methods:
		:SetPosition(UDim2 newPos) 		- Sets the position of object
		:SetSize(UDim2 newSize) 		- Sets the size of the object
		:Add(string Class, table Data)	- Adds a new object of Class to the object with properties specified by Data

	Boolean Class:
		:Toggle		- Enables/Disables the boolean object

	String Class:
		- BoxText			- Starting text
		- BoxProperties		- Properties of the TextBox
		- TextChanged		- Function fired when text is changed

	Slider Class:
		- Value 				- 0 - 1 Decimal representing slider position percentage
		- :SetValue(decimal)	- Sets the slider positional value

	Dropdown Class:
		- Selected				- String for currently selected option
		- Options 				- Table containing dropdown menu options
		- OnSelect 				- Function ran when an option is selected

	TabFrame Class:
		:NewTab(string, table)	- Makes a new tab
		:GetTab(string)			- Gets an existing tab's frame

	ScrollingFrame Class:
		:GenerateList(table)				- Generates a list and resizes the canvas
		:ResizeCanvas(bool onX, bool onY)	- Resizes based on it's contents

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
																																																				--]]

--// Todo:
--//	Window frame support for fullscreen/scale (pseudo-scale)
--//	Optimize/fix some stuff

--/////////////////////////////////////////////////////////--

local dZIndex 	 = 2
local dScrollBar = 4
local dBackground 	= Color3.new(31/255, 31/255, 31/255)
local dSecondaryBackground = dBackground:lerp(Color3.new(1,1,1), 0.1);
local dTransparency = 0
local dPixelSize 	= 0
local dBorder 		= Color3.new(27/255,42/255,53/255)
local dPosition 	= UDim2.new(0,5,0,5)
local dCanvasSize 	= UDim2.new(0, 0, 0, 0)
local dScrollImage 	= "http://roblox.com/asset?id=158348114"
local dTextColor = Color3.new(1,1,1)
local dSize 	 = UDim2.new(1,-10,1,-10)
local dFont 	 = "SourceSans"
local dTextSize  = 16
local dPlaceholderColor = Color3.fromRGB(178, 178, 178)
local MouseIcons = {
	Horizontal = "rbxassetid://1243146213";
	Vertical = "rbxassetid://1243145985";
	LeftCorner = "rbxassetid://1243145459";
	RightCorner = "rbxassetid://1243145350";
	TopRight = "rbxassetid://1243145459";
	TopLeft = "rbxassetid://1243145350";
}

--/////////////////////////////////////////////////////////--

local curSize
local create
local Expand
local doHide
local doClose
local dragSize
local isVisible
local DoRefresh
local getNextPos
local wallPosition
local setPosition
local checkMouse
local isInFrame
local setSize
local setMinSize
local setMaxSize
local apiIfy

client = nil
Pcall = nil
Routine = nil
service = nil
GetEnv = nil

local function isGui(child)
	return child:IsA("GuiObject");
end

--// All global vars will be wiped/replaced except script
return function(data, env)

	--local client = service.GarbleTable(client)
	local Player = service.Players.LocalPlayer
	local Mouse = Player:GetMouse()
	local InputService = service.UserInputService
	local gIndex = data.gIndex
	local gTable = data.gTable

	local Event = gTable.BindEvent
	local GUI = gTable.Object
	local Name = data.Name
	local Icon = data.Icon
	local Size = data.Size
	local Menu = data.Menu
	local Title = data.Title
	local Ready = data.Ready
	local Walls = data.Walls
	local noHide = data.NoHide
	local noClose = data.NoClose
	local noDrag = data.NoDrag
	local onReady = data.OnReady
	local onClose = data.OnClose
	local onResize = data.OnResize
	local onRefresh = data.OnRefresh
	local onMinimize = data.OnMinimize
	local ContextMenu = data.ContextMenu
	local ResetOnSpawn = data.ResetOnSpawn
	local CanKeepAlive = data.CanKeepAlive
	local iconClicked = data.IconClicked
	local SizeLocked = data.SizeLocked or data.SizeLock
	local CanvasSize = data.CanvasSize
	local Position = data.Position
	local Content = data.Content or data.Children
	local MinSize = data.MinSize or {150, 50}
	local MaxSize = data.MaxSize or {math.huge, math.huge}
	local curIcon = Mouse.Icon
	local isClosed = false
	local Resizing = false
	local Refreshing = false
	local checkProperty = service.CheckProperty
	local specialInsts = {}
	local inExpandable
	local addTitleButton
	local LoadChildren
	local BringToFront
	local functionify

	local Drag = GUI.Drag
	local Close = Drag.Close
	local Hide = Drag.Hide
	local Iconf = Drag.Icon
	local Titlef = Drag.Title
	local Refresh = Drag.Refresh
	local rSpinner = Refresh.Spinner
	local Main = Drag.Main
	local Tooltip = GUI.Desc
	local ScrollFrame = GUI.Drag.Main.ScrollingFrame
	local LeftSizeIcon = Main.LeftResizeIcon
	local RightSizeIcon = Main.RightResizeIcon
	local RightCorner = Main.RightCorner
	local LeftCorner = Main.LeftCorner
	local RightSide = Main.RightSide
	local LeftSide = Main.LeftSide
	local TopRight = Main.TopRight
	local TopLeft = Main.TopLeft
	local Bottom = Main.Bottom
	local Top = Main.Top
	local Config = GUI.Config
	local Components = Config.Components
	
	function Expand(ent, point, text, richText)
		local label = point:FindFirstChild("Label")

		if label then
			ent.MouseLeave:Connect(function(x,y)
				if inExpandable == ent then
					point.Visible = false
				end
			end)

			ent.MouseMoved:Connect(function(x,y)
				inExpandable = ent

				local text = text or ent.Desc.Value
				label.Text = text
				label.RichText = richText
				label.TextScaled = richText

				local sizeText = label.ContentText

				local maxWidth = 400
				local bounds = service.TextService:GetTextSize(sizeText, label.TextSize, label.Font, Vector2.new(maxWidth, math.huge))

				local sizeX, sizeY = bounds.X + 10, bounds.Y + 10
				local posX = (x + 6 + sizeX) < GUI.AbsoluteSize.X and (x + 6) or (x - 6 - sizeX)
				local posY = (y - 6 - sizeY) > 0 and (y - 6 - sizeY) or (y)

				point.Size = UDim2.fromOffset(sizeX, sizeY)
				point.Position = UDim2.fromOffset(posX, posY)
				point.Visible = text ~= ""
			end)
		end
	end
	
	local function spinObject(object, duration, fromAngle, toAngle)
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		service.TweenService:Create(object, tweenInfo, { Rotation = toAngle }):Play()
	end
	
	function getNextPos(frame)
		local farXChild, farYChild
		for i,v in ipairs(frame:GetChildren()) do
			if checkProperty(v, "Size") then
				if not farXChild or (v.AbsolutePosition.X + v.AbsoluteSize.X) > (farXChild.AbsolutePosition.X + farXChild.AbsoluteSize.X) then
					farXChild = v
				end

				if not farYChild or (v.AbsolutePosition.Y + v.AbsoluteSize.Y) > (farXChild.AbsolutePosition.Y + farXChild.AbsoluteSize.Y) then
					farYChild = v
				end
			end
		end

		return ((not farXChild or not farYChild) and UDim2.new(0,0,0,0)) or UDim2.new(farXChild.Position.X.Scale, farXChild.Position.X.Offset + farXChild.AbsoluteSize.X, farYChild.Position.Y.Scale, farYChild.Position.Y.Offset + farYChild.AbsoluteSize.Y)
	end

	function LoadChildren(Obj, Children)
		if Children then
			local runWhenDone = Children.RunWhenDone and functionify(Children.RunWhenDone, Obj)
			for class,data in pairs(Children) do
				if type(data) == "table" then
					if not data.Parent then data.Parent = Obj end
					create(data.Class or data.ClassName or class, data)
				elseif type(data) == "function" or type(data) == "string" and not runWhenDone then
					runWhenDone = functionify(data, Obj)
				end
			end

			if runWhenDone then
				runWhenDone(Obj)
			end
		end
	end

	function BringToFront()
		for i,v in ipairs(Player.PlayerGui:GetChildren()) do
			if v:FindFirstChild("__ADONIS_WINDOW") then
				v.DisplayOrder = 100
			end
		end

		GUI.DisplayOrder = 101
	end

	function addTitleButton(data)
		local startPos = 1
		local realPos
		local new
		local original = Hide
		local diff = (Hide.AbsolutePosition.X + Hide.AbsoluteSize.X) - Close.AbsolutePosition.X;
		local far = Close;

		for i,obj in ipairs(Drag:GetChildren()) do
			if obj:IsA("TextButton") then
				if obj.Visible and obj.AbsolutePosition.X < far.AbsolutePosition.X then
					far = obj;
				end
			end
		end;

		local size = data.Size or original.Size;
		local xPos = far.Position.X.Offset - (size.X.Offset - diff);
		realPos = UDim2.new(far.Position.X.Scale, xPos, original.Position.Y.Scale, original.Position.Y.Offset)

		data.Name = "__TITLEBUTTON"
		data.Size = size
		data.Parent = Drag
		data.ZIndex = data.ZIndex or original.ZIndex
		data.Position = data.Position or realPos
		data.TextSize = data.TextSize or original.TextSize
		data.TextColor3 = data.TextColor3 or original.TextColor3
		data.TextScaled = data.TextScaled or original.TextScaled
		data.TextScaled = data.TextScaled or original.TextScaled
		data.TextWrapped = data.TextWrapped or original.TextWrapped
		data.TextStrokeColor3 = data.TextStrokeColor3 or original.TextStrokeColor3
		data.TextTransparency = data.TextTransparency or original.TextTransparency
		data.TextStrokeTransparency = data.TextStrokeTransparency or original.TextStrokeTransparency
		data.BackgroundTransparency = data.BackgroundTransparency or original.BackgroundTransparency
		data.BackgroundColor3 = data.BackgroundColor3 or original.BackgroundColor3
		data.BorderSizePixel = data.BorderSizePixel or original.BorderSizePixel
		--data.TextXAlignment = data.TextXAlignment or original.TextXAlignment
		--data.TextYAlignment = data.TextYAlignment or original.TextYAlignment
		data.Font = data.Font or original.Font

		return create("TextButton", data)
	end

	function functionify(func, object)
		if type(func) == "string" then
			if object then
				local env = GetEnv()
				env.Object = object
				return client.Core.LoadCode(func, env)
			else
				return client.Core.LoadCode(func)
			end
		else
			return func
		end
	end

	function create(class, dataFound, existing)
		local data = dataFound or {}
		local class = data.Class or data.ClassName or class
		local new = existing or (specialInsts[class] and specialInsts[class]:Clone()) or service.New(class)
		local parent = data.Parent or new.Parent

		local Component = Components:FindFirstChild(class)

		local ComponentData = {
			new = new;
			create = create;
			GUI = GUI;
			functionify = functionify;
			data = data;
			checkProperty = checkProperty;
			client = client;
			service = service;
			getNextPos = getNextPos;
			dTextSize = dTextSize;
			dFont = dFont;
			dSecondaryBackground = dSecondaryBackground;
			dScrollBar = dScrollBar;
			Expand = Expand;
			Tooltip = Tooltip;
			isGui = isGui;
		}

		if dataFound then
			data.Parent = nil

			if data.Class or data.ClassName then
				data.Class = nil
				data.ClassName = nil
			end

			if not data.BorderColor3 and checkProperty(new, "BorderColor3") then
				new.BorderColor3 = dBorder
			end

			if not data.CanvasSize and checkProperty(new, "CanvasSize") then
				new.CanvasSize = dCanvasSize
			end

			if not data.BorderSizePixel and checkProperty(new, "BorderSizePixel") then
				new.BorderSizePixel = dPixelSize
			end

			if not data.BackgroundColor3 and checkProperty(new, "BackgroundColor3") then
				new.BackgroundColor3 = dBackground
			end

			if not data.PlaceholderColor3 and checkProperty(new, "PlaceholderColor3") then
				new.PlaceholderColor3 = dPlaceholderColor
			end

			if not data.Transparency and not data.BackgroundTransparency and checkProperty(new, "Transparency") and checkProperty(new, "BackgroundTransparency")  then
				new.BackgroundTransparency = dTransparency
			elseif data.Transparency and checkProperty(new, "BackgroundTransparency") then
				new.BackgroundTransparency = data.Transparency
			end

			if not data.TextColor3 and not data.TextColor and checkProperty(new, "TextColor3") then
				new.TextColor3 = dTextColor
			elseif data.TextColor then
				new.TextColor3 = data.TextColor
			end

			if not data.Font and checkProperty(new, "Font") then
				data.Font = dFont
			end

			if not data.TextSize and checkProperty(new, "TextSize") then
				data.TextSize = dTextSize
			end

			if not data.BottomImage and not data.MidImage and not data.TopImage and class == "ScrollingFrame" then
				new.BottomImage = dScrollImage
				new.MidImage = dScrollImage
				new.TopImage = dScrollImage
			end

			if not data.Size and checkProperty(new, "Size") then
				new.Size = dSize
			end

			if not data.Position and checkProperty(new, "Position") then
				new.Position = dPosition
			end

			if not data.ZIndex and checkProperty(new, "ZIndex") then
				new.ZIndex = dZIndex
				if parent and checkProperty(parent, "ZIndex") then
					new.ZIndex = parent.ZIndex
				end
			end

			if data.TextChanged and class == "TextBox" then
				local textChanged = functionify(data.TextChanged, new)
				new.FocusLost:Connect(function(enterPressed)
					textChanged(new.Text, enterPressed, new)
				end)
			end

			if (data.OnClicked or data.OnClick) and (class == "TextButton" or class == "ImageButton") then
				local debounce = false;
				local doDebounce = data.Debounce;
				local onClick = functionify((data.OnClicked or data.OnClick), new)
				new.MouseButton1Down:Connect(function()
					if not debounce then
						if doDebounce then
							debounce = true
						end

						onClick(new)

						debounce = false
					end
				end)
			end

			if data.Events then
				for event,func in pairs(data.Events) do
					local realFunc = functionify(func, new)
					Event(new[event], function(...)
						realFunc(...)
					end)
				end
			end

			if data.Visible == nil then
				data.Visible = true
			end

			if data.LabelProps then
				data.LabelProperties = data.LabelProps
			end
		end
		
		if Component then
			--print(`Found {Component} class from Components folder! Running the component code`)
			--local ComponentFunction = require(Component)
			
			local Sucess, Response = pcall(function() require(Component)(ComponentData) end)
			
			if not Sucess then
				warn(`\n**********************\nSomething went wrong when running {Component}\n{Response}\n**********************`)
				local errtext = service.New("TextLabel", {
					Parent = new;
					Name = "RenderError";
					BackgroundColor3 = dSecondaryBackground;
					TextColor = BrickColor.new('Really red');
					Text = `\n**********************\nSomething went wrong when running {Component}\n{Response}\n**********************`
				})
			end
		end
		
		if class == "Entry" then
			local label = new.Text
			local dots = new.Dots
			local desc = new.Desc
			local richText = data.RichText or label.RichText

			label.ZIndex = data.ZIndex or new.ZIndex
			dots.ZIndex = data.ZIndex or new.ZIndex

			if data.Text then
				label.Text = data.Text
				label.Visible = true
				data.Text = nil
			end

			if data.Desc or data.ToolTip then
				desc.Value = data.Desc or data.ToolTip
				data.Desc = nil
			end

			Expand(new, Tooltip, nil, richText)
		else
			if data.ToolTip then
				Expand(new, Tooltip, data.ToolTip, data.RichText)
			end
		end

		LoadChildren(new, data.Content or data.Children)

		data.Children = nil
		data.Content = nil

		for i,v in pairs(data) do
			if checkProperty(new, i) then
				new[i] = v
			end
		end

		new.Parent = parent

		return apiIfy(new, data, class),data
	end

	function apiIfy(gui, data, class)
		local newGui = service.Wrap(gui)
		gui:SetSpecial("Object", gui)
		gui:SetSpecial("SetPosition", function(ignore, newPos) gui.Position = newPos end)
		gui:SetSpecial("SetSize", function(ingore, newSize) gui.Size = newSize end)
		gui:SetSpecial("Add", function(ignore, class, data)
			if not data then data = class class = ignore end
			local new = create(class,data);
			new.Parent = gui;
			return apiIfy(new, data, class)
		end)

		gui:SetSpecial("Copy", function(ignore, class, gotData)
			local newData = {}
			local new

			for i,v in pairs(data) do
				newData[i] = v
			end

			for i,v in pairs(gotData) do
				newData[i] = v
			end

			new = create(class or data.Class or gui.ClassName, newData);
			new.Parent = gotData.Parent or gui.Parent;
			return apiIfy(new, data, class)
		end)

		return newGui
	end

	function doClose()
		if not isClosed then
			isClosed = true

			if onClose then
				local r,e = pcall(onClose)
				if e then
					warn(e)
				end
			end

			gTable:Destroy()
		end
	end

	function isVisible()
		return Main.Visible
	end

	local hideLabel = Hide:FindFirstChild("TextLabel")
	function doHide(doHide)
		local origLH = Hide.LineHeight
		if doHide or (doHide == nil and Main.Visible) then
			dragSize = Drag.Size
			Main.Visible = false
			Drag.BackgroundTransparency = Main.BackgroundTransparency
			Drag.BackgroundColor3 = Main.BackgroundColor3
			Drag.Size = UDim2.new(0, Drag.Size.X.Offset, Drag.Size.Y.Scale, Drag.Size.Y.Offset)

			if not Hide:FindFirstChildOfClass("ImageLabel") and hideLabel then
				hideLabel.Text = "+"
			elseif not Hide:FindFirstChildOfClass("ImageLabel") then
				Hide.Text = "+"
			end

			Hide.LineHeight = origLH
			gTable.Minimized = true
		elseif doHide == false or (doHide == nil and not Main.Visible) then
			Main.Visible = true
			Drag.BackgroundTransparency = 1
			Drag.Size = dragSize or Drag.Size

			if not Hide:FindFirstChildOfClass("ImageLabel") and hideLabel then
				hideLabel.Text = "-"
			elseif not Hide:FindFirstChildOfClass("ImageLabel") then
				Hide.Text = "-"
			end

			Hide.LineHeight = origLH
			gTable.Minimized = false
		end

		if onMinimize then
			onMinimize(Main.Visible)
		end

		if Walls then
			wallPosition()
		end
	end

	function isInFrame(x, y, frame)
		if x > frame.AbsolutePosition.X and x < (frame.AbsolutePosition.X+frame.AbsoluteSize.X) and y > frame.AbsolutePosition.Y and y < (frame.AbsolutePosition.Y+frame.AbsoluteSize.Y) then
			return true
		else
			return false
		end
	end

	function wallPosition()
		if gTable.Active then
			local x,y = Drag.AbsolutePosition.X, Drag.AbsolutePosition.Y
			local abx, gx, gy = Drag.AbsoluteSize.X, GUI.AbsoluteSize.X, GUI.AbsoluteSize.Y
			local ySize = (Main.Visible and Main.AbsoluteSize.Y) or Drag.AbsoluteSize.Y

			if x < 0 then
				Drag.Position = UDim2.new(0, 0, Drag.Position.Y.Scale, Drag.Position.Y.Offset)
			end

			if y < 0 then
				Drag.Position = UDim2.new(Drag.Position.X.Scale, Drag.Position.X.Offset, 0, 0)
			end

			if x + abx > gx then
				Drag.Position = UDim2.new(0, GUI.AbsoluteSize.X - Drag.AbsoluteSize.X, Drag.Position.Y.Scale, Drag.Position.Y.Offset)
			end

			if y + ySize > gy then
				Drag.Position = UDim2.new(Drag.Position.X.Scale, Drag.Position.X.Offset, 0, GUI.AbsoluteSize.Y - ySize)
			end
		end
	end

	function setSize(newSize)
		if newSize and type(newSize) == "table" then
			if newSize[1] < 50 then newSize[1] = 50 end
			if newSize[2] < 50 then newSize[2] = 50 end

			Drag.Size = UDim2.new(0,newSize[1],Drag.Size.Y.Scale,Drag.Size.Y.Offset)
			Main.Size = UDim2.new(1,0,0,newSize[2])
		end
	end

	function setPosition(newPos)
		if newPos and typeof(newPos) == "UDim2" then
			Drag.Position = newPos
		elseif newPos and type(newPos) == "table" then
			Drag.Position = UDim2.new(0, newPos[1], 0, newPos[2])
		elseif Size and not newPos then
			Drag.Position = UDim2.new(0.5, -Drag.AbsoluteSize.X/2, 0.5, -Main.AbsoluteSize.Y/2)
		end
	end

	function setMinSize(Table)
		if Table and typeof(Table) == "table" then
			MinSize = Table
		end
	end

	function setMaxSize(Table)
		if Table and typeof(Table) == "table" then
			MaxSize = Table
		end
	end

	if Name then
		gTable.Name = Name
		if data.AllowMultiple ~= nil and data.AllowMultiple == false then
			local found, num = client.UI.Get(Name, GUI, true)
			if found then
				doClose()
				return nil
			end
		end
	end

	if Size then
		setSize(Size)
	end

	if Position then
		setPosition(Position)
	end

	if Title then
		Titlef.Text = Title
	end

	if CanKeepAlive or not ResetOnSpawn then
		gTable.CanKeepAlive = true
		GUI.ResetOnSpawn = false
	elseif ResetOnSpawn then
		gTable.CanKeepAlive = false
		GUI.ResetOnSpawn = true
	end
	
	
	
	if Icon then
		Iconf.Visible = true
		Iconf.Image = Icon
		Iconf.Size = UDim2.new(0, 16, 0, 16)
		Iconf.Position = UDim2.new(0, 6, 0, 5)
		Iconf.ImageTransparency = 0
	end
	
	local egg = math.random(1, 200)
	
	if egg <= 1 then
		Iconf.Image = "rbxassetid://10723345347"
	end
	
	if CanvasSize then
		ScrollFrame.CanvasSize = CanvasSize
	end

	if noClose then
		Close.Visible = false
		Refresh.Position = Hide.Position
		Hide.Position = Close.Position
	end

	if noHide then
		Hide.Visible = false
		Refresh.Position = Hide.Position
	end

	if Walls then
		Drag.DragStopped:Connect(function()
			wallPosition()
		end)
	end

	if onRefresh then
		local debounce = false
		function DoRefresh()
			if not Refreshing then
				local done = false
				Refreshing = true

				--task.spawn(function()
				--	while gTable.Active and not done do
				--		for i = 0, 300, 10 do
				--			rSpinner.Rotation = -i
				--			task.wait(1 / 60)
				--		end
				--	end
				--end)

				spinObject(rSpinner, 1, rSpinner.Rotation, rSpinner.Rotation-360)
				onRefresh()
				task.wait(1)
				done = true
				Refreshing = false
			end
		end

		Refresh.MouseButton1Down:Connect(function()
			if not debounce then
				debounce = true
				DoRefresh()
				debounce = false
			end
		end)

		--Titlef.Size = UDim2.new(1,0, Titlef.Size.Y.Scale, Titlef.Size.Y.Offset)
		Titlef.Size = UDim2.new(1, -130, Titlef.Size.Y.Scale, Titlef.Size.Y.Offset)
	else
		Refresh.Visible = false
	end

	if iconClicked then
		Iconf.MouseButton1Down(function()
			iconClicked(data, GUI, Iconf)
		end)
	end

	if Menu then
		data.Menu.Text     = ""
		data.Menu.Parent   = Main
		data.Menu.Size     = UDim2.new(1,-10,0,25)
		data.Menu.Position = UDim2.new(0,5,0,25)
		ScrollFrame.Size   = UDim2.new(1,-10,1,-55)
		ScrollFrame.Position       = UDim2.new(0,5,0,50)
		data.Menu.BackgroundColor3 = Color3.fromRGB(216, 216, 216)
		data.Menu.BorderSizePixel  = 0
		create("TextLabel",data.Menu)
	end

	if not SizeLocked then
		local startXPos = Drag.AbsolutePosition.X
		local startYPos = Drag.AbsolutePosition.Y
		local startXSize = Drag.AbsoluteSize.X
		local startYSize = Drag.AbsoluteSize.Y
		local vars = client.Variables
		local newIcon
		local inFrame
		local ReallyInFrame

		local function readify(obj)
			obj.MouseEnter:Connect(function()
				ReallyInFrame = obj
			end)

			obj.MouseLeave:Connect(function()
				if ReallyInFrame == obj then
					ReallyInFrame = nil
				end
			end)
		end

		--[[
		readify(Drag)
		readify(ScrollFrame)
		readify(TopRight)
		readify(TopLeft)
		readify(RightCorner)
		readify(LeftCorner)
		readify(RightSide)
		readify(LeftSide)
		readify(Bottom)
		readify(Top)
		--]]

		function checkMouse(x, y) --// Update later to remove frame by frame pos checking
			if gTable.Active and Main.Visible then
				if isInFrame(x, y, Drag) or isInFrame(x, y, ScrollFrame) then
					inFrame = nil
					newIcon = nil
				elseif isInFrame(x, y, TopRight) then
					inFrame = "TopRight"
					newIcon = MouseIcons.TopRight
				elseif isInFrame(x, y, TopLeft) then
					inFrame = "TopLeft"
					newIcon = MouseIcons.TopLeft
				elseif isInFrame(x, y, RightCorner) then
					inFrame = "RightCorner"
					newIcon = MouseIcons.RightCorner
				elseif isInFrame(x, y, LeftCorner) then
					inFrame = "LeftCorner"
					newIcon = MouseIcons.LeftCorner
				elseif isInFrame(x, y, RightSide) then
					inFrame = "RightSide"
					newIcon = MouseIcons.Horizontal
				elseif isInFrame(x, y, LeftSide) then
					inFrame = "LeftSide"
					newIcon = MouseIcons.Horizontal
				elseif isInFrame(x, y, Bottom) then
					inFrame = "Bottom"
					newIcon = MouseIcons.Vertical
				elseif isInFrame(x, y, Top) then
					inFrame = "Top"
					newIcon = MouseIcons.Vertical
				else
					inFrame = nil
					newIcon = nil
				end
			else
				inFrame = nil
			end

			if (not client.Variables.MouseLockedBy) or client.Variables.MouseLockedBy == gTable then
				if inFrame and newIcon then
					Mouse.Icon = newIcon
					client.Variables.MouseLockedBy = gTable
				elseif client.Variables.MouseLockedBy == gTable then
					Mouse.Icon = curIcon
					client.Variables.MouseLockedBy = nil
				end
			end
		end

		local function inputStart(x, y)
			checkMouse(x, y)
			if gTable.Active and inFrame and not Resizing and not isInFrame(x, y, ScrollFrame) and not isInFrame(x, y, Drag) then
				Resizing = inFrame
				startXPos = Drag.AbsolutePosition.X
				startYPos = Drag.AbsolutePosition.Y
				startXSize = Drag.AbsoluteSize.X
				startYSize = Main.AbsoluteSize.Y
			end
		end

		local function inputEnd()
			if gTable.Active then
				if Resizing and onResize then
					onResize(UDim2.new(Drag.Size.X.Scale, Drag.Size.X.Offset, Main.Size.Y.Scale, Main.Size.Y.Offset))
				end

				Resizing = nil
				Mouse.Icon = curIcon
				--DragEnabled = true
				--if Walls then
				--	wallPosition()
				--end
			end
		end

		local function inputMoved(x, y)
			if gTable.Active then
				if Mouse.Icon ~= MouseIcons.TopRight and Mouse.Icon ~= MouseIcons.TopLeft and Mouse.Icon ~= MouseIcons.RightCorner and Mouse.Icon ~= MouseIcons.LeftCorner and Mouse.Icon ~= MouseIcons.Horizontal and Mouse.Icon ~= MouseIcons.Vertical then
					curIcon = Mouse.Icon
				end

				if Resizing then
					local moveX = false
					local moveY = false
					local newPos = Drag.Position
					local xPos, yPos = x, y
					local newX, newY = startXSize, startYSize

					--DragEnabled = false

					if Resizing == "TopRight" then
						newX = (xPos - startXPos) + 3
						newY = (startYPos - yPos) + startYSize -1
						moveY = true
					elseif Resizing == "TopLeft" then
						newX = (startXPos - xPos) + startXSize -1
						newY = (startYPos - yPos) + startYSize -1
						moveY = true
						moveX = true
					elseif Resizing == "RightCorner" then
						newX = (xPos - startXPos) + 3
						newY = (yPos - startYPos) + 3
					elseif Resizing == "LeftCorner" then
						newX = (startXPos - xPos) + startXSize + 3
						newY = (yPos - startYPos) + 3
						moveX = true
					elseif Resizing == "LeftSide" then
						newX = (startXPos - xPos) + startXSize + 3
						newY = startYSize
						moveX = true
					elseif Resizing == "RightSide" then
						newX = (xPos - startXPos) + 3
						newY = startYSize
					elseif Resizing == "Bottom" then
						newX = startXSize
						newY = (yPos - startYPos) + 3
					elseif Resizing == "Top" then
						newX = startXSize
						newY = (startYPos - yPos) + startYSize - 1
						moveY = true
					end

					if newX < MinSize[1] then newX = MinSize[1]  end
					if newY < MinSize[2] then newY = MinSize[2] end
					if newX > MaxSize[1] then newX = MaxSize[1] end
					if newY > MaxSize[2] then newY = MaxSize[2] end

					if moveX then
						newPos = UDim2.new(0, (startXPos+startXSize)-newX, newPos.Y.Scale, newPos.Y.Offset)
					end

					if moveY then
						newPos  = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, (startYPos+startYSize)-newY)
					end

					Drag.Position = newPos
					Drag.Size = UDim2.new(0, newX, Drag.Size.Y.Scale, Drag.Size.Y.Offset)
					Main.Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, newY)

					if not Titlef.TextFits then
						Titlef.Visible = false
					else
						Titlef.Visible = true
					end
				else
					checkMouse(x, y)
				end
			end
		end

		Event(InputService.InputBegan, function(input, gameHandled)
			if not gameHandled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				local Position = input.Position
				inputStart(Position.X, Position.Y)
			end
		end)

		Event(InputService.InputChanged, function(input, gameHandled)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local Position = input.Position
				inputMoved(Position.X, Position.Y)
			end
		end)

		Event(InputService.InputEnded, function(input, gameHandled)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				inputEnd()
			end
		end)

		--[[Event(Mouse.Button1Down, function()
			if gTable.Active and inFrame and not Resizing and not isInFrame(Mouse.X, Mouse.Y, ScrollFrame) and not isInFrame(Mouse.X, Mouse.Y, Drag) then
				Resizing = inFrame
				startXPos = Drag.AbsolutePosition.X
				startYPos = Drag.AbsolutePosition.Y
				startXSize = Drag.AbsoluteSize.X
				startYSize = Main.AbsoluteSize.Y
				checkMouse()
			end
		end)

		Event(Mouse.Button1Up, function()
			if gTable.Active then
				if Resizing and onResize then
					onResize(UDim2.new(Drag.Size.X.Scale, Drag.Size.X.Offset, Main.Size.Y.Scale, Main.Size.Y.Offset))
				end

				Resizing = nil
				Mouse.Icon = curIcon
				--if Walls then
				--	wallPosition()
				--end
			end
		end)--]]
	else
		LeftSizeIcon.Visible  = false
		RightSizeIcon.Visible = false
	end


	Close.MouseButton1Down:Connect(doClose)
	Hide.MouseButton1Down:Connect(function() doHide() end)
	gTable.CustomDestroy = function()
		if client.Variables.MouseLockedBy == gTable then
			Mouse.Icon = curIcon
			client.Variables.MouseLockedBy = nil
		end

		if not isClosed then
			isClosed = true
			if onClose then
				onClose()
			end
		end

		service.UnWrap(GUI):Destroy()
	end

	for i,child in ipairs(GUI:GetChildren()) do
		if child.Name ~= "Desc" and child.Name ~= "Drag" then
			specialInsts[child.Name] = child
			child.Parent = nil
		end
	end

	--// Drag & DisplayOrder Handler
	do
		local windowValue = Instance.new("BoolValue", GUI)
		local dragDragging = false
		local dragOffset
		local inFrame

		windowValue.Name = "__ADONIS_WINDOW"

		Event(Main.InputBegan, function(input)
			if gTable.Active and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				BringToFront()
			end
		end)

		Event(Drag.InputBegan, function(input)
			if gTable.Active then
				inFrame = true

				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					BringToFront()
				end
			end
		end)

		Event(Drag.InputChanged, function(input)
			if gTable.Active then
				inFrame = true
			end
		end)

		Event(Drag.InputEnded, function(input)
			inFrame = false
		end)

		Event(InputService.InputBegan, function(input)
			if inFrame and GUI.DisplayOrder == 101 and not dragDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then--isInFrame(input.Position.X, input.Position.Y, object) then
				if not noDrag then
					dragDragging = true
					BringToFront()
					dragOffset = Vector2.new(Drag.AbsolutePosition.X - input.Position.X, Drag.AbsolutePosition.Y - input.Position.Y)
				end
			end
		end)

		Event(InputService.InputChanged, function(input)
			if dragDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				Drag.Position = UDim2.fromOffset(dragOffset.X + input.Position.X, dragOffset.Y + input.Position.Y)
			end
		end)

		Event(InputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragDragging = false
			end
		end)
	end

	--// Finishing up
	local api = apiIfy(ScrollFrame, data)
	local meta = api:GetMetatable()
	local oldNewIndex = meta.__newindex
	local oldIndex = meta.__index

	create("ScrollingFrame", nil, ScrollFrame)
	LoadChildren(api, Content)

	api:SetSpecial("gTable", gTable)
	api:SetSpecial("Window", GUI)
	api:SetSpecial("Main", Main)
	api:SetSpecial("Title", Titlef)
	api:SetSpecial("Dragger", Drag)
	api:SetSpecial("Destroy", doClose)
	api:SetSpecial("Close", doClose)
	api:SetSpecial("Object", ScrollFrame)
	api:SetSpecial("Refresh", DoRefresh)
	api:SetSpecial("AddTitleButton", function(ignore, data) if type(ignore) == "table" and not data then data = ignore end return addTitleButton(data) end)
	api:SetSpecial("Ready", function() if onReady then onReady() end gTable.Ready() BringToFront() end)
	api:SetSpecial("BindEvent", function(ignore, ...) Event(...) end)
	api:SetSpecial("Hide", function(ignore, hide) doHide(hide) end)
	api:SetSpecial("SetTitle", function(ignore, newTitle) Titlef.Text = newTitle end)
	api:SetSpecial("SetPosition", function(ignore, newPos) setPosition(newPos) end)
	api:SetSpecial("SetSize", function(ignore, newSize) setSize(newSize) end)
	api:SetSpecial("SetMinSize",function(ignore, Table) setMinSize(Table) end)
	api:SetSpecial("SetMaxSize",function(ignore, Table) setMaxSize(Table) end)
	api:SetSpecial("GetPosition", function() return Drag.AbsolutePosition end)
	api:SetSpecial("GetSize", function() return Main.AbsoluteSize end)
	api:SetSpecial("IsVisible", isVisible)
	api:SetSpecial("IsClosed", isClosed)

	meta.__index = function(tab, ind)
		if ind == "IsVisible" then
			return isVisible()
		elseif ind == "Closed" then
			return isClosed
		else
			return oldIndex(tab, ind)
		end
	end

	setSize(Size)
	setPosition(Position)

	if Ready then
		gTable:Ready()
		BringToFront()
	end
	
	return api,GUI
end
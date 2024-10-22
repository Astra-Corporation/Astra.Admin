client = nil
service = nil

return function(data)
    local window = client.UI.Make("Window",{
        Name  = "Adminlists";
        Title = "Admin Lists";
        Size  = {640, 325};
        AllowMultiple = false;
    })
    local tabFrame = window:Add("TabFrame",{
        Size = UDim2.new(1, -10, 1, -10);
        Position = UDim2.new(0, 5, 0, 5);
    })

    local lists = {}

    -- Function to create or retrieve a list for each rank
    local function getList(rankName)
        if not lists[rankName] then
            lists[rankName] = tabFrame:NewTab(rankName, {Text = rankName}) -- Create a new tab for the rank
        end
        return lists[rankName]
    end

    -- Function to add a user to the list with Trello indication
    local function addUserToList(list, user)
        local name, trello = user:match("^([^%[%]]+)%s*%[([^%[%]]+)%]") -- Extract name and Trello tag
        if not name then
            name = user
        end
        if not trello then
            trello = ""
        end
        local displayUser = name
        if trello ~= "" then
            displayUser = name .. " [Trello]"
        end
        list:Add("TextLabel", {
            Text = "  " .. displayUser;
            ToolTip = name;
            BackgroundTransparency = (#list:GetChildren() % 2 == 0 and 0) or 0.2;
            Size = UDim2.new(1, -10, 0, 30);
            Position = UDim2.new(0, 5, 0, (#list:GetChildren() * 30) + 5);
            TextXAlignment = "Left";
            Children = {
                TextLabel = {
                    Text = trello;
                    Size = UDim2.new(0, 100, 1, 0);
                    Position = UDim2.new(1, -100, 0, 0); 
                    BackgroundTransparency = 1;
                }
            }
        })
        list:ResizeCanvas(false, true, false, false, 5, 5)
    end

    -- Process InGame data first
    local inGameList = getList("InGame") -- Get or create the InGame list
    local inGameData = data["InGame"]
    if type(inGameData) == "table" then
        for _, user in ipairs(inGameData) do
            addUserToList(inGameList, user) -- Add InGame user to the list
        end
    end

    -- Process other ranks
    for rankName, rankData in pairs(data) do
        if rankName ~= "InGame" then
            local targetRankName = rankName:gsub("%[Trello%] ", "") -- Remove [Trello] from the rank name
            local targetList = getList(targetRankName) -- Get or create the target list
            if type(rankData) == "table" then
                if rankName:match("%[Trello%]") then
                    for _, user in ipairs(rankData.Users) do
                        addUserToList(targetList, user) -- Add Trello user to the respective list
                    end
                elseif type(rankData.Users) == "table" then
                    for _, user in ipairs(rankData.Users) do
                        addUserToList(targetList, user) -- Add user to the respective list
                    end
                end
            end
        end
    end

    window:Ready()
end

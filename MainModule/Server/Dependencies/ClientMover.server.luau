--disable
 --client
--// ARIDe Client Loader (Non-ReplicatedFirst Version)

local DebugMode = true;

local players = game:GetService("Players");
local player = players.LocalPlayer;
local folder = script.Parent;
local container = folder.Parent;
local Kick = player.Kick;
local module = folder:WaitForChild("Client");
local target = player;
local realPrint = print;
local realWarn = warn;
local clock = os.clock;

local start = clock();

local function print(...)
	--realPrint(...)
end

local warn = function(str)
	--realWarn(`ACLI: {str}`)
end

local function Kill(info)
	if DebugMode then realWarn(info) return end
	pcall(function() Kick(player, info) end)
	task.wait(1)
	--pcall(function() while not DebugMode do task.wait() pcall(function() while true do end end) end end)
end

if module and module:IsA("ModuleScript") then
	warn("Loading Folder...")
	local nameVal
	local origName
	local depsFolder
	local clientModule

	warn("Waiting for Client & Special")
	nameVal = folder:WaitForChild("Special", 30)

	warn("Checking Client & Special")
	--callCheck(nameVal)
	--callCheck(clientModule)

	warn("Getting origName")
	origName = (nameVal and nameVal.Value) or folder.Name
	warn(`Got name: {origName}`)

	warn("Removing old client folder...")
	local starterPlayer = game:GetService("StarterPlayer");
	local playerScripts = starterPlayer:FindFirstChildOfClass("StarterPlayerScripts");
	local found = playerScripts:FindFirstChild(folder.Name);
	warn(`FOUND?! {found}`);
	warn(`LOOKED FOR : {folder.Name}`)
	if found then
		print("REMOVED!")
		found.Parent = nil --found:Destroy();
	end
	--// Sometimes we load a little too fast and generate a warning from Roblox so we need to introduce some (minor) artificial loading lag...
	warn("Changing child parent...")

	folder.Name = "";

	task.wait();

	folder.Parent = nil; --// We cannot do this assynchronously or it will disconnect events that manage to connect before it changes parent to nil...

	warn("Destroying parent...")
	print("Debug: Loading the client?")

	local Client = require(module);

	warn(`Got metatable: {Client}`)

	if Client then
		local Success, Return = pcall(Client, {
			Module = module,
			Start = start,
			Loader = script,
			Name = origName,
			Folder = folder,
			Kill = Kill
		})

		warn(`Got return: {Return}`)

		if Return ~= "SUCCESS" then
			realWarn(Return)

			Kill("ACLI: Loading Error [Bad Module Return]")
		else
			print("Debug: The client was found and loaded?")
			warn("Client Loaded")

			if container and container:IsA("ScreenGui") then
				container.Parent = nil --container:Destroy();
			end
		end
	end
end

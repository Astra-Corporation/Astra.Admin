----------------------------------------------
--- 	Scroll down for settings		   ---
--- Do not alter the three variables below ---
----------------------------------------------
local settings = {};		--// The settings table which contains all settings
local Settings = settings; 	--// For custom commands that use 'Settings' rather than the lowercase 'settings'
local descs = {};			--// Contains settings descriptions
----------------------------------------------

--------------
-- SETTINGS --
--------------
																																																																				
settings.BaseURL = ""; --// Proxy url without /
settings.CallReasons = {"Exploiting","Spamming","Chat bypassing","Inappropriate behavior","Misc"};
settings.ApiKey = "" -- // Api key if needed
settings.MainCallWebhook = "" --// Webhook url for calls or api path to whatever api is used.
settings.LogWebhook = ""
settings.ExploitLogWebhook = ""
																																																																				
settings.HideScript = true						 -- When the game starts the Adonis_Loader model will be hidden so other scripts cannot access the settings module; Disable if your game uses AssetService:SavePlaceAsync()
settings.DataStore = "Astra_1"					 -- DataStore the script will use for saving data; Changing this will lose any saved data
settings.DataStoreKey = "CHANGE_THIS"			 -- CHANGE THIS TO ANYTHING RANDOM! Key used to encrypt all datastore entries; Changing this will lose any saved data
settings.DataStoreEnabled = true				 -- Disable if you don't want to load settings and admins from the datastore; PlayerData will still save
settings.LocalDatastore = false					 -- If this is turned on, a mock DataStore will forcibly be used instead and shall never save across servers

settings.Storage = game:GetService("ServerStorage")  -- Where things like tools are stored
settings.RecursiveTools = false						 -- Whether tools that are included in sub-containers within settings.Storage will be available via the :give command (useful if your tools are organized into multiple folders)

settings.Theme = "Default"				-- UI theme;
settings.MobileTheme = "Mobilius"		-- Theme to use on mobile devices; Some UI elements are disabled

																																																																																				--[[
	**HOW TO ADD ADMINISTRATORS:**
		Below are the administrator permission levels/ranks (Mods, Admins, HeadAdmins, Creators, StuffYouAdd, etc)
		Simply place users into the respective "Users" table for whatever level/rank you want to give them.

		Format Example:
			settings.Ranks = {
				["Moderators"] = {
					Level = 100;
					Users = {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
				}
			}

		If you use custom ranks, existing custom ranks will be imported with a level of 1.
		Add all new CustomRanks to the table below with the respective level you want them to be.

	NOTE: Changing the level of built-in ranks (Moderators, Admins, HeadAdmins, Creators)
				will also change the permission level for any built-in commands associated with that rank. 																																				-			-]]

settings.Ranks = {
	["Moderators"] = {
		Level = 100;
		Users = {
			--// Add users here
		};
	};

	["Admins"] = {
		Level = 200;
		Users = {
			--// Add users here
		};
	};

	["HeadAdmins"] = {
		Level = 300;
		Users = {
			--// Add users here
		};
	};

	["Creators"] = {
		Level = 900; --// Anything 900 or higher will be considered a creator and will bypass all perms & be allowed to edit settings in-game.
		Users = {
			--// Add users here (Also, don't forget quotations and all that)
		};
	};
};

--// Use the below table to set command permissions; Commented commands are included for example purposes
settings.Permissions = {
	-- "ff:HeadAdmins"; --// Changes :ff to HeadAdmins and higher (HeadAdmins = Level 300 by default)
	-- "kill:300"; --// Changes :kill to level 300 and higher (Level 300 = HeadAdmins by default)
	-- "ban:200,300" --// Makes it so :ban is only usable by levels 200 and 300 specifically (nothing higher or lower or in between)
};	-- Format: {"Command:NewLevel"; "Command:Customrank1,Customrank2,Customrank3";}

--// Use the below table to define "pre-set" command aliases
--// Command aliases; Format: {[":alias <arg1> <arg2> ..."] = ":command <arg1> <arg2> ..."}
settings.Aliases = {
	[":examplealias <player> <fireColor>"] = ":ff <player> | :fling <player> | :fire <player> <fireColor>" --// Order arguments appear in alias string determines their required order in the command message when ran later
};

settings.Banned = {}		-- List of people banned from the game 		  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
settings.Muted = {}			-- List of people muted (cannot send chat messages)				 		  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
settings.Blacklist = {}		-- List of people banned from running commands 	  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
settings.Whitelist = {}		-- People who can join if whitelist enabled	  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}

settings.MusicList = {} 	-- List of songs to appear in the :musiclist	  Format: {{Name = "somesong", ID = 1234567}, {Name = "anotherone", ID = 1243562}}
settings.CapeList = {}		-- List of capes							  Format: {{Name = "somecape", Material = "Fabric", Color = "Bright yellow", ID = 12345567, Reflectance = 1}; {etc more stuff here}}
settings.InsertList = {} 	-- List of models to appear in the :insertlist and can be inserted using ':insert <name>'	  Format: {{Name = "somemodel", ID = 1234567}; {Name = "anotherone", ID = 1243562}}
settings.Waypoints = {}     -- List of waypoints you can teleport via ':to wp-WAYPOINTNAME' or ':teleport PLAYER tp.WAYPOINTNAME' Format {YOURNAME1 = Vector3.new(1,2,3), YOURNAME2 = Vector(231,666,999)}

settings.SaveAdmins = true		  -- If true anyone you :admin or :headadmin in-game will save
settings.LoadAdminsFromDS = true  -- If false, any admins saved in your DataStores will not load
settings.WhitelistEnabled = false -- If true enables the whitelist/server lock; Only lets admins & whitelisted users join

settings.Prefix = ";"				-- The : in :kill me
settings.PlayerPrefix = "!"			-- The ! in !donate; Mainly used for commands that any player can run; Do not make it the same as settings.Prefix
settings.SpecialPrefix = ""			-- Used for things like "all", "me" and "others" (If changed to ! you would do :kill !me)
settings.SplitKey = " "				-- The space in :kill me (eg if you change it to / :kill me would be :kill/me)
settings.BatchKey = "|"				-- :kill me | :ff bob | :explode scel
settings.ConsoleKeyCode = "Quote"	-- Keybind to open the console; Rebindable per player in userpanel; KeyCodes: https://developer.roblox.com/en-us/api-reference/enum/KeyCode

--// Easily add new custom commands below (without needing to create a plugin module)
--// You can also use this to overwrite existing commands if you know the command's index (found in the command's respective module within the Adonis MainModule)
settings.Commands = {
	ExampleCommand1 = {								--// The index & table of the command
		Prefix = Settings.Prefix;				--// The prefix the command will use, this is the ':' in ':ff me'
		Commands = {"examplecommand1", "examplealias1", "examplealias2"};	--// A table containing the command strings (the things you chat in-game to run the command, the 'ff' in ':ff me')
		Args = {"arg1", "arg2", "etc"};	--// Command arguments, these will be available in order as args[1], args[2], args[3], etc; This is the 'me' in ':ff me'
		Description = "Example command";--// The description of the command
		AdminLevel = 100; -- Moderators	--// The commands minimum admin level; This can also be a table containing specific levels rather than a minimum level: {124, 152, "HeadAdmins", etc};
		-- Alternative option: AdminLevel = "Moderators"
		Filter = true;									--// Should user-supplied text passed to this command be filtered automatically? Use this if you plan to display a user-defined message to other players
		Hidden = true;									--// Should this command be hidden from the command list?
		Disabled = true;								--// If set to true this command won't be usable.
		Function = function(plr: Player, args: {string}, data)	--// The command's function; This is the actual code of the command which runs when you run the command
			--// "plr" is the player running the command
			--// "args" is an array of strings containing command arguments supplied by the user
			--// "data" is a table containing information related to the command and the player running it, such as data.PlayerData.Level (the player's admin level) [Refer to API docs]
			print("This is 'arg1':", tostring(args[1]))
			print("This is 'arg2':", tostring(args[2]))
			print("This is 'etc'(arg 3):", tostring(args[3]))
			error("this is an example error :o !") --// Errors raised in the function during command execution will be displayed to the user.
		end
	};
}

settings.CommandCooldowns = {
--[[
	REFERENCE:
		command_full_name: The name of a command (e.g. :cmds)

	[command_full_name] = {
		Player = 0;
		Server = 0;
		Cross = 0;
	}
]]	
}

settings.FunCommands = true				-- Are fun commands enabled?
settings.PlayerCommands = true			-- Are player-level utility commands enabled?
settings.AgeRestrictedCommands = true	-- Are age-locked commands enabled?
settings.WarnDangerousCommand = false	-- Do dangerous commands ask for confirmation?
settings.CommandFeedback = false		-- Should players be notified when commands with non-obvious effects are run on them?
settings.CrossServerCommands = true		-- Are commands which affect more than one server enabled?
settings.ChatCommands = true			-- If false you will not be able to run commands via the chat; Instead, you MUST use the console or you will be unable to run commands
settings.CreatorPowers = true			-- Gives me creator-level admin; This is strictly used for debugging; I can't debug without full access to the script
settings.CodeExecution = true			-- Enables the use of code execution in Adonis; Scripting related (such as :s) and a few other commands require this
settings.SilentCommandDenials = false	-- If true, there will be no differences between the error messages shown when a user enters an invalid command and when they have insufficient permissions for the command
settings.OverrideChatCallbacks = true	-- If the TextChatService ShouldDeliverCallbacks of all channels are overridden by Adonis on load. Required for slowmode. Mutes use a CanSend method to mute when this is set to false.
settings.ChatCreateRobloxCommands = true	-- Whether "/" commands for Roblox should get created in new Chat

settings.BanMessage = "Banned"				-- Message shown to banned users upon kick
settings.LockMessage = "Not Whitelisted"	-- Message shown to people when they are kicked while the game is :slocked
settings.SystemTitle = "System Message"		-- Title to display in :sm and :bc

settings.MaxLogs = 5000			           -- Maximum logs to save before deleting the oldest
settings.SaveCommandLogs = true	           -- If command logs are saved to the datastores
settings.Notification = true	           -- Whether or not to show the "You're an admin" and "Updated" notifications
settings.SongHint = true		           -- Display a hint with the current song name and ID when a song is played via :music
settings.TopBarShift = false	           -- By default hints and notifications will appear from the top edge of the window. Set this to true if you don't want hints/notifications to appear in that region.
settings.DefaultTheme = "Default"		   -- Theme to be used as a replacement for "Default". The new replacement theme can still use "Default" as its Base_Theme however any other theme that references "Default" as its redirects to this theme.
settings.Messages = {}			           -- A list of notification messages to show HeadAdmins and above on join
settings.AutoClean = false		           -- Will auto clean workspace of things like hats and tools
settings.AutoCleanDelay = 60	           -- Time between auto cleans
settings.AutoBackup = false 	           -- Run :backupmap automatically when the server starts. To restore the map, run :restoremap
settings.ReJail = false			           -- If true then when a player rejoins they'll go back into jail. Or if the moderator leaves everybody gets unjailed
settings.DisableRejoinAtMaxPlayers = false -- If true, disables rejoin when max players is reached to avoid an exploit that allows more players than the max amount.

settings.Console = true				-- Whether the command console is enabled
settings.Console_AdminsOnly = false -- If true, only admins will be able to access the console

settings.HelpSystem = true		-- Allows players to call admins for help using !help
settings.HelpButton = true		-- Shows a little help button in the bottom right corner.
settings.HelpButtonImage = "rbxassetid://15129449173" -- Sets the image used for the Adonis help button above.


--------------------
-- DONOR SETTINGS --
--------------------

settings.DonorCapes = true 		-- Donors get to show off their capes; Not disruptive :)
settings.DonorCommands = true	-- Show your support for the script and let donors use harmless commands like !sparkles
settings.LocalCapes = false	 	-- Makes Donor capes local so only the donors see their cape [All players can still disable capes locally]


--------------------------
-- HTTP/TRELLO SETTINGS --
--------------------------

settings.HttpWait = 60					-- How long things that use the HttpService will wait before updating again
settings.Trello_Enabled = false			-- Are the Trello features enabled?
settings.Trello_Primary = ""			-- Primary Trello board
settings.Trello_Secondary = {}			-- Secondary Trello boards (read-only)		Format: {"BoardID";"BoardID2","etc"}
settings.Trello_AppKey = ""				-- Your Trello AppKey
settings.Trello_Token = ""				-- Trello token (DON'T SHARE WITH ANYONE!)    Get API key: /1/connect?name=Trello_API_Module&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE
settings.Trello_HideRanks = false		-- If true, Trello-assigned ranks won't be shown in the admins list UI (accessed via :admins)


---------------------
-- _G API SETTINGS --
---------------------

settings.G_API = true					-- If true, allows other server scripts to access certain functions described in the API module through _G.Adonis
settings.G_Access = false				-- If enabled, allows other scripts to access Adonis using _G.Adonis.Access; Scripts will still be able to do things like _G.Adonis.CheckAdmin(player)
settings.G_Access_Key = "Example_Key"	-- Key required to use the _G access API; Example_Key will not work for obvious reasons
settings.G_Access_Perms = "Read" 		-- Access perms
settings.Allowed_API_Calls = {
	Client = false;				-- Allow access to the Client (not recommended)
	Settings = false;			-- Allow access to settings (not recommended)
	DataStore = false;			-- Allow access to the DataStore (not recommended)
	Core = false;				-- Allow access to the script's core table (REALLY not recommended)
	Service = false;			-- Allow access to the script's service metatable
	Remote = false;				-- Communication table
	HTTP = false; 				-- HTTP-related things like Trello functions
	Anti = false;				-- Anti-Exploit table
	Logs = false;
	UI = false;					-- Client UI table
	Admin = false;				-- Admin related functions
	Functions = false;			-- Functions table (contains functions used by the script that don't have a subcategory)
	Variables = true;			-- Variables table
	API_Specific = true;		-- API Specific functions
}


---------------------------
-- ANTI-EXPLOIT SETTINGS --
---------------------------

--// IF YOU EXPERIENCE ISSUES WITH FALSE POSITIVES/RANDOM KICKING/CRASHING DISABLE ALL OF THESE!

settings.AllowClientAntiExploit = false 	-- (Default: false) Allows use of client-sided anti exploit functionality if true
settings.Detection = false					-- (Default: false) If true: enables built-in anti-exploit detections that do not have their own settings.
settings.CheckClients = true				-- (Default: true) 	Checks clients every minute or two to make sure they are still active.

settings.ExploitNotifications = true        -- (Default: true)	Notify all moderators and higher-ups when a player is kicked or crashed from the AntiExploit.
settings.CharacterCheckLogs = false			-- (Default: false)	If the character checks appear in exploit logs and exploit notifications.
settings.AntiNoclip = false					-- (Default: false)	Attempts to detect noclipping and kills the player if found.
settings.AntiRootJointDeletion = false		-- (Default: false)	Attempts to detect paranoid and kills the player if found.
settings.AntiMultiTool = false 				-- (Default: false)	Prevents multitool and because of that many other exploits.
settings.AntiGod = false 					-- (Default: false)	If a player does not respawn when they should have they get respawned.
-- settings.AntiHumanoidDeletion and settings.ProtectHats have been superseded Workspace.RejectCharacterDeletions.

settings.AntiSpeed = false 				-- (Default: false)	(Client-Sided) Attempts to detect speed exploits.
settings.AntiBuildingTools = false		-- (Default: false)	(Client-Sided) Attempts to detect any HopperBin(s)/Building Tools added to the client.
settings.AntiAntiIdle = false 			-- (Default: false)	(Client-Sided) Kick the player if they are using an anti-idle exploit. Highly useful for grinding/farming games.
settings.ExploitGuiDetection = false 	-- (Default: false)	(Client-Sided) If any exploit GUIs are found in the CoreGui the exploiter gets kicked (If you use StarterGui:SetCore("SendNotification") with an image this will kick you).


--[[ Message shown to banned users, each line is a new line, for example {
		"[Astra]";
		"";
		"You are banned!";
		"Reason: {reason}";
		"Time: {time}";
		"";
		"[Astra]";
	}
	
	The different placeholders you can use are
	{reason} - Shows the Ban Reason, if none is provided, it will show as "No Reason Provided"
	{time} - Shows the Time they were banned, in UTC time
	{name} - Shows the Player's name
	{id} - Shows the Player's UserId
	{moderator} - Shows the moderator who banned the Player
	{type} - Shows the type of ban, Can display: "TIMEBAN", "SERVERBAN", "GAMEBAN", "CONFIGBAN", "TRELLOBAN"
	{expiretime} - Shows the time a ban will expire, only applicable on a Timeban, else will return "Undefined" or "Permanent"
	{remainingtime} - Shows the remaining time on a Timeban, any other form of ban will return "Undefined" or "Permanent"
	
	Not up to date i still need to update this!
]]--

settings.CustomKickMessages = {
	BanMessage = { --// Shown if a player is server-banned in-game or databanned
		"";
		"▬▬▬▬ Astra ▬▬▬▬";
		"";
		"You are banned!";
		"Reason: {reason}";
		"Time: {time}";
		"Moderator: {moderator}";
		"";
		"▬▬▬▬ Technologies ▬▬▬▬";
	};		

	TrelloBanMessage = { --// Shown if a player is Trelobanned on a connected Trelo
		"";		
		"▬▬▬▬ Astra ▬▬▬▬";
		"";
		"You are Trello-Banned!";
		"Reason: {reason}";
		"Time: {time}";
		"";
		"▬▬▬▬ Technologies ▬▬▬▬";
	};	

	TimeBanMessage = {  --// Shown if a player is Timebanned in-game
		"";
		"▬▬▬▬ Astra ▬▬▬▬";
		"";
		"You are Timebanned!";
		"Reason: {reason}";
		"Time: {time}";
		"Expires: {expiretime}";
		"Time remaining: {remainingtime}";
		"";
		"▬▬▬▬ Technologies ▬▬▬▬";
	};

	GameBanMessage = { --// Shown if a player is banned in the `settings.Banned` table
		"";
		"▬▬▬▬ Astra ▬▬▬▬";
		"";
		"You are gamebanned!";
		"Reason: {reason}";
		"";
		"▬▬▬▬ Technologies ▬▬▬▬";
	};	
	
	KickMessage = { --// Shown if a player is banned in the `settings.Banned` table
		"";
		"▬▬▬▬ Astra ▬▬▬▬";
		"";
		"You were kicked by an admin!";
		"Reason: {reason}";
		"";
		"▬▬▬▬ Technologies ▬▬▬▬";
	};	
	ShutdownMessage = { --// Shown if a player is banned in the `settings.Banned` table
		"";
		"▬▬▬▬ Astra ▬▬▬▬";
		"";
		"Server Shutdown";
		"{reason}";
		"";
		"▬▬▬▬ Technologies ▬▬▬▬";
	};	

	FailedJoinFilter = { 
		"";
		"▬▬▬▬ Astra ▬▬▬▬";
		"";
		"You did not pass a Join Filter";
		"FILTER: {filter}";
		"ERROR: {error}";
		"";
		"▬▬▬▬ Technologies ▬▬▬▬";
		"";
	}		
}

---------------------
-- END OF SETTINGS --
---------------------

--// Setting descriptions used for the in-game settings editor;

descs.HideScript = [[ Disable if your game saves; When the game starts the Adonis_Loader model will be hidden so other scripts cannot access the settings module ]]
descs.DataStore = [[ DataStore the script will use for saving data; Changing this will lose any saved data ]]
descs.DataStoreKey = [[ Key used to encode all datastore entries; Changing this will lose any saved data ]]
descs.DataStoreEnabled = [[ Disable if you don't want settings and admins to be saveable in-game; PlayerData will still save ]]
descs.LocalDatastore = [[ If this is turned on, a mock DataStore will forcibly be used instead and shall never save across servers ]]

descs.Storage = [[ Where things like tools are stored ]]
descs.RecursiveTools = [[ Whether tools that are included in sub-containers within settings.Storage will be available via the :give command (useful if your tools are organized into multiple folders) ]]

descs.Theme = [[ UI theme; ]]
descs.MobileTheme = [[ Theme to use on mobile devices; Mobile themes are optimized for smaller screens; Some GUIs are disabled ]]

descs.Ranks = [[ All admin permission level ranks; ]];
descs.Moderators = [[ Mods; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.Admins = [[ Admins; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.HeadAdmins = [[ Head Admins; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.Creators = [[ Anyone to be identified as a place owner; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]

descs.Permissions = [[ Command permissions; Format: {"Command:NewLevel";} ]]
descs.Aliases = [[ Command aliases; Format: {[":alias <arg1> <arg2> ..."] = ":command <arg1> <arg2> ..."} ]]

descs.Commands = [[ Custom commands ]]
descs.Banned = [[ List of people banned from the game; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.Muted = [[ List of people muted; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.Blacklist = [[ List of people banned from using admin; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";}	]]
descs.Whitelist = [[ People who can join if whitelist enabled; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.MusicList = [[ List of songs to appear in the script; Format: {{Name = "somesong",ID = 1234567},{Name = "anotherone",ID = 1243562}} ]]
descs.CapeList = [[ List of capes; Format: {{Name = "somecape",Material = "Fabric",Color = "Bright yellow",ID = 12345567,Reflectance = 1},{etc more stuff here}} ]]
descs.InsertList = [[ List of models to appear in the script; Format: {{Name = "somemodel",ID = 1234567},{Name = "anotherone",ID = 1243562}} ]]
descs.Waypoints = [[ List of waypoints you can teleport via ':to wp-WAYPOINTNAME' or ':teleport PLAYER tp.WAYPOINTNAME' Format {YOURNAME1 = Vector3.new(1,2,3), YOURNAME2 = Vector(231,666,999)} ]]
descs.CustomRanks = [[ List of custom AdminLevel ranks			  Format: {RankName = {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";};} ]]

descs.SaveAdmins = [[ If true anyone you :mod, :admin, or :headadmin in-game will save]]
descs.LoadAdminsFromDS = [[ If false, any admins saved in your DataStores will not load ]]
descs.WhitelistEnabled = [[ If true enables the whitelist/server lock; Only lets admins & whitelisted users join ]]

descs.Prefix = [[ The : in :kill me ]]
descs.PlayerPrefix = [[ The ! in !donate; Mainly used for commands that any player can run ]]
descs.SpecialPrefix = [[ Used for things like "all", "me" and "others" (If changed to ! you would do :kill !me) ]]
descs.SplitKey = [[ The space in :kill me (eg if you change it to / :kill me would be :kill/me) ]]
descs.BatchKey = [[ :kill me | :ff bob | :explode scel ]]
descs.ConsoleKeyCode = [[ Keybind to open the console ]]

descs.HttpWait = [[ How long things that use the HttpService will wait before updating again ]]
descs.Trello_Enabled = [[ Are the Trello features enabled? ]]
descs.Trello_Primary = [[ Primary Trello board ]]
descs.Trello_Secondary = [[ Secondary Trello boards; Format: {"BoardID";"BoardID2","etc"} ]]
descs.Trello_AppKey = [[ Your Trello AppKey; ]]
descs.Trello_Token = [[ Trello token (DON'T SHARE WITH ANYONE!) ]]
descs.Trello_HideRanks = [[ If true, Trello-assigned ranks won't be shown in the admins list UI (accessed via :admins) ]]

descs.G_API = [[ If true, allows other server scripts to access certain functions described in the API module through _G.Adonis ]]
descs.G_Access = [[ If enabled, allows other scripts to access Adonis using _G.Adonis.Access; Scripts will still be able to do things like _G.Adonis.CheckAdmin(player) ]]
descs.G_Access_Key = [[ Key required to use the _G access API; Example_Key will not work for obvious reasons ]]
descs.G_Access_Perms = [[ Access perms level ]]
descs.Allowed_API_Calls = [[ Allowed calls ]]

descs.FunCommands = [[ Are fun commands enabled? ]]
descs.PlayerCommands = [[ Are players commands enabled? ]]
descs.AgeRestrictedCommands = [[ Are age-restricted commands enabled? ]]
descs.WarnDangerousCommand = [[ Do dangerous commands ask for confirmation before executing?]]
descs.CommandFeedback = [[ Should players be notified when commands with non-obvious effects are run on them? ]]
descs.CrossServerCommands = [[ Are commands which affect more than one server enabled? ]]
descs.ChatCommands = [[ If false you will not be able to run commands via the chat; Instead, you MUST use the console or you will be unable to run commands ]]
descs.SilentCommandDenials = [[ If true, there will be no differences between the error messages shown when a user enters an invalid command and when they have insufficient permissions for the command ]]
descs.OverrideChatCallbacks = [[ If the TextChatService ShouldDeliverCallbacks of all channels are overridden by Adonis on load. Required for muting ]]
descs.ChatCreateRobloxCommands = [[ Whether "/" commands for Roblox should get created in new Chat ]]

descs.BanMessage = [[ Message shown to banned users ]]
descs.LockMessage = [[ Message shown to people when they are kicked while the game is :slocked ]]
descs.SystemTitle = [[ Title to display in :sm ]]

descs.CreatorPowers = [[ Gives me creator-level admin; This is strictly used for debugging; I can't debug without access to the script and specific owner commands ]]
descs.MaxLogs = [[ Maximum logs to save before deleting the oldest; Too high can lag the game ]]
descs.SaveCommandLogs = [[ If command logs are saved to the datastores ]]
descs.Notification = [[ Whether or not to show the "You're an admin" and "Updated" notifications ]]
descs.CodeExecution = [[ Enables the use of code execution in Adonis; Scripting related and a few other commands require this ]]
descs.SongHint = [[ Display a hint with the current song name and ID when a song is played via :music ]]
descs.TopBarShift = [[ By default hints and notifs will appear from the top edge of the window. Set this to true if you don't want hints/notifications to appear in that region. ]]
descs.DefaultTheme = [[ Theme to be used as a replacement for "Default". The new replacement theme can still use "Default" as its Base_Theme however any other theme that references "Default" as its redirects to this theme. ]]
descs.ReJail = [[ If true then when a player rejoins they'll go back into jail. Or if the moderator leaves everybody gets unjailed ]]
descs.DisableRejoinAtMaxPlayers = [[ If true, disables rejoin when max players is reached to avoid an exploit that allows more players than the max amount. ]]

descs.Messages = [[ A list of notification messages to show HeadAdmins and above on join ]]

descs.AutoClean = [[ Will auto clean workspace of things like hats and tools ]]
descs.AutoBackup = [[ (not recommended) Run a map backup command when the server starts, this is mostly useless as clients cannot modify the server. To restore the map run :restoremap ]]
descs.AutoCleanDelay = [[ Time between auto cleans ]]

descs.CustomChat = [[ Custom chat ]]
descs.PlayerList = [[ Custom playerlist ]]

descs.Console = [[ Command console ]]
descs.Console_AdminsOnly = [[ Makes it so if the console is enabled, only admins will see it ]]

descs.DonorCommands = [[ Show your support for the script and let donors use commands like !sparkles ]]
descs.DonorCapes = [[ Determines if donors have capes ]]
descs.LocalCapes = [[ Makes Donor capes local instead of removing them ]]

descs.HelpSystem = [[ Allows players to call admins for help using !help ]]
descs.HelpButton = [[ Shows a little help button in the bottom right corner ]]
descs.HelpButtonImage = [[ Change this to change the help button's image ]]

descs.AllowClientAntiExploit = [[ Enables client-sided anti-exploit functionality ]]
descs.Detection = [[ (Extremely important, makes all protection systems work) A global toggle for all the other protection settings ]]
descs.CheckClients = [[ (Important, makes sure Adonis clients are connected to the server) Checks clients every minute or two to make sure they are still active ]]

descs.ExploitNotifications = [[ Notify all moderators and higher-ups when a player is kicked or crashed from the AntiExploit ]]
descs.CharacterCheckLogs = [[If the character checks appear in exploit logs and exploit notifications]]
descs.AntiNoclip = [[ Attempts to detect noclipping and kills the player if found ]]
descs.AntiRootJointDeletion = [[ Attempts to detect paranoid and kills the player if found ]]
descs.AntiMultiTool = [[ Prevents multitool and because of that many other exploits ]]
descs.AntiGod = [[ If a player does not respawn when they should have they get respawned ]]

descs.AntiSpeed = [[ (Client-Sided) Attempts to detect speed exploits ]]
descs.AntiBuildingTools = [[ (Client-Sided) Attempts to detect any HopperBin(s)/Building Tools added to the client ]]
descs.AntiAntiIdle = [[ (Client-Sided) Kick the player if they are using an anti-idle exploit. Highly useful for grinding/farming games ]]
descs.ExploitGuiDetection = [[ (Client-Sided) If any exploit GUIs are found in the CoreGui the exploiter gets kicked (If you use StarterGui:SetCore("SendNotification") with an image this will kick you) ]]

order = {
	"HideScript";
	"DataStore";
	"DataStoreKey";
	"DataStoreEnabled";
	"LocalDatastore";
	" ";
	"Storage";
	"RecursiveTools";
	" ";
	"Theme";
	"MobileTheme";
	" ";
	"Ranks";
	" ";
	"Permissions";
	"Aliases";
	" ";
	"Commands";
	"Banned";
	"Muted";
	"Blacklist";
	"Whitelist";
	"MusicList";
	"CapeList";
	"InsertList";
	"Waypoints";
	"CustomRanks";
	" ";
	"SaveAdmins";
	"WhitelistEnabled";
	" ";
	"Prefix";
	"PlayerPrefix";
	"SpecialPrefix";
	"SplitKey";
	"BatchKey";
	"ConsoleKeyCode";
	" ";
	"HttpWait";
	"Trello_Enabled";
	"Trello_Primary";
	"Trello_Secondary";
	"Trello_AppKey";
	"Trello_Token";
	"Trello_HideRanks";
	" ";
	"G_API";
	"G_Access";
	"G_Access_Key";
	"G_Access_Perms";
	"Allowed_API_Calls";
	" ";
	"FunCommands";
	"PlayerCommands";
	"AgeRestrictedCommands";
	"WarnDangerousCommand";
	"CommandFeedback";
	"CrossServerCommands";
	"ChatCommands";
	"CreatorPowers";
	"";
	"SilentCommandDenials";
	"OverrideChatCallbacks";
	"ChatCreateRobloxCommands";
	" ";
	"BanMessage";
	"LockMessage";
	"SystemTitle";
	" ";
	"MaxLogs";
	"SaveCommandLogs";
	"Notification";
	"SongHint";
	"TopBarShift";
	"DefaultTheme";
	"ReJail";
	"DisableRejoinAtMaxPlayers";
	"";
	"AutoClean";
	"AutoCleanDelay";
	"AutoBackup";
	" ";
	"CustomChat";
	"PlayerList";
	" ";
	"Console";
	"Console_AdminsOnly";
	" ";
	"HelpSystem";
	"HelpButton";
	"HelpButtonImage";
	" ";
	"DonorCommands";
	"DonorCapes";
	"LocalCapes";
	" ";
	"AllowClientAntiExploit";
	"Detection";
	"CheckClients";
	" ";
	"ExploitNotifications";
	"CharacterCheckLogs";
	"AntiNoclip";
	"AntiRootJointDeletion";
	"AntiMultiTool";
	"AntiGod";
	" ";
	"AntiSpeed";
	"AntiBuildingTools";
	"AntiAntiIdle";
	"ExploitGuiDetection";
}

return {Settings = settings, Descriptions = descs, Order = order}
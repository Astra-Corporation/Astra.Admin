--// Special Variables
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})

	local script = script
	local service = Vargs.Service
	local client = Vargs.Client

	local Anti, Core, Functions, Process, Remote, UI, Variables
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;

		Variables.Init = nil;
	end

	local function RunAfterLoaded()
		--// Get CodeName
		Variables.CodeName = Remote.Get("Variable", "CodeName")

		Variables.RunAfterLoaded = nil;
	end

	local function RunLast()
		Variables.RunLast = nil;
	end

	client.GUIs = {}
	client.GUIHolder = service.New("Folder")
	client.Variables = {
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		CodeName = "";
		UIKeepAlive = true;
		KeybindsEnabled = true;
		BuildInfo = {
			COMMIT = "";
			BRANCH = "";
			BUILD_DATE = = "";
		};
		ParticlesEnabled = true;
		ForceListsSelectable = true;
		EnableChatChannelTabs = false;
		CommandBoxonSpawn = true;
		EnableChatResize = false;
		CapesEnabled = true;
		HideChatCommands = false;
		Particles = {};
		UIColor1 = Color3.fromRGB(0,0,0);
		UIColor2 = Color3.fromRGB(0, 0, 128);
		KeyBinds = {};
		Aliases = {};
		Capes = {};
		savedUI = {};
		localSounds = {};
		ESPObjects = {};
		CommunicationsHistory = {};
		
		LightingSettings = {
			Ambient = service.Lighting.Ambient;
			Brightness = service.Lighting.Brightness;
			ColorShift_Bottom = service.Lighting.ColorShift_Bottom;
			ColorShift_Top = service.Lighting.ColorShift_Top;
			GlobalShadows = service.Lighting.GlobalShadows;
			OutdoorAmbient = service.Lighting.OutdoorAmbient;
			Outlines = service.Lighting.Outlines;
			ShadowColor = service.Lighting.ShadowColor;
			GeographicLatitude = service.Lighting.GeographicLatitude;
			Name = service.Lighting.Name;
			TimeOfDay = service.Lighting.TimeOfDay;
			FogColor = service.Lighting.FogColor;
			FogEnd = service.Lighting.FogEnd;
			FogStart = service.Lighting.FogStart;
		};
		
		KeycodeNames = require(service.UnWrap(client.Shared.KeycodeNames));
	};
end

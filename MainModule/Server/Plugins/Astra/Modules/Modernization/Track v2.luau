-- 8ch fixed this
-- Uncondoned...

return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Core = server.Core;
	local Deps = server.Deps;
	local Admin = server.Admin;
	local Process = server.Process;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local Logs = server.Logs;
	local Variables = server.Variables;
	local HTTP = server.HTTP;
	local Anti = server.Anti;

	local Players = game:GetService("Players");

	local TrackTable = Variables.TrackingTable;
	
	local TrackBeam = Deps:FindFirstChild("TrackBeam");
	local TrackGUI = Deps:FindFirstChild("TrackingGUI");

	Commands.Track.Function = function(plr: Player, args: { string })
		local ID = plr.UserId;
		local Char = plr.Character;

		if not Char then
			return;
		end;

		local Root = Char:FindFirstChild("HumanoidRootPart");

		if not Root then
			return;
		end;

		for _, player in service.GetPlayers(plr, args[1] or "me") do
			local _Char = player.Character;

			if not _Char then
				continue;
			end;

			local _Root = _Char:FindFirstChild("HumanoidRootPart");

			if not _Root then
				return;
			end;

			task.defer(function()
				local PlayerName = player.Name;

				local GUI = TrackGUI:Clone();

				local TrackerName = `{PlayerName}_Tracker`;

				GUI.Name = TrackerName;
				GUI.Adornee = _Root;
				GUI:FindFirstChild("Username").Text = PlayerName;
				GUI:FindFirstChild("Username").TextColor3 = player.TeamColor.Color
				local Attachment0 = Root:FindFirstChild("KronosTrackingAtt");

				if not Attachment0 then
					Attachment0 = service.New('Attachment');

					Attachment0.Name = "KronosTrackingAtt";
					Attachment0.Parent = Root;
				end;

				local Attachment1 = _Root:FindFirstChild("KronosTrackingAtt");

				if not Attachment1 then
					Attachment1 = service.New('Attachment');

					Attachment1.Name = "KronosTrackingAtt";
					Attachment1.Parent = _Root;
				end;

				local Beam = TrackBeam:Clone();

				Beam.Name = "TrackingBeam";
				Beam.Attachment0 = Attachment0;
				Beam.Attachment1 = Attachment1;
				Beam.Parent = GUI;
				Beam.Color = ColorSequence.new(player.TeamColor.Color);

				Remote.RemoveLocal(plr, TrackerName);
				Remote.MakeLocal(plr, GUI, false, true);

				local playerID = player.UserId;

				if not TrackTable[ID] then
					TrackTable[ID] = {};
				end;

				TrackTable[ID][playerID] = player;

				player.CharacterRemoving:Once(function()
					Remote.RemoveLocal(plr, TrackerName);

					TrackTable[ID][playerID] = nil;
				end);
			end);
		end;
	end;

	Players.PlayerAdded:Connect(function(player)
		local ID = player.UserId;

		if not TrackTable[ID] then
			TrackTable[ID] = {};
		end;

		player:GetPropertyChangedSignal("TeamColor"):Connect(function()
			local color = player.TeamColor.Color;

			for _, plr in Players:GetPlayers() do
				if TrackTable[plr.UserId][ID] then
					Commands.Track.Function(plr, { player.Name });
				end;
			end;
		end);

		player.CharacterAppearanceLoaded:Connect(function()
			for _, plr in TrackTable[ID] do
				Commands.Track.Function(player, { plr.Name });
			end;
		end);
	end);

	Commands.UnTrack.Function = function(plr: Player, args: { string })
		local ID = plr.UserId;

		for _, player in service.GetPlayers(plr,args[1] or "me") do
			task.defer(Remote.RemoveLocal, plr, `{player.Name}_Tracker`);

			TrackTable[ID][player.UserId] = nil;
		end;
	end;
end;
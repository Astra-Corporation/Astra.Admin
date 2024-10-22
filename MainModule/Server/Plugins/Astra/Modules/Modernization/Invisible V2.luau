return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service
	local Functions = server.Functions;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local HTTP = server.HTTP;


	Commands.Invisible.Function = function(plr: Player, args: { string })
		for _, v in service.GetPlayers(plr, args[1] or "me") do
			local Char = v.Character;

			if not Char then
				continue;
			end;

			for _, obj in v.Character:GetChildren() do
				if obj:IsA("BasePart") then
					obj.Transparency = 1;

					local Billboard = obj:FindFirstChildOfClass("BillboardGui");

					if Billboard then
						Billboard.Enabled = false
					end
					if obj:FindFirstChild("face") then
						obj.face.Transparency = 1;
					end;
				elseif obj:IsA("Accoutrement") and obj:FindFirstChild("Handle") then
					obj.Handle.Transparency = 1
				elseif obj:IsA("Tool") then
					for _, Descendant in obj:GetDescendants() do
						if Descendant:IsA("BasePart") or Descendant:IsA("Decal") or Descendant:IsA("UnionOperation") then
							Descendant:SetAttribute('OriginalTransparency',Descendant.Transparency)
							Descendant.Transparency = 1
						end
					end
				elseif obj:IsA("ForceField") then
					obj.Visible = false
				elseif obj.Name == "Head" then
					local face = obj:FindFirstChildOfClass("Decal");
					local rt = obj:FindFirstChildOfClass("BillboardGui");
					if face then
						face.Transparency = 1
					end
					if rt then
						rt.Enabled = false
					end
				end
			end
		end
	end

	Commands.Visible.Function = function(plr: Player, args: {string})
		for i, v in service.GetPlayers(plr, args[1]) do
			if v.Character then
				for a, obj in v.Character:GetChildren() do
					if obj:IsA("BasePart") and obj.Name~="HumanoidRootPart" then
						obj.Transparency = 0
						if obj:FindFirstChild("face") then
							obj.face.Transparency = 0
						elseif obj:FindFirstChildOfClass("BillboardGui") then
							obj:FindFirstChildOfClass("BillboardGui").Enabled = true
						end
					elseif obj:IsA("Accoutrement") and obj:FindFirstChild("Handle") then
						obj.Handle.Transparency = 0
					elseif obj:IsA("Tool") then
						for _, Descendant in obj:GetDescendants() do
							if Descendant:IsA("BasePart") or Descendant:IsA("Decal") or Descendant:IsA("UnionOperation") then
								local Transparency = Descendant:GetAttribute('OriginalTransparency') or 0
								Descendant.Transparency = Transparency
								Descendant:SetAttribute('OriginalTransparency',nil)
							end
						end
					elseif obj:IsA("ForceField") and obj.Name ~="ADONIS_FULLGOD" then
						obj.Visible = true
					elseif obj.Name == "Head" then
						local face = obj:FindFirstChildOfClass("Decal")
						if face then
							face.Transparency = 0
						end
					end
				end
			end
		end
	end

end;

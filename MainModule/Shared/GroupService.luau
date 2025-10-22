--// Author: 8ch99

local Players = game:GetService("Players")
local RealGroupService = game:GetService("GroupService")

--// @module GroupService

local GroupService = {}

function GroupService:GetPlayerRoleInGroup(Player, ID)
	--// player is nil OR player disconnected
	local Role = "Guest"
	if Player and Player:IsDescendantOf(Players) then
		local Success, FetchedRole = pcall(Player.GetRoleInGroup, Player, ID)
		if Success then
			Role = FetchedRole
		else
			warn(`GroupService: Failed to fetch player rank! Player: {Player}, Error message: {Role}`)
			Role = "Guest"
		end
	end
	return Role
end

function GroupService:GetPlayerRankInGroup(Player, ID)
	--// player is nil OR player disconnected
	local Rank = 0
	if Player and Player:IsDescendantOf(Players) then
		local Success, FetchedRank = pcall(Player.GetRankInGroup, Player, ID)
		if Success then
			Rank = FetchedRank
		else
			warn(`GroupService: Failed to fetch player rank! Player: {Player}, Error message: {Rank}`)
			Rank = 0
		end
	end
	return Rank
end

function GroupService:IsPlayerInGroup(Player, ID)
	return self:GetPlayerRankInGroup(Player, ID) ~= 0
end

function GroupService:GetGroupInfo(ID: number)
	local Success, GroupInfo = pcall(RealGroupService.GetGroupInfoAsync, RealGroupService, ID)
	if not Success then
		warn(`GroupService: Failed to fetch group info! Error message: {GroupInfo}`)
		return nil
	end
	return GroupInfo
end

function GroupService:GetGroupName(ID: number)
	local Info = self:GetGroupInfo(ID)
	if Info then
		return Info.Name
	end
end

function GroupService:GetGroupOwner(ID: number)
	local Info = self:GetGroupInfo(ID)
	if Info then
		return Info.Owner
	end
end

function GroupService:GetGroupEmblemUrl(ID: number)
	local Info = self:GetGroupInfo(ID)
	if Info then
		return Info.EmblemUrl
	end
end

function GroupService:GetGroupDescription(ID: number)
	local Info = self:GetGroupInfo(ID)
	if Info then
		return Info.Description
	end
end

function GroupService:GetGroupRoles(ID: number)
	local Info = self:GetGroupInfo(ID)
	if Info then
		return Info.Roles
	end
end

function GroupService:GetGroupRole(ID: number, Index: number)
	local Roles = self:GetGroupRoles(ID)
	if Roles then
		return Roles[Index]
	end
end

function GroupService:GetGroupRoleByName(ID, RoleName)
	for _, Role in self:GetGroupRoles(ID) do
		if Role.Name == RoleName then
			return Role
		end
	end
end

function GroupService:GetGroupRoleByRank(ID, Rank)
	for _, Role in self:GetGroupRoles(ID) do
		if Role.Rank == Rank then
			return Role
		end
	end
end

return GroupService

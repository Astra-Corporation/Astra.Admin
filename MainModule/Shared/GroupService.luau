--// Author: 8ch_32bit

local UpdateInterval = 60
local RealGroupService = game:GetService("GroupService")

--// Cache tables

local GroupInfoCache = {}
local PlayerGroupData = {}

--// Fetching functions

local function GetGroupInfo(GroupId)
	local GroupInfo = GroupInfoCache[GroupId]
	
	if GroupInfo then
		return GroupInfo
	end

	GroupInfo = RealGroupService:GetGroupInfoAsync(GroupId)
	GroupInfoCache[GroupId] = GroupInfo

	return GroupInfo
end

local function GetPlayerGroupData(Player: Player, GroupId)
	local GroupData = PlayerGroupData[GroupId]

	if not GroupData then
		GroupData = {}
		PlayerGroupData[GroupId] = GroupData
	end

	local Data = GroupData[Player]

	if Data then
		return Data
	end
	
	--[[if not Player:IsDescendantOf(game) then
		return
	end]]
	
	Data = {
		Role = Player:GetRoleInGroup(GroupId),
		Rank = Player:GetRankInGroup(GroupId),
	}
	
	GroupData[Player] = Data

	return Data
end

--// Begin GroupService

local GroupService = {}

--// Group info functions

function GroupService:GetGroupInfo(GroupId)
	return GetGroupInfo(GroupId)
end

function GroupService:GetGroupName(GroupId)
	return GetGroupInfo(GroupId).Name
end

function GroupService:GetGroupOwner(GroupId)
	return GetGroupInfo(GroupId).Owner
end

function GroupService:GetGroupEmblemUrl(GroupId)
	return GetGroupInfo(GroupId).EmblemUrl
end

function GroupService:GetGroupDescription(GroupId)
	return GetGroupInfo(GroupId).Description
end

--// Group roles functions

function GroupService:GetGroupRoles(GroupId)
	return GetGroupInfo(GroupId).Roles
end

function GroupService:GetGroupRole(GroupId, Index)
	return GetGroupInfo(GroupId).Roles[Index]
end

function GroupService:GetGroupRoleByName(GroupId, RoleName)
	for _, Role in self:GetGroupRoles(GroupId) do
		if Role.Name == RoleName then
			return Role
		end
	end
end

function GroupService:GetGroupRoleByRank(GroupId, Rank)
	for _, Role in self:GetGroupRoles(GroupId) do
		if Role.Rank == Rank then
			return Role
		end
	end
end

--// Player functions

function GroupService:GetPlayerRoleInGroup(Player, GroupId)
	return GetPlayerGroupData(Player, GroupId).Role
end

function GroupService:GetPlayerRankInGroup(Player, GroupId)
	return GetPlayerGroupData(Player, GroupId).Rank
end

function GroupService:IsPlayerInGroup(Player, GroupId)
	return self:GetPlayerRankInGroup(Player, GroupId) ~= 0
end

--// Updater thread
task.spawn(function()
	while true do
		task.wait(UpdateInterval)
		
		for GroupId in GroupInfoCache do
			GroupInfoCache[GroupId] = RealGroupService:GetGroupInfoAsync(GroupId)
		end
		
		for GroupId, GroupData in PlayerGroupData do
			for Player in GroupData do
				if Player.Parent == nil or not Player then
					GroupData[Player] = nil
					continue
				end

				GroupData[Player] = {
					Role = Player:GetRoleInGroup(GroupId),
					Rank = Player:GetRankInGroup(GroupId),
				}
			end
		end
	end
end)

return GroupService
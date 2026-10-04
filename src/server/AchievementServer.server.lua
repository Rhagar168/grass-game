local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AchievementConfig = require(ReplicatedStorage:WaitForChild("AchievementConfig"))

local claimEvent = ReplicatedStorage:FindFirstChild("ClaimAchievement") or Instance.new("RemoteEvent")
claimEvent.Name = "ClaimAchievement"
claimEvent.Parent = ReplicatedStorage

local function updateCounts(player)
	local claimed, claimable, total = 0, 0, 0
	for id, entry in pairs(AchievementConfig.ById) do
		total += 1
		if player:GetAttribute(AchievementConfig.ClaimAttribute(id)) == true then
			claimed += 1
		elseif AchievementConfig.IsComplete(player, entry) then
			claimable += 1
		end
	end
	player:SetAttribute("AchievementClaimedCount", claimed)
	player:SetAttribute("AchievementClaimableCount", claimable)
	player:SetAttribute("AchievementTotalCount", total)
end

local function setup(player)
	while player.Parent and player:GetAttribute("DataLoaded") ~= true do task.wait(0.1) end
	if not player.Parent then return end
	local watched = {}
	for id, entry in pairs(AchievementConfig.ById) do
		if not watched[entry.Attribute] then
			watched[entry.Attribute] = true
			player:GetAttributeChangedSignal(entry.Attribute):Connect(function() updateCounts(player) end)
		end
		player:GetAttributeChangedSignal(AchievementConfig.ClaimAttribute(id)):Connect(function() updateCounts(player) end)
	end
	updateCounts(player)
end

claimEvent.OnServerEvent:Connect(function(player, id)
	if player:GetAttribute("DataLoaded") ~= true or typeof(id) ~= "string" then return end
	local entry = AchievementConfig.ById[id]
	if not entry then return end
	local attribute = AchievementConfig.ClaimAttribute(id)
	if player:GetAttribute(attribute) == true then return end
	if not AchievementConfig.IsComplete(player, entry) then return end
	player:SetAttribute(attribute, true)
end)

Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player) end

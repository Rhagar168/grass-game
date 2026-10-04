local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementConfig = require(ReplicatedStorage:WaitForChild("AchievementConfig"))

local claimEvent = ReplicatedStorage:FindFirstChild("ClaimAchievement")
if not claimEvent then
	claimEvent = Instance.new("RemoteEvent")
	claimEvent.Name = "ClaimAchievement"
	claimEvent.Parent = ReplicatedStorage
end

local function recalculateBonuses(player)
	local totals = {
		Grass = 0,
		ResetTokens = 0,
		Backpack = 0,
		RareLuck = 0,
		XP = 0,
	}
	local claimedCount = 0
	local claimableCount = 0
	local totalCount = 0

	for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
		for _, entry in ipairs(AchievementConfig.Categories[categoryId].Entries) do
			totalCount += 1
			local claimed = player:GetAttribute(AchievementConfig.GetClaimAttribute(entry.Id)) == true
			if claimed then
				claimedCount += 1
				totals[entry.BonusType] += entry.Bonus
			elseif AchievementConfig.IsComplete(player, entry) then
				claimableCount += 1
			end
		end
	end

	player:SetAttribute("AchievementGrassMultiplier", 1 + totals.Grass)
	player:SetAttribute("AchievementResetTokenMultiplier", 1 + totals.ResetTokens)
	player:SetAttribute("AchievementBackpackMultiplier", 1 + totals.Backpack)
	player:SetAttribute("AchievementRareLuckMultiplier", 1 + totals.RareLuck)
	player:SetAttribute("AchievementXPMultiplier", 1 + totals.XP)
	player:SetAttribute("AchievementClaimedCount", claimedCount)
	player:SetAttribute("AchievementClaimableCount", claimableCount)
	player:SetAttribute("AchievementTotalCount", totalCount)
end

local function setupPlayer(player)
	while player.Parent and player:GetAttribute("DataLoaded") ~= true do
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end
	if not player.Parent then return end

	recalculateBonuses(player)

	local watched = {}
	for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
		for _, entry in ipairs(AchievementConfig.Categories[categoryId].Entries) do
			if not watched[entry.Attribute] then
				watched[entry.Attribute] = true
				player:GetAttributeChangedSignal(entry.Attribute):Connect(function()
					recalculateBonuses(player)
				end)
			end
		end
	end
end

claimEvent.OnServerEvent:Connect(function(player, achievementId)
	if player:GetAttribute("DataLoaded") ~= true then return end
	if typeof(achievementId) ~= "string" then return end

	local entry = AchievementConfig.ById[achievementId]
	if not entry then return end

	local claimAttribute = AchievementConfig.GetClaimAttribute(achievementId)
	if player:GetAttribute(claimAttribute) == true then return end
	if not AchievementConfig.IsComplete(player, entry) then return end

	player:SetAttribute(claimAttribute, true)
	recalculateBonuses(player)
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

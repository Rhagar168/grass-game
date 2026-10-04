local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

local MilestoneConfig = require(ReplicatedStorage:WaitForChild("MilestoneConfig"))
local ToolConfig = require(ReplicatedStorage:WaitForChild("ToolConfig"))
local AchievementConfig = require(ReplicatedStorage:WaitForChild("AchievementConfig"))
local claimAchievementEvent = ReplicatedStorage:WaitForChild("ClaimAchievement")

local bottomMenu = gui:WaitForChild("BottomMenu")
local openButton = bottomMenu:WaitForChild("ProfileButton")
local xpFrame = gui:FindFirstChild("XPFrame")

local menu = gui:WaitForChild("ProfileMenu")
local menuScale = menu:FindFirstChild("MenuScale")
local closeButton = menu:WaitForChild("TopBar"):WaitForChild("CloseButton")

local playerCard = menu:WaitForChild("PlayerCard")
local statsPanel = menu:WaitForChild("StatsPanel")

local profileTabs = menu:WaitForChild("ProfileTabs")
local profileTab = profileTabs:WaitForChild("ProfileTab")
local achievementsTab = profileTabs:WaitForChild("AchievementsTab")
local achievementsPanel = menu:WaitForChild("AchievementsPanel")
local categories = achievementsPanel:WaitForChild("Categories")

local ACTIVE_COLOR = Color3.fromRGB(48, 180, 82)
local ACTIVE_STROKE = Color3.fromRGB(75, 220, 105)
local INACTIVE_COLOR = Color3.fromRGB(35, 42, 45)
local INACTIVE_STROKE = Color3.fromRGB(58, 74, 79)
local HEADER_HEIGHT = 78
local openedCategory = nil
local avatar = playerCard:WaitForChild("Avatar")
local playerName = playerCard:WaitForChild("PlayerName")
local levelLabel = playerCard:WaitForChild("Level")
local equippedToolLabel = playerCard:WaitForChild("EquippedTool")

local content = statsPanel:WaitForChild("Content")

if not menuScale then
	menuScale = Instance.new("UIScale")
	menuScale.Name = "MenuScale"
	menuScale.Scale = 1
	menuScale.Parent = menu
end

local function valueLabel(rowName)
	return content:WaitForChild(rowName):WaitForChild("Value")
end

local grassCutLabel = valueLabel("GrassCut")
local resetsLabel = valueLabel("Resets")
local playtimeLabel = valueLabel("Playtime")
local coinsLabel = valueLabel("Coins")
local resetTokensLabel = valueLabel("ResetTokens")
local coinsMultiplierLabel = valueLabel("CoinsMultiplier")
local xpMultiplierLabel = valueLabel("XPMultiplier")
local damageMultiplierLabel = valueLabel("DamageMultiplier")
local capacityMultiplierLabel = valueLabel("CapacityMultiplier")

local function optionalValueLabel(rowName)
	local row = content:FindFirstChild(rowName)
	return row and row:FindFirstChild("Value")
end

local damageStatLabel = optionalValueLabel("DamageStat")
local critChanceStatLabel = optionalValueLabel("CritChanceStat")
local critDamageStatLabel = optionalValueLabel("CritDamageStat")
local cooldownStatLabel = optionalValueLabel("CooldownStat")
local radiusStatLabel = optionalValueLabel("RadiusStat")
local cutCountStatLabel = optionalValueLabel("CutCountStat")
local backpackStatLabel = optionalValueLabel("BackpackStat")
local instantBreakStatLabel = optionalValueLabel("InstantBreakStat")
local instantSellStatLabel = optionalValueLabel("InstantSellStat")

local function formatNumber(value)
	value = tonumber(value) or 0
	local absValue = math.abs(value)
	if absValue < 1000 then
		if value % 1 == 0 then return tostring(math.floor(value)) end
		return string.format("%.2f", value)
	end
	local suffixes = {"K","M","B","T","QA","QI","SX","SP","OC","NO","DC","UD","DD","TD","QAD","QID","SXD","SPD","OCD","NOD"}
	local tier = math.max(1, math.floor(math.log10(absValue) / 3))
	if tier <= #suffixes then
		return string.format("%.2f%s", value / (10 ^ (tier * 3)), suffixes[tier])
	end
	return string.format("%.2e", value):upper()
end

local function formatPlaytime(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	if hours > 0 then return string.format("%dh %02dm", hours, minutes) end
	return string.format("%dm", minutes)
end

local BASE_CUT_RADIUS = 4.5
local BASE_CUT_COUNT = 1
local BASE_CUT_COOLDOWN = 1

local function getToolUpgradeLevel(toolId, statName)
	return math.max(0, math.floor(player:GetAttribute("Tool_" .. toolId .. "_" .. statName .. "Level") or 0))
end

local function getToolStat(toolId, tool, statName)
	local upgrade = tool and tool.Upgrades and tool.Upgrades[statName]
	if not tool or not upgrade then return 0 end
	local level = math.min(getToolUpgradeLevel(toolId, statName), upgrade.MaxLevel)
	if statName == "Damage" then return tool.BaseDamage + level * upgrade.AmountPerLevel end
	if statName == "Cooldown" then return math.max(0.1, tool.BaseCooldown - level * upgrade.AmountPerLevel) end
	if statName == "Radius" then return tool.BaseRadius + level * upgrade.AmountPerLevel end
	if statName == "CutCount" then return tool.BaseCutCount + level * upgrade.AmountPerLevel end
	return 0
end

local function updateDetailedStats(toolId, tool, milestone)
	if not damageStatLabel then return end

	local toolDamage = getToolStat(toolId, tool, "Damage")
	local damage = (toolDamage + (player:GetAttribute("FlatDamageBonus") or 0))
		* (1 + (player:GetAttribute("PercentDamageBonus") or 0))
		* milestone.Damage

	local critChance = math.clamp((player:GetAttribute("CritChance") or 0) + milestone.CritChance, 0, 1)
	local critDamage = (player:GetAttribute("CritMultiplier") or 2) + milestone.CritDamage

	local toolCooldown = getToolStat(toolId, tool, "Cooldown")
	local cooldown = math.max(0.1, toolCooldown * ((player:GetAttribute("CutCooldown") or BASE_CUT_COOLDOWN) / BASE_CUT_COOLDOWN) * milestone.Cooldown)

	local toolRadius = getToolStat(toolId, tool, "Radius")
	local radius = (toolRadius + ((player:GetAttribute("CutRadius") or BASE_CUT_RADIUS) - BASE_CUT_RADIUS)) * milestone.Radius

	local toolCount = getToolStat(toolId, tool, "CutCount")
	local cutCount = math.max(1, math.floor(toolCount + ((player:GetAttribute("CutCount") or BASE_CUT_COUNT) - BASE_CUT_COUNT) + milestone.CutCount))

	damageStatLabel.Text = formatNumber(math.floor(damage * 10 + 0.5) / 10)
	critChanceStatLabel.Text = string.format("%.1f%%", critChance * 100)
	critDamageStatLabel.Text = string.format("x%.2f", critDamage)
	cooldownStatLabel.Text = string.format("%.2fs", cooldown)
	radiusStatLabel.Text = string.format("%.1f", radius)
	cutCountStatLabel.Text = tostring(cutCount)
	backpackStatLabel.Text = formatNumber(player:GetAttribute("GrassStored") or 0) .. " / " .. formatNumber(player:GetAttribute("BackpackCapacity") or 20)
	instantBreakStatLabel.Text = string.format("%.1f%%", math.clamp(player:GetAttribute("InstantBreakChance") or 0, 0, 1) * 100)
	instantSellStatLabel.Text = string.format("%.1f%%", math.clamp(player:GetAttribute("InstantSellChance") or 0, 0, 1) * 100)
end

local function getTotalResetCount()
	return player:GetAttribute("TotalResets") or 0
end

local function updateProfile()
	playerName.Text = player.DisplayName
	levelLabel.Text = "Level " .. tostring(player:GetAttribute("Level") or 1)

	local toolId = player:GetAttribute("EquippedTool") or "BasicScissors"
	local tool = ToolConfig.GetTool(toolId)
	equippedToolLabel.Text = (tool and tool.DisplayName) or toolId

	grassCutLabel.Text = formatNumber(player:GetAttribute("TotalGrassCut") or 0)
	resetsLabel.Text = formatNumber(getTotalResetCount())
	playtimeLabel.Text = formatPlaytime(player:GetAttribute("Playtime") or 0)
	coinsLabel.Text = formatNumber(player:GetAttribute("Coins") or 0)
	resetTokensLabel.Text = formatNumber(player:GetAttribute("ResetTokens") or 0)

	local milestone = MilestoneConfig.GetMultipliers(player)
	local percentCoins = player:GetAttribute("PercentCoinsBonus") or 0
	local xp = player:GetAttribute("XPMultiplier") or 1
	local percentDamage = player:GetAttribute("PercentDamageBonus") or 0
	local capacity = player:GetAttribute("BackpackCapacity") or 20

	coinsMultiplierLabel.Text = string.format("x%.2f", (1 + percentCoins) * milestone.Coins)
	xpMultiplierLabel.Text = string.format("x%.2f", xp * milestone.XP)
	damageMultiplierLabel.Text = string.format("x%.2f", (1 + percentDamage) * milestone.Damage)
	capacityMultiplierLabel.Text = string.format("x%.2f", capacity / 20)
	updateDetailedStats(toolId, tool, milestone)
end

local function setTabButton(button, active)
	button.BackgroundColor3 = active and ACTIVE_COLOR or INACTIVE_COLOR
	local stroke = button:FindFirstChild("Stroke")
	if stroke then
		stroke.Color = active and ACTIVE_STROKE or INACTIVE_STROKE
	end
end

local function showProfile()
	playerCard.Visible = true
	statsPanel.Visible = true
	achievementsPanel.Visible = false
	setTabButton(profileTab, true)
	setTabButton(achievementsTab, false)
end

local function showAchievements()
	updateAchievements()
	playerCard.Visible = false
	statsPanel.Visible = false
	achievementsPanel.Visible = true
	setTabButton(profileTab, false)
	setTabButton(achievementsTab, true)
end

profileTab.MouseButton1Click:Connect(showProfile)
achievementsTab.MouseButton1Click:Connect(showAchievements)

local function closeCategory(category)
	local categoryContent = category:FindFirstChild("Content")
	local arrow = category:FindFirstChild("Arrow")
	if categoryContent then categoryContent.Visible = false end
	category.Size = UDim2.new(1, -5, 0, HEADER_HEIGHT)
	if arrow then arrow.Rotation = 0 end
end

local function openCategory(category)
	local categoryContent = category:FindFirstChild("Content")
	local arrow = category:FindFirstChild("Arrow")
	if not categoryContent then return end
	categoryContent.Visible = true
	category.Size = UDim2.new(1, -5, 0, HEADER_HEIGHT + categoryContent.Size.Y.Offset + 8)
	if arrow then arrow.Rotation = 90 end
end

for _, category in ipairs(categories:GetChildren()) do
	if category:IsA("Frame") then
		local header = category:FindFirstChild("Header")
		if header and header:IsA("TextButton") then
			closeCategory(category)
			header.MouseButton1Click:Connect(function()
				if openedCategory == category then
					closeCategory(category)
					openedCategory = nil
					return
				end
				if openedCategory then closeCategory(openedCategory) end
				openCategory(category)
				openedCategory = category
			end)
		end
	end
end

local achievementConnectionsReady = false

local function formatAchievementNumber(value)
	value = tonumber(value) or 0
	if value >= 1e9 then return (string.format("%.2f", value / 1e9):gsub("%.?0+$", "")) .. "B" end
	if value >= 1e6 then return (string.format("%.2f", value / 1e6):gsub("%.?0+$", "")) .. "M" end
	if value >= 1e3 then return (string.format("%.2f", value / 1e3):gsub("%.?0+$", "")) .. "K" end
	return tostring(math.floor(value))
end

local function rewardText(entry)
	return "+" .. tostring(math.floor(entry.Bonus * 100 + 0.5)) .. "% " .. ({
		Grass = "GRASS",
		ResetTokens = "RESET TOKENS",
		Backpack = "BACKPACK",
		RareLuck = "RARE LUCK",
		XP = "XP",
	})[entry.BonusType]
end

local function updateAchievements()
	local claimedTotal = 0
	local total = 0

	for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
		local categoryData = AchievementConfig.Categories[categoryId]
		local categoryFrame = categories:FindFirstChild(categoryId)
		local claimedInCategory = 0

		if categoryFrame then
			local categoryContent = categoryFrame:FindFirstChild("Content")

			for index, entry in ipairs(categoryData.Entries) do
				total += 1
				local claimed = player:GetAttribute(AchievementConfig.GetClaimAttribute(entry.Id)) == true
				local complete = AchievementConfig.IsComplete(player, entry)
				if claimed then
					claimedTotal += 1
					claimedInCategory += 1
				end

				local row = categoryContent and categoryContent:FindFirstChild("Achievement_" .. index)
				if row then
					local title = row:FindFirstChild("Title")
					local progress = row:FindFirstChild("Progress")
					local reward = row:FindFirstChild("Reward")
					local status = row:FindFirstChild("Status")

					if title then title.Text = entry.Title end
					if reward then reward.Text = rewardText(entry) end

					local current, goal = AchievementConfig.GetProgress(player, entry)
					if progress then
						if entry.ProgressType == "Boolean" then
							progress.Text = complete and "UNLOCKED" or "LOCKED"
						else
							progress.Text = formatAchievementNumber(math.min(current, goal)) .. " / " .. formatAchievementNumber(goal)
						end
					end

					if status then
						if claimed then
							status.Text = "CLAIMED ✓"
							status.TextColor3 = Color3.fromRGB(75, 220, 105)
						elseif complete then
							status.Text = "CLAIM"
							status.TextColor3 = Color3.fromRGB(75, 220, 105)
						else
							status.Text = "LOCKED"
							status.TextColor3 = Color3.fromRGB(140, 150, 150)
						end
					end
				end
			end

			local completed = categoryFrame:FindFirstChild("Completed")
			if completed then
				completed.Text = tostring(claimedInCategory) .. " / " .. tostring(#categoryData.Entries)
			end
		end
	end

	local completionText = achievementsPanel:FindFirstChild("CompletionText")
	if completionText then
		completionText.Text = tostring(claimedTotal) .. " / " .. tostring(total) .. " COMPLETED"
	end
end

local function setupAchievementInteractions()
	if achievementConnectionsReady then return end
	achievementConnectionsReady = true

	local watchedProgressAttributes = {}

	for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
		local categoryData = AchievementConfig.Categories[categoryId]
		local categoryFrame = categories:FindFirstChild(categoryId)
		local categoryContent = categoryFrame and categoryFrame:FindFirstChild("Content")

		for index, entry in ipairs(categoryData.Entries) do
			local row = categoryContent and categoryContent:FindFirstChild("Achievement_" .. index)
			if row then
				row.Active = true
				row.InputBegan:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1
						and input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					if player:GetAttribute(AchievementConfig.GetClaimAttribute(entry.Id)) == true then return end
					if not AchievementConfig.IsComplete(player, entry) then return end
					claimAchievementEvent:FireServer(entry.Id)
				end)
			end

			if not watchedProgressAttributes[entry.Attribute] then
				watchedProgressAttributes[entry.Attribute] = true
				player:GetAttributeChangedSignal(entry.Attribute):Connect(updateAchievements)
			end

			player:GetAttributeChangedSignal(AchievementConfig.GetClaimAttribute(entry.Id)):Connect(updateAchievements)
		end
	end

	updateAchievements()
end

setupAchievementInteractions()

task.spawn(function()
	local ok, image = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	if ok then avatar.Image = image end
end)

local watchedAttributes = {
	"Level","EquippedTool","TotalGrassCut","TotalResets","Playtime","Coins","ResetTokens",
	"PercentCoinsBonus","XPMultiplier","PercentDamageBonus","BackpackCapacity",
	"PlainsResetCount","ForestResetCount","SavannaResetCount","JungleResetCount","TundraResetCount","VolcanoResetCount","BeachResetCount",
	"FlatDamageBonus","CritChance","CritMultiplier","CutCooldown","CutRadius","CutCount","GrassStored",
	"InstantBreakChance","InstantSellChance",
}

for _, attributeName in ipairs(watchedAttributes) do
	player:GetAttributeChangedSignal(attributeName):Connect(updateProfile)
end

task.spawn(function()
	while player.Parent do
		task.wait(1)
		if menu.Visible then
			local base = player:GetAttribute("Playtime") or 0
			playtimeLabel.Text = formatPlaytime(base)
		end
	end
end)

local function openMenu()
	updateProfile()
	showProfile()
	menu.Visible = true
	bottomMenu.Visible = false
	if xpFrame then xpFrame.Visible = false end
	player:SetAttribute("ProfileMenuOpen", true)
	menuScale.Scale = 0.9
	TweenService:Create(menuScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local function closeMenu()
	menu.Visible = false
	menuScale.Scale = 1
	bottomMenu.Visible = true
	if xpFrame then xpFrame.Visible = true end
	player:SetAttribute("ProfileMenuOpen", false)
end

openButton.MouseButton1Click:Connect(openMenu)
closeButton.MouseButton1Click:Connect(closeMenu)

menu.Visible = false
showProfile()
updateProfile()

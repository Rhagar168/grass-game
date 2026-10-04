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

local function createNotification(parent, name, position)
	local badge = parent:FindFirstChild(name)
	if not badge then
		badge = Instance.new("TextLabel")
		badge.Name = name
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = position
		badge.Size = UDim2.fromOffset(30, 34)
		badge.BackgroundTransparency = 1
		badge.Font = Enum.Font.GothamBlack
		badge.Text = "!"
		badge.TextColor3 = Color3.fromRGB(235, 55, 60)
		badge.TextScaled = true
		badge.TextStrokeColor3 = Color3.fromRGB(45, 12, 14)
		badge.TextStrokeTransparency = 0.1
		badge.ZIndex = parent.ZIndex + 20
		badge.Parent = parent
	end
	if not badge:GetAttribute("BounceStarted") then
		badge:SetAttribute("BounceStarted", true)
		local basePosition = badge.Position
		task.spawn(function()
			while badge.Parent do
				if badge.Visible then
					local up = UDim2.new(basePosition.X.Scale, basePosition.X.Offset, basePosition.Y.Scale, basePosition.Y.Offset - 5)
					local rise = TweenService:Create(badge, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = up})
					rise:Play()
					rise.Completed:Wait()
					if not badge.Parent then break end
					local fall = TweenService:Create(badge, TweenInfo.new(0.34, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Position = basePosition})
					fall:Play()
					fall.Completed:Wait()
					task.wait(0.65)
				else
					badge.Position = basePosition
					task.wait(0.2)
				end
			end
		end)
	end
	return badge
end

local profileNotification = createNotification(openButton, "AchievementNotification", UDim2.new(0.78, 0, 0.18, 0))
local achievementsNotification = createNotification(achievementsTab, "AchievementNotification", UDim2.new(1, -8, 0.5, 0))

local categoryNotifications = {}
for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
	local category = categories:FindFirstChild(categoryId)
	if category then
		categoryNotifications[categoryId] = createNotification(category, "ClaimNotification", UDim2.new(1, -12, 0, 39))
	end
end

local function updateAchievementNotifications()
	local claimable = tonumber(player:GetAttribute("AchievementClaimableCount")) or 0
	profileNotification.Visible = claimable > 0
	achievementsNotification.Visible = claimable > 0

	for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
		local badge = categoryNotifications[categoryId]
		if badge then
			local hasClaimable = false
			for _, entry in ipairs(AchievementConfig.Categories[categoryId].Entries) do
				if AchievementConfig.IsComplete(player, entry)
					and player:GetAttribute(AchievementConfig.ClaimAttribute(entry.Id)) ~= true then
					hasClaimable = true
					break
				end
			end
			badge.Visible = hasClaimable
		end
	end
end

local ACTIVE_COLOR = Color3.fromRGB(48, 180, 82)
local ACTIVE_STROKE = Color3.fromRGB(75, 220, 105)
local INACTIVE_COLOR = Color3.fromRGB(35, 42, 45)
local INACTIVE_STROKE = Color3.fromRGB(58, 74, 79)
local HEADER_HEIGHT = 78
local CATEGORY_OPEN_TIME = 0.28
local HOVER_TIME = 0.12
local CLAIMED_ROW_COLOR = Color3.fromRGB(24, 68, 42)
local CLAIMED_ROW_HOVER_COLOR = Color3.fromRGB(29, 80, 49)
local CATEGORY_SELECTED_COLOR = Color3.fromRGB(31, 55, 43)
local CATEGORY_HOVER_COLOR = Color3.fromRGB(28, 47, 39)
local openedCategory = nil
local lastTab = "Profile"
local updateAchievements
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

local function setHover(guiObject, normalColor, hoverColor)
	if not guiObject or not guiObject:IsA("GuiObject") then return end
	guiObject.MouseEnter:Connect(function()
		TweenService:Create(guiObject, TweenInfo.new(HOVER_TIME), {BackgroundColor3 = hoverColor}):Play()
	end)
	guiObject.MouseLeave:Connect(function()
		TweenService:Create(guiObject, TweenInfo.new(HOVER_TIME), {BackgroundColor3 = normalColor}):Play()
	end)
end

local function showProfile()
	lastTab = "Profile"
	playerCard.Visible = true
	statsPanel.Visible = true
	achievementsPanel.Visible = false
	setTabButton(profileTab, true)
	setTabButton(achievementsTab, false)
end

local function showAchievements()
	lastTab = "Achievements"
	if updateAchievements then updateAchievements() end
	playerCard.Visible = false
	statsPanel.Visible = false
	achievementsPanel.Visible = true
	setTabButton(profileTab, false)
	setTabButton(achievementsTab, true)
end

profileTab.MouseButton1Click:Connect(showProfile)
achievementsTab.MouseButton1Click:Connect(showAchievements)

local categoryTweens = {}

local function categoryTargetHeight(category)
	local categoryContent = category:FindFirstChild("Content")
	return HEADER_HEIGHT + (categoryContent and categoryContent.Size.Y.Offset or 0) + 8
end

local function tweenCategory(category, opening, instant)
	local categoryContent = category:FindFirstChild("Content")
	local arrow = category:FindFirstChild("Arrow")
	local header = category:FindFirstChild("Header")
	if not categoryContent then return end

	if categoryTweens[category] then categoryTweens[category]:Cancel() end
	if opening then categoryContent.Visible = true end

	local goal = {
		Size = UDim2.new(1, -5, 0, opening and categoryTargetHeight(category) or HEADER_HEIGHT),
		BackgroundColor3 = opening and CATEGORY_SELECTED_COLOR or INACTIVE_COLOR,
	}
	local info = TweenInfo.new(instant and 0 or CATEGORY_OPEN_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(category, info, goal)
	categoryTweens[category] = tween
	if arrow then
		TweenService:Create(arrow, info, {Rotation = opening and 90 or 0}):Play()
	end
	tween:Play()
	if not opening then
		tween.Completed:Connect(function()
			if openedCategory ~= category and categoryContent.Parent then categoryContent.Visible = false end
		end)
	end
	if header then
		header.BackgroundTransparency = opening and 0.82 or 1
	end
end

local function closeCategory(category, instant)
	tweenCategory(category, false, instant)
end

local function openCategory(category, instant)
	tweenCategory(category, true, instant)
end

for _, category in ipairs(categories:GetChildren()) do
	if category:IsA("Frame") then
		local header = category:FindFirstChild("Header")
		if header and header:IsA("TextButton") then
			closeCategory(category, true)
			header.MouseEnter:Connect(function()
				if openedCategory ~= category then
					TweenService:Create(category, TweenInfo.new(HOVER_TIME), {BackgroundColor3 = CATEGORY_HOVER_COLOR}):Play()
				end
			end)
			header.MouseLeave:Connect(function()
				if openedCategory ~= category then
					TweenService:Create(category, TweenInfo.new(HOVER_TIME), {BackgroundColor3 = INACTIVE_COLOR}):Play()
				end
			end)
			header.MouseButton1Click:Connect(function()
				if openedCategory == category then
					openedCategory = nil
					closeCategory(category)
					return
				end
				local previous = openedCategory
				openedCategory = category
				if previous then closeCategory(previous) end
				openCategory(category)
			end)
		end
	end
end

local function setupTabHover(button, tabName)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(HOVER_TIME), {BackgroundColor3 = Color3.fromRGB(43, 57, 60)}):Play()
	end)
	button.MouseLeave:Connect(function()
		local active = lastTab == tabName
		TweenService:Create(button, TweenInfo.new(HOVER_TIME), {BackgroundColor3 = active and ACTIVE_COLOR or INACTIVE_COLOR}):Play()
	end)
end
setupTabHover(profileTab, "Profile")
setupTabHover(achievementsTab, "Achievements")

updateAchievements = function()
	local claimedTotal = 0
	local total = 0
	for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
		local data = AchievementConfig.Categories[categoryId]
		local category = categories:FindFirstChild(categoryId)
		local categoryContent = category and category:FindFirstChild("Content")
		local claimedHere = 0
		for index, entry in ipairs(data.Entries) do
			total += 1
			local claimed = player:GetAttribute(AchievementConfig.ClaimAttribute(entry.Id)) == true
			local complete = AchievementConfig.IsComplete(player, entry)
			if claimed then claimedTotal += 1 claimedHere += 1 end
			local row = categoryContent and categoryContent:FindFirstChild("Achievement_" .. index)
			if row then
				local targetRowColor = claimed and CLAIMED_ROW_COLOR or Color3.fromRGB(8, 13, 14)
				if row.BackgroundColor3 ~= targetRowColor then
					TweenService:Create(row, TweenInfo.new(0.18), {BackgroundColor3 = targetRowColor}):Play()
				end
				local title = row:FindFirstChild("Title")
				local progress = row:FindFirstChild("Progress")
				local reward = row:FindFirstChild("Reward")
				local status = row:FindFirstChild("Status")
				if title then title.Text = entry.Title end
				if reward then reward.Text = entry.Reward end
				if progress then
					if entry.Goal == true then
						progress.Text = complete and "UNLOCKED" or "LOCKED"
					else
						local value = tonumber(player:GetAttribute(entry.Attribute)) or 0
						progress.Text = formatNumber(math.min(value, entry.Goal)) .. " / " .. formatNumber(entry.Goal)
					end
				end
				if status then
					status.Text = claimed and "CLAIMED ✓" or (complete and "CLAIM" or "LOCKED")
					status.TextColor3 = (claimed or complete) and Color3.fromRGB(75,220,105) or Color3.fromRGB(140,150,150)
				end
			end
		end
		local completed = category and category:FindFirstChild("Completed")
		if completed then
			completed.Text = tostring(claimedHere) .. " / " .. tostring(#data.Entries)
			completed.Position = UDim2.new(1, -88, completed.Position.Y.Scale, completed.Position.Y.Offset)
		end
		if category then
			local arrow = category:FindFirstChild("Arrow")
			if arrow then arrow.Position = UDim2.new(1, -46, arrow.Position.Y.Scale, arrow.Position.Y.Offset) end
			local rewardType = category:FindFirstChild("RewardType")
			if rewardType then rewardType.Position = UDim2.new(1, -72, rewardType.Position.Y.Scale, rewardType.Position.Y.Offset) end
		end
	end
	local completion = achievementsPanel:FindFirstChild("CompletionText")
	if completion then completion.Text = tostring(claimedTotal) .. " / " .. tostring(total) .. " COMPLETED" end
end

for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
	local data = AchievementConfig.Categories[categoryId]
	local category = categories:FindFirstChild(categoryId)
	local categoryContent = category and category:FindFirstChild("Content")
	for index, entry in ipairs(data.Entries) do
		local row = categoryContent and categoryContent:FindFirstChild("Achievement_" .. index)
		local status = row and row:FindFirstChild("Status")
		if row and row:IsA("GuiObject") then
			row.MouseEnter:Connect(function()
				local claimed = player:GetAttribute(AchievementConfig.ClaimAttribute(entry.Id)) == true
				TweenService:Create(row, TweenInfo.new(HOVER_TIME), {BackgroundColor3 = claimed and CLAIMED_ROW_HOVER_COLOR or Color3.fromRGB(17, 25, 26)}):Play()
			end)
			row.MouseLeave:Connect(function()
				local claimed = player:GetAttribute(AchievementConfig.ClaimAttribute(entry.Id)) == true
				TweenService:Create(row, TweenInfo.new(HOVER_TIME), {BackgroundColor3 = claimed and CLAIMED_ROW_COLOR or Color3.fromRGB(8, 13, 14)}):Play()
			end)
		end
		if row and row:IsA("GuiObject") then
			row.Active = true
			local clickCatcher = row:FindFirstChild("ClaimClick")
			if not clickCatcher then
				clickCatcher = Instance.new("TextButton")
				clickCatcher.Name = "ClaimClick"
				clickCatcher.BackgroundTransparency = 1
				clickCatcher.Text = ""
				clickCatcher.AutoButtonColor = false
				clickCatcher.Size = UDim2.fromScale(1, 1)
				clickCatcher.Position = UDim2.fromScale(0, 0)
				clickCatcher.ZIndex = row.ZIndex + 10
				clickCatcher.Parent = row
			end
			clickCatcher.MouseButton1Click:Connect(function()
				if AchievementConfig.IsComplete(player, entry) and player:GetAttribute(AchievementConfig.ClaimAttribute(entry.Id)) ~= true then
					claimAchievementEvent:FireServer(entry.Id)
				end
			end)
		end
		player:GetAttributeChangedSignal(entry.Attribute):Connect(function()
			updateAchievements()
			updateAchievementNotifications()
		end)
		player:GetAttributeChangedSignal(AchievementConfig.ClaimAttribute(entry.Id)):Connect(function()
			updateAchievements()
			updateAchievementNotifications()
		end)
	end
end

updateAchievements()
updateAchievementNotifications()
player:GetAttributeChangedSignal("AchievementClaimableCount"):Connect(updateAchievementNotifications)

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
	if lastTab == "Achievements" then
		showAchievements()
	else
		showProfile()
	end
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

local MilestoneConfig = require(ReplicatedStorage:WaitForChild("MilestoneConfig"))
local ToolConfig = require(ReplicatedStorage:WaitForChild("ToolConfig"))

local bottomMenu = gui:WaitForChild("BottomMenu")
local openButton = bottomMenu:WaitForChild("ProfileButton")
local xpFrame = gui:FindFirstChild("XPFrame")

local menu = gui:WaitForChild("ProfileMenu")
local menuScale = menu:FindFirstChild("MenuScale")
local closeButton = menu:WaitForChild("TopBar"):WaitForChild("CloseButton")

local playerCard = menu:WaitForChild("PlayerCard")
local avatar = playerCard:WaitForChild("Avatar")
local playerName = playerCard:WaitForChild("PlayerName")
local levelLabel = playerCard:WaitForChild("Level")
local equippedToolLabel = playerCard:WaitForChild("EquippedTool")

local content = menu:WaitForChild("StatsPanel"):WaitForChild("Content")

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
end

task.spawn(function()
	local ok, image = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	if ok then avatar.Image = image end
end)

local watchedAttributes = {
	"Level","EquippedTool","TotalGrassCut","TotalResets","Playtime","Coins","ResetTokens",
	"PercentCoinsBonus","XPMultiplier","PercentDamageBonus","BackpackCapacity",
	"PlainsResetCount","ForestResetCount","SavannaResetCount","JungleResetCount",
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
updateProfile()

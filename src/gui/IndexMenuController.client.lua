local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local GrassConfig = require(ReplicatedStorage:WaitForChild("GrassConfig"))

local bottomMenu = gui:WaitForChild("BottomMenu")
local openButton = bottomMenu:WaitForChild("IndexButton")
local xpFrame = gui:FindFirstChild("XPFrame")

local indexMenu = gui:WaitForChild("IndexMenu")
local menuScale = indexMenu:WaitForChild("MenuScale")
local closeButton = indexMenu:WaitForChild("TopBar"):WaitForChild("CloseButton")
local biomeList = indexMenu:WaitForChild("BiomeList")
local resetControls = grassList and nil -- assigned below
local grassList = indexMenu:WaitForChild("GrassList")
resetControls = grassList:WaitForChild("ResetControls")
local resetBox = resetControls:WaitForChild("ResetButton")
local minusButton = resetControls:WaitForChild("MinusButton")
local plusButton = resetControls:WaitForChild("PlusButton")

local selectedBiome = "Plains"
local previewReset = 0

local SELECTED = Color3.fromRGB(72, 170, 88)
local NORMAL = Color3.fromRGB(54, 61, 75)
local GOLD = Color3.fromRGB(255, 190, 35)
local RAINBOW = Color3.fromRGB(190, 105, 220)

local function formatNumber(value)
	value = tonumber(value) or 0
	local absValue = math.abs(value)
	if absValue >= 1e18 then return string.format("%.2fQi", value / 1e18) end
	if absValue >= 1e15 then return string.format("%.2fQa", value / 1e15) end
	if absValue >= 1e12 then return string.format("%.2fT", value / 1e12) end
	if absValue >= 1e9 then return string.format("%.2fB", value / 1e9) end
	if absValue >= 1e6 then return string.format("%.2fM", value / 1e6) end
	if absValue >= 1e3 then return string.format("%.2fK", value / 1e3) end
	if value % 1 == 0 then return tostring(math.floor(value)) end
	return string.format("%.1f", value)
end

local function updateBiomeButtons()
	for _, biomeId in ipairs(GrassConfig.BiomeOrder) do
		local button = biomeList:FindFirstChild(biomeId)
		if button and button:IsA("GuiButton") then
			button.BackgroundColor3 = biomeId == selectedBiome and SELECTED or NORMAL
		end
	end
end

local function updateGrassRows()
	for _, grassType in ipairs(GrassConfig.TypeOrder) do
		local row = grassList:FindFirstChild(grassType)
		if row then
			local nameLabel = row:FindFirstChild("GrassName")
			if nameLabel then
				nameLabel.Text = GrassConfig.Types[grassType].DisplayName
			end

			for _, rarity in ipairs(GrassConfig.RarityOrder) do
				local label = row:FindFirstChild(rarity .. "HP")
				if label and label:IsA("TextLabel") then
					local health = GrassConfig.GetHealth(selectedBiome, grassType, rarity, previewReset) or 0
					label.Text = rarity:upper() .. "                                      " .. formatNumber(health) .. " HP"
					if rarity == "Gold" then
						label.TextColor3 = GOLD
					elseif rarity == "Rainbow" then
						label.TextColor3 = RAINBOW
					else
						label.TextColor3 = Color3.fromRGB(235, 238, 245)
					end
				end
			end
		end
	end
end

local function setReset(value)
	previewReset = math.clamp(math.floor(tonumber(value) or 0), 0, 99)
	resetBox.Text = tostring(previewReset)
	updateGrassRows()
end

local function selectBiome(biomeId)
	if not GrassConfig.Biomes[biomeId] then return end
	selectedBiome = biomeId
	updateBiomeButtons()
	updateGrassRows()
end

local function openMenu()
	previewReset = math.max(0, math.floor(player:GetAttribute(selectedBiome .. "ResetCount") or 0))
	resetBox.Text = tostring(previewReset)
	updateBiomeButtons()
	updateGrassRows()

	indexMenu.Visible = true
	bottomMenu.Visible = false
	if xpFrame then xpFrame.Visible = false end
	player:SetAttribute("IndexMenuOpen", true)

	menuScale.Scale = 0.86
	TweenService:Create(
		menuScale,
		TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1}
	):Play()
end

local function closeMenu()
	indexMenu.Visible = false
	bottomMenu.Visible = true
	if xpFrame then xpFrame.Visible = true end
	player:SetAttribute("IndexMenuOpen", false)
end

for _, biomeId in ipairs(GrassConfig.BiomeOrder) do
	local button = biomeList:FindFirstChild(biomeId)
	if button and button:IsA("GuiButton") then
		button.MouseButton1Click:Connect(function()
			selectBiome(biomeId)
		end)
	end
end

openButton.MouseButton1Click:Connect(openMenu)
closeButton.MouseButton1Click:Connect(closeMenu)

minusButton.MouseButton1Click:Connect(function()
	setReset(previewReset - 1)
end)

plusButton.MouseButton1Click:Connect(function()
	setReset(previewReset + 1)
end)

resetBox.FocusLost:Connect(function()
	setReset(resetBox.Text)
end)

indexMenu.Visible = false
player:SetAttribute("IndexMenuOpen", false)
setReset(0)
selectBiome("Plains")

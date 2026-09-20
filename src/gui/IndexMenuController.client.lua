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
local grassList = indexMenu:WaitForChild("GrassList")
local resetControls = grassList:WaitForChild("ResetControls")
local resetBox = resetControls:WaitForChild("ResetButton")

-- The GUI was built with ResetButton as a TextButton.
-- Replace it at runtime with a TextBox so the player can type a reset number.
if not resetBox:IsA("TextBox") then
	local oldButton = resetBox
	local textBox = Instance.new("TextBox")
	textBox.Name = "ResetButton"
	textBox.AnchorPoint = oldButton.AnchorPoint
	textBox.Position = oldButton.Position
	textBox.Size = oldButton.Size
	textBox.BackgroundColor3 = oldButton.BackgroundColor3
	textBox.BackgroundTransparency = oldButton.BackgroundTransparency
	textBox.BorderSizePixel = oldButton.BorderSizePixel
	textBox.Text = oldButton.Text
	textBox.TextColor3 = oldButton.TextColor3
	textBox.TextTransparency = oldButton.TextTransparency
	textBox.TextSize = oldButton.TextSize
	textBox.TextScaled = oldButton.TextScaled
	textBox.Font = oldButton.Font
	textBox.ZIndex = oldButton.ZIndex
	textBox.ClearTextOnFocus = true
	textBox.Parent = resetControls

	for _, child in ipairs(oldButton:GetChildren()) do
		child:Clone().Parent = textBox
	end

	oldButton:Destroy()
	resetBox = textBox
else
	resetBox.ClearTextOnFocus = true
end

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

	if absValue < 1000 then
		if value % 1 == 0 then
			return tostring(math.floor(value))
		end
		return string.format("%.2f", value)
	end

	local suffixes = {
		"K", "M", "B", "T", "QA", "QI", "SX", "SP", "OC", "NO",
		"DC", "UD", "DD", "TD", "QAD", "QID", "SXD", "SPD", "OCD", "NOD",
	}

	local tier = math.floor(math.log10(absValue) / 3)
	tier = math.max(1, tier)

	if tier <= #suffixes then
		local scaled = value / (10 ^ (tier * 3))
		return string.format("%.2f%s", scaled, suffixes[tier])
	end

	-- Beyond named suffixes, keep the text compact instead of printing hundreds of digits.
	return string.format("%.2e", value):upper()
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
				local rarityLabel = row:FindFirstChild(rarity .. "Rarity")

				if label and label:IsA("TextLabel") then
					local health = GrassConfig.GetHealth(selectedBiome, grassType, rarity, previewReset) or 0
					label.Text = formatNumber(health) .. " HP"
					label.TextXAlignment = Enum.TextXAlignment.Right
				end

				if rarityLabel and rarityLabel:IsA("TextLabel") then
					rarityLabel.Text = rarity:upper()
					rarityLabel.TextXAlignment = Enum.TextXAlignment.Left

					if rarity == "Gold" then
						rarityLabel.TextColor3 = GOLD
					elseif rarity == "Rainbow" then
						rarityLabel.TextColor3 = RAINBOW
					else
						rarityLabel.TextColor3 = Color3.fromRGB(235, 238, 245)
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

resetBox:GetPropertyChangedSignal("Text"):Connect(function()
	local cleaned = resetBox.Text:gsub("%D", "")
	if cleaned ~= resetBox.Text then
		resetBox.Text = cleaned
	end
end)

resetBox.FocusLost:Connect(function()
	setReset(resetBox.Text)
end)

indexMenu.Visible = false
player:SetAttribute("IndexMenuOpen", false)
setReset(0)
selectBiome("Plains")

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local vegetationFolder = workspace:WaitForChild("Vegetation")

local BASE_GOLD_CHANCE = 0.01
local BASE_RAINBOW_CHANCE = 0.001
local BASE_GOLD_MULTIPLIER = 2
local BASE_RAINBOW_MULTIPLIER = 5

local GOLD_COLOR = Color3.fromRGB(255, 190, 35)
local GOLD_MATERIAL = Enum.Material.Metal
local RAINBOW_TWEEN_TIME = 1.6

local rainbowColors = {
	Color3.fromRGB(220, 95, 95),
	Color3.fromRGB(225, 155, 75),
	Color3.fromRGB(215, 195, 85),
	Color3.fromRGB(95, 190, 110),
	Color3.fromRGB(90, 155, 210),
	Color3.fromRGB(145, 105, 205),
	Color3.fromRGB(205, 105, 175),
}

local function getOwner(grass)
	local ownerUserId = grass:GetAttribute("OwnerUserId")
	if not ownerUserId then return nil end
	return Players:GetPlayerByUserId(ownerUserId)
end

local function startRainbowEffect(grass)
	task.spawn(function()
		local colorIndex = 1
		while grass.Parent do
			colorIndex += 1
			if colorIndex > #rainbowColors then colorIndex = 1 end

			local tween = TweenService:Create(
				grass,
				TweenInfo.new(RAINBOW_TWEEN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
				{Color = rainbowColors[colorIndex]}
			)
			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

local function applyRarity(grass)
	if not grass:IsA("BasePart") then return end
	if grass:GetAttribute("RarityRolled") then return end
	if not CollectionService:HasTag(grass, "Cuttable") then return end

	local player = getOwner(grass)

	-- Saved rare-grass upgrades must be recalculated before the first rarity roll.
	if player and player:GetAttribute("UpgradesReady") ~= true then
		task.spawn(function()
			local timeout = os.clock() + 15
			while grass.Parent and player.Parent and player:GetAttribute("UpgradesReady") ~= true and os.clock() < timeout do
				task.wait(0.05)
			end
			if grass.Parent then
				applyRarity(grass)
			end
		end)
		return
	end

	grass:SetAttribute("RarityRolled", true)

	local goldChance = BASE_GOLD_CHANCE
	local rainbowChance = BASE_RAINBOW_CHANCE
	local goldMultiplier = BASE_GOLD_MULTIPLIER
	local rainbowMultiplier = BASE_RAINBOW_MULTIPLIER

	if player then
		goldChance = player:GetAttribute("GoldGrassChance") or BASE_GOLD_CHANCE
		rainbowChance = player:GetAttribute("RainbowGrassChance") or BASE_RAINBOW_CHANCE
		goldMultiplier = player:GetAttribute("GoldGrassMultiplier") or BASE_GOLD_MULTIPLIER
		rainbowMultiplier = player:GetAttribute("RainbowGrassMultiplier") or BASE_RAINBOW_MULTIPLIER
	end

	goldChance = math.clamp(goldChance, 0, 1)
	rainbowChance = math.clamp(rainbowChance, 0, 1)

	local roll = math.random()

	if roll < rainbowChance then
		grass:SetAttribute("GrassRarity", "Rainbow")
		grass:SetAttribute("RewardMultiplier", rainbowMultiplier)
		grass.Material = Enum.Material.SmoothPlastic
		grass.Color = rainbowColors[1]
		startRainbowEffect(grass)
	elseif roll < rainbowChance + goldChance then
		grass:SetAttribute("GrassRarity", "Gold")
		grass:SetAttribute("RewardMultiplier", goldMultiplier)
		grass.Material = GOLD_MATERIAL
		grass.Color = GOLD_COLOR
	else
		grass:SetAttribute("GrassRarity", "Normal")
		grass:SetAttribute("RewardMultiplier", 1)

		local baseColor = grass:GetAttribute("BaseGrassColor")
		if typeof(baseColor) == "Color3" then
			grass.Color = baseColor
		end
	end
end

vegetationFolder.DescendantAdded:Connect(applyRarity)

for _, descendant in ipairs(vegetationFolder:GetDescendants()) do
	applyRarity(descendant)
end

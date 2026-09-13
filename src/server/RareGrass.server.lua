local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local vegetationFolder = workspace:WaitForChild("Vegetation")

-- Zakladni sance. Pozdeji je muzeme zvysovat upgrady pres atributy hrace.
local BASE_GOLD_CHANCE = 0.01 -- 1 %
local BASE_RAINBOW_CHANCE = 0.001 -- 0.1 %

-- Zakladni reward multipliery.
local GOLD_REWARD_MULTIPLIER = 2
local RAINBOW_REWARD_MULTIPLIER = 5

-- Jemnejsi vzhled bez Neonu.
local GOLD_COLOR = Color3.fromRGB(218, 165, 55)
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

	if not ownerUserId then
		return nil
	end

	return Players:GetPlayerByUserId(ownerUserId)
end

local function startRainbowEffect(grass)
	task.spawn(function()
		local colorIndex = 1

		while grass.Parent do
			colorIndex += 1

			if colorIndex > #rainbowColors then
				colorIndex = 1
			end

			local tween = TweenService:Create(
				grass,
				TweenInfo.new(
					RAINBOW_TWEEN_TIME,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.InOut
				),
				{
					Color = rainbowColors[colorIndex],
				}
			)

			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

local function applyRarity(grass)
	if not grass:IsA("BasePart") then
		return
	end

	if grass:GetAttribute("RarityRolled") then
		return
	end

	if not CollectionService:HasTag(grass, "Cuttable") then
		return
	end

	grass:SetAttribute("RarityRolled", true)

	local player = getOwner(grass)

	local goldChance = BASE_GOLD_CHANCE
	local rainbowChance = BASE_RAINBOW_CHANCE

	if player then
		goldChance = player:GetAttribute("GoldGrassChance") or BASE_GOLD_CHANCE
		rainbowChance = player:GetAttribute("RainbowGrassChance") or BASE_RAINBOW_CHANCE
	end

	goldChance = math.clamp(goldChance, 0, 1)
	rainbowChance = math.clamp(rainbowChance, 0, 1)

	-- Rainbow se losuje jako prvni, protoze je vzacnejsi.
	local roll = math.random()

	if roll < rainbowChance then
		grass:SetAttribute("GrassRarity", "Rainbow")
		grass:SetAttribute("RewardMultiplier", RAINBOW_REWARD_MULTIPLIER)
		grass.Material = Enum.Material.SmoothPlastic
		grass.Color = rainbowColors[1]
		startRainbowEffect(grass)

	elseif roll < rainbowChance + goldChance then
		grass:SetAttribute("GrassRarity", "Gold")
		grass:SetAttribute("RewardMultiplier", GOLD_REWARD_MULTIPLIER)
		grass.Material = Enum.Material.SmoothPlastic
		grass.Color = GOLD_COLOR

	else
		grass:SetAttribute("GrassRarity", "Normal")
		grass:SetAttribute("RewardMultiplier", 1)
	end
end

-- Nove spawnuta trava.
vegetationFolder.DescendantAdded:Connect(function(descendant)
	-- GrassSpawn nastavi tag jeste pred Parent, takze muzeme rarity vyhodnotit hned.
	applyRarity(descendant)
end)

-- Pro pripad, ze script nabehne az po casti spawnu.
for _, descendant in ipairs(vegetationFolder:GetDescendants()) do
	applyRarity(descendant)
end

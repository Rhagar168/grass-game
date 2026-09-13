local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local vegetationFolder = workspace:WaitForChild("Vegetation")

-- Zakladni sance. Pozdeji je muzeme zvysovat upgrady pres atributy hrace.
local BASE_GOLD_CHANCE = 0.01 -- 1 %
local BASE_RAINBOW_CHANCE = 0.001 -- 0.1 %

local GOLD_COLOR = Color3.fromRGB(255, 190, 35)
local RAINBOW_TWEEN_TIME = 1.2

local rainbowColors = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 170, 40),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 230, 100),
	Color3.fromRGB(70, 170, 255),
	Color3.fromRGB(150, 90, 255),
	Color3.fromRGB(255, 90, 210),
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
		grass.Material = Enum.Material.Neon
		grass.Color = rainbowColors[1]
		startRainbowEffect(grass)

	elseif roll < rainbowChance + goldChance then
		grass:SetAttribute("GrassRarity", "Gold")
		grass.Material = Enum.Material.Neon
		grass.Color = GOLD_COLOR

	else
		grass:SetAttribute("GrassRarity", "Normal")
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

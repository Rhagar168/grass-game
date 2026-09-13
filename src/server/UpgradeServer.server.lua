local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local purchaseEvent = ReplicatedStorage:WaitForChild("UpgradePurchase")
local UpgradeConfig = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))

local BASE_BACKPACK_CAPACITY = 20
local BASE_CUT_COOLDOWN = 1
local BASE_CUT_COUNT = 1
local BASE_CUT_RADIUS = 4.5
local BASE_CRIT_CHANCE = 0
local BASE_CRIT_MULTIPLIER = 2
local BASE_WALK_SPEED = 16
local BASE_GOLD_GRASS_CHANCE = 0.01
local BASE_RAINBOW_GRASS_CHANCE = 0.001
local BASE_GOLD_GRASS_MULTIPLIER = 2
local BASE_RAINBOW_GRASS_MULTIPLIER = 5

local function round1(n) return math.floor(n * 10 + 0.5) / 10 end
local function round2(n) return math.floor(n * 100 + 0.5) / 100 end
local function round3(n) return math.floor(n * 1000 + 0.5) / 1000 end
local function round4(n) return math.floor(n * 10000 + 0.5) / 10000 end
local function getBoughtAttribute(name) return name .. "Bought" end

local function applyWalkSpeed(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = player:GetAttribute("WalkSpeed") or BASE_WALK_SPEED end
end

local function recalculateUpgrades(player)
	local flatDamage, percentDamage = 0, 0
	local flatGrass, percentGrass = 0, 0
	local flatCoins, percentCoins = 0, 0
	local backpackCapacity = BASE_BACKPACK_CAPACITY
	local cooldownReduction, cutCountBonus, cutRadiusBonus = 0, 0, 0
	local critChanceBonus, critDamageBonus = 0, 0
	local instantSellChance, walkSpeedBonus, xpBonus = 0, 0, 0
	local instantBreakChance, sellMultiplierBonus = 0, 0
	local goldChanceBonus, rainbowChanceBonus = 0, 0
	local goldMultiplierBonus, rainbowMultiplierBonus = 0, 0

	for upgradeName, data in pairs(UpgradeConfig) do
		if player:GetAttribute(getBoughtAttribute(upgradeName)) == true then
			flatDamage += data.FlatDamage or 0
			percentDamage += data.PercentDamage or 0
			flatGrass += data.FlatGrass or 0
			percentGrass += data.PercentGrass or 0
			flatCoins += data.FlatCoins or 0
			percentCoins += data.PercentCoins or 0
			if data.BackpackCapacity then backpackCapacity = math.max(backpackCapacity, data.BackpackCapacity) end
			cooldownReduction += data.CutCooldownReduction or 0
			cutCountBonus += data.CutCountBonus or 0
			cutRadiusBonus += data.CutRadiusBonus or 0
			critChanceBonus += data.CritChanceBonus or 0
			critDamageBonus += data.CritDamageBonus or 0
			instantSellChance += data.InstantSellChance or 0
			instantBreakChance += data.InstantBreakChance or 0
			sellMultiplierBonus += data.SellMultiplierBonus or 0
			walkSpeedBonus += data.WalkSpeedBonus or 0
			xpBonus += data.XPBonus or 0
			goldChanceBonus += data.GoldGrassChanceBonus or 0
			rainbowChanceBonus += data.RainbowGrassChanceBonus or 0
			goldMultiplierBonus += data.GoldGrassMultiplierBonus or 0
			rainbowMultiplierBonus += data.RainbowGrassMultiplierBonus or 0
		end
	end

	-- Sell multiplier compounds with the normal coin-upgrade total while still using CuttingServer's existing PercentCoinsBonus.
	local effectivePercentCoins = (1 + percentCoins) * (1 + sellMultiplierBonus) - 1

	player:SetAttribute("FlatDamageBonus", flatDamage)
	player:SetAttribute("PercentDamageBonus", percentDamage)
	player:SetAttribute("FlatGrassBonus", flatGrass)
	player:SetAttribute("PercentGrassBonus", percentGrass)
	player:SetAttribute("FlatCoinsBonus", flatCoins)
	player:SetAttribute("PercentCoinsBonus", effectivePercentCoins)
	player:SetAttribute("BackpackCapacity", backpackCapacity)
	player:SetAttribute("CutCooldown", round3(math.max(0.1, BASE_CUT_COOLDOWN * (1 - cooldownReduction))))
	player:SetAttribute("CutCount", math.max(1, math.floor(BASE_CUT_COUNT + cutCountBonus)))
	player:SetAttribute("CutRadius", round1(BASE_CUT_RADIUS + cutRadiusBonus))
	player:SetAttribute("CritChance", math.clamp(BASE_CRIT_CHANCE + critChanceBonus, 0, 1))
	player:SetAttribute("CritMultiplier", math.max(1, BASE_CRIT_MULTIPLIER + critDamageBonus))
	player:SetAttribute("InstantSellChance", math.clamp(instantSellChance, 0, 1))
	player:SetAttribute("InstantBreakChance", math.clamp(instantBreakChance, 0, 1))
	player:SetAttribute("SellMultiplier", round2(1 + sellMultiplierBonus))

	local walkSpeed = BASE_WALK_SPEED + walkSpeedBonus
	player:SetAttribute("WalkSpeedBonus", walkSpeedBonus)
	player:SetAttribute("WalkSpeed", walkSpeed)
	applyWalkSpeed(player)
	player:SetAttribute("XPMultiplier", 1 + xpBonus)
	player:SetAttribute("GoldGrassChance", round4(math.clamp(BASE_GOLD_GRASS_CHANCE + goldChanceBonus, 0, 1)))
	player:SetAttribute("RainbowGrassChance", round4(math.clamp(BASE_RAINBOW_GRASS_CHANCE + rainbowChanceBonus, 0, 1)))
	player:SetAttribute("GoldGrassMultiplier", round2(BASE_GOLD_GRASS_MULTIPLIER + goldMultiplierBonus))
	player:SetAttribute("RainbowGrassMultiplier", round2(BASE_RAINBOW_GRASS_MULTIPLIER + rainbowMultiplierBonus))
end

purchaseEvent.OnServerEvent:Connect(function(player, upgradeName)
	if typeof(upgradeName) ~= "string" then return end
	local data = UpgradeConfig[upgradeName]
	if not data then warn("Upgrade not found:", upgradeName) return end
	local boughtAttribute = getBoughtAttribute(upgradeName)
	if player:GetAttribute(boughtAttribute) == true then return end
	if data.Requires and player:GetAttribute(getBoughtAttribute(data.Requires)) ~= true then return end
	local coins = player:GetAttribute("Coins") or 0
	local price = data.Price or 0
	if coins < price then return end
	player:SetAttribute("Coins", round2(coins - price))
	player:SetAttribute(boughtAttribute, true)
	recalculateUpgrades(player)
end)

local function setupPlayer(player)
	task.wait(1)
	recalculateUpgrades(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		task.wait()
		humanoid.WalkSpeed = player:GetAttribute("WalkSpeed") or BASE_WALK_SPEED
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setupPlayer, player) end

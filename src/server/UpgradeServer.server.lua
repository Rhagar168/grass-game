local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local purchaseEvent =
	ReplicatedStorage:WaitForChild("UpgradePurchase")

local UpgradeConfig = require(
	ReplicatedStorage:WaitForChild("UpgradeConfig")
)

-- ========================================
-- BASE VALUES
-- ========================================

local BASE_BACKPACK_CAPACITY = 20

local BASE_CUT_COOLDOWN = 1
local BASE_CUT_COUNT = 1
local BASE_CUT_RADIUS = 4.5

local BASE_CRIT_CHANCE = 0
local BASE_CRIT_MULTIPLIER = 2

local BASE_WALK_SPEED = 16

-- ========================================
-- ROUND
-- ========================================

local function round1(number)
	return math.floor(number * 10 + 0.5) / 10
end

local function round2(number)
	return math.floor(number * 100 + 0.5) / 100
end

local function round3(number)
	return math.floor(number * 1000 + 0.5) / 1000
end

-- ========================================
-- BOUGHT ATTRIBUTE
-- ========================================

local function getBoughtAttribute(upgradeName)
	return upgradeName .. "Bought"
end

-- ========================================
-- WALK SPEED
-- ========================================

local function applyWalkSpeed(player)

	local character =
		player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	local walkSpeed =
		player:GetAttribute("WalkSpeed")
		or BASE_WALK_SPEED

	humanoid.WalkSpeed =
		walkSpeed
end

-- ========================================
-- RECALCULATE
-- ========================================

local function recalculateUpgrades(player)

	-- DAMAGE

	local flatDamage = 0
	local percentDamage = 0

	-- GRASS

	local flatGrass = 0
	local percentGrass = 0

	-- COINS

	local flatCoins = 0
	local percentCoins = 0

	-- BACKPACK

	local backpackCapacity =
		BASE_BACKPACK_CAPACITY

	-- RED

	local cooldownReduction = 0
	local cutCountBonus = 0
	local cutRadiusBonus = 0

	local critChanceBonus = 0
	local critDamageBonus = 0

	-- BLUE

	local instantSellChance = 0
	local walkSpeedBonus = 0
	local xpBonus = 0

	-- ========================================
	-- CHECK BOUGHT UPGRADES
	-- ========================================

	for upgradeName, data in pairs(
		UpgradeConfig
		) do

		local bought =
			player:GetAttribute(
				getBoughtAttribute(upgradeName)
			) == true

		if bought then

			-- DAMAGE

			flatDamage +=
				data.FlatDamage or 0

			percentDamage +=
				data.PercentDamage or 0

			-- GRASS

			flatGrass +=
				data.FlatGrass or 0

			percentGrass +=
				data.PercentGrass or 0

			-- COINS

			flatCoins +=
				data.FlatCoins or 0

			percentCoins +=
				data.PercentCoins or 0

			-- BACKPACK

			if data.BackpackCapacity then

				backpackCapacity =
					math.max(
						backpackCapacity,
						data.BackpackCapacity
					)
			end

			-- CUT COOLDOWN

			cooldownReduction +=
				data.CutCooldownReduction or 0

			-- CUT COUNT

			cutCountBonus +=
				data.CutCountBonus or 0

			-- CUT RADIUS

			cutRadiusBonus +=
				data.CutRadiusBonus or 0

			-- CRIT CHANCE

			critChanceBonus +=
				data.CritChanceBonus or 0

			-- CRIT DAMAGE

			critDamageBonus +=
				data.CritDamageBonus or 0

			-- INSTANT SELL

			instantSellChance +=
				data.InstantSellChance or 0

			-- WALK SPEED

			walkSpeedBonus +=
				data.WalkSpeedBonus or 0

			-- XP

			xpBonus +=
				data.XPBonus or 0
		end
	end

	-- ========================================
	-- DAMAGE
	-- ========================================

	player:SetAttribute(
		"FlatDamageBonus",
		flatDamage
	)

	player:SetAttribute(
		"PercentDamageBonus",
		percentDamage
	)

	-- ========================================
	-- GRASS
	-- ========================================

	player:SetAttribute(
		"FlatGrassBonus",
		flatGrass
	)

	player:SetAttribute(
		"PercentGrassBonus",
		percentGrass
	)

	-- ========================================
	-- COINS
	-- ========================================

	player:SetAttribute(
		"FlatCoinsBonus",
		flatCoins
	)

	player:SetAttribute(
		"PercentCoinsBonus",
		percentCoins
	)

	-- ========================================
	-- BACKPACK
	-- ========================================

	player:SetAttribute(
		"BackpackCapacity",
		backpackCapacity
	)

	-- ========================================
	-- CUT COOLDOWN
	-- ========================================

	local cutCooldown =
		BASE_CUT_COOLDOWN
		* (1 - cooldownReduction)

	cutCooldown =
		math.max(
			0.1,
			cutCooldown
		)

	player:SetAttribute(
		"CutCooldown",
		round3(cutCooldown)
	)

	-- ========================================
	-- CUT COUNT
	-- ========================================

	local cutCount =
		BASE_CUT_COUNT
		+ cutCountBonus

	cutCount =
		math.max(
			1,
			math.floor(cutCount)
		)

	player:SetAttribute(
		"CutCount",
		cutCount
	)

	-- ========================================
	-- CUT RADIUS
	-- ========================================

	local cutRadius =
		BASE_CUT_RADIUS
		+ cutRadiusBonus

	player:SetAttribute(
		"CutRadius",
		round1(cutRadius)
	)

	-- ========================================
	-- CRIT CHANCE
	-- ========================================

	local critChance =
		BASE_CRIT_CHANCE
		+ critChanceBonus

	critChance =
		math.clamp(
			critChance,
			0,
			1
		)

	player:SetAttribute(
		"CritChance",
		critChance
	)

	-- ========================================
	-- CRIT DAMAGE
	-- ========================================

	local critMultiplier =
		BASE_CRIT_MULTIPLIER
		+ critDamageBonus

	critMultiplier =
		math.max(
			1,
			critMultiplier
		)

	player:SetAttribute(
		"CritMultiplier",
		critMultiplier
	)

	-- ========================================
	-- INSTANT SELL
	-- ========================================

	instantSellChance =
		math.clamp(
			instantSellChance,
			0,
			1
		)

	player:SetAttribute(
		"InstantSellChance",
		instantSellChance
	)

	-- ========================================
	-- WALK SPEED
	-- ========================================

	local walkSpeed =
		BASE_WALK_SPEED
		+ walkSpeedBonus

	player:SetAttribute(
		"WalkSpeedBonus",
		walkSpeedBonus
	)

	player:SetAttribute(
		"WalkSpeed",
		walkSpeed
	)

	applyWalkSpeed(player)

	-- ========================================
	-- XP BOOST
	-- ========================================

	local xpMultiplier =
		1 + xpBonus

	player:SetAttribute(
		"XPMultiplier",
		xpMultiplier
	)

	-- DEBUG
	-- print(
	-- 	player.Name,
	-- 	"Backpack:",
	-- 	backpackCapacity
	-- )
end

-- ========================================
-- PURCHASE
-- ========================================

purchaseEvent.OnServerEvent:Connect(
	function(player, upgradeName)

		if typeof(upgradeName) ~= "string" then
			return
		end

		local data =
			UpgradeConfig[upgradeName]

		if not data then
			warn(
				"Upgrade not found:",
				upgradeName
			)

			return
		end

		local boughtAttribute =
			getBoughtAttribute(
				upgradeName
			)

		-- už koupeno

		if player:GetAttribute(
			boughtAttribute
			) == true then

			return
		end

		-- prerequisite

		if data.Requires then

			local requiredAttribute =
				getBoughtAttribute(
					data.Requires
				)

			if player:GetAttribute(
				requiredAttribute
				) ~= true then

				return
			end
		end

		-- cena

		local coins =
			player:GetAttribute("Coins") or 0

		local price =
			data.Price or 0

		if coins < price then
			return
		end

		-- odebrání coinů

		player:SetAttribute(
			"Coins",
			round2(
				coins - price
			)
		)

		-- koupeno

		player:SetAttribute(
			boughtAttribute,
			true
		)

		-- přepočet

		recalculateUpgrades(
			player
		)
	end
)

-- ========================================
-- PLAYER SETUP
-- ========================================

local function setupPlayer(player)

	task.wait(1)

	recalculateUpgrades(
		player
	)

	player.CharacterAdded:Connect(
		function(character)

			local humanoid =
				character:WaitForChild(
					"Humanoid"
				)

			task.wait()

			local speed =
				player:GetAttribute(
					"WalkSpeed"
				) or BASE_WALK_SPEED

			humanoid.WalkSpeed =
				speed
		end
	)
end

Players.PlayerAdded:Connect(
	setupPlayer
)

for _, player in ipairs(
	Players:GetPlayers()
	) do

	task.spawn(
		setupPlayer,
		player
	)
end
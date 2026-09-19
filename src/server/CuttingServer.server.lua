local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local MilestoneConfig = require(ReplicatedStorage:WaitForChild("MilestoneConfig"))

-- ========================================
-- EVENTS
-- ========================================

local cutEvent =
	ReplicatedStorage:WaitForChild("CutVegetation")

local backpackFullEvent =
	ReplicatedStorage:WaitForChild("BackpackFull")

local progressEvent =
	ReplicatedStorage:WaitForChild("LocationProgressUpdate")

local grassGainEvent =
	ReplicatedStorage:WaitForChild("GrassGainPopup")

local instantSellPopupEvent =
	ReplicatedStorage:WaitForChild("InstantSellPopup")

local xpGainPopupEvent =
	ReplicatedStorage:WaitForChild("XPGainPopup")

local damagePopupEvent =
	ReplicatedStorage:WaitForChild("DamagePopup")

-- ========================================
-- SETTINGS
-- ========================================

local CUT_FORWARD = 2.5
local CUT_DOWN = 1.5

local BASE_CUT_RADIUS = 4.5
local BASE_CUT_COUNT = 1
local BASE_CUT_COOLDOWN = 1

local BASE_DAMAGE = 1

local PRICE_PER_GRASS = 0.1

-- XP
local BASE_XP_TO_LEVEL = 10
local XP_GROWTH = 1.35

local lastCut = {}

-- ========================================
-- ROUND
-- ========================================

local function round1(number)
	return math.floor(number * 10 + 0.5) / 10
end

local function round2(number)
	return math.floor(number * 100 + 0.5) / 100
end

-- ========================================
-- XP REQUIRED
-- ========================================

local function getXPRequired(level)

	local required =
		BASE_XP_TO_LEVEL
		* (XP_GROWTH ^ (level - 1))

	return math.floor(
		required + 0.5
	)
end

-- ========================================
-- GIVE XP
-- ========================================

local function giveXP(
	player,
	baseXP
)

	if baseXP <= 0 then
		return
	end

	local multiplier =
		player:GetAttribute(
			"XPMultiplier"
		) or 1

	local milestoneMultiplier = MilestoneConfig.GetMultipliers(player).XP

	local gainedXP =
		baseXP
		* multiplier
		* milestoneMultiplier

	gainedXP =
		round1(
			gainedXP
		)

	local xp =
		player:GetAttribute(
			"XP"
		) or 0

	local level =
		player:GetAttribute(
			"Level"
		) or 1

	local xpToNext =
		player:GetAttribute(
			"XPToNext"
		)

	if not xpToNext
		or xpToNext <= 0 then

		xpToNext =
			getXPRequired(
				level
			)
	end

	xp += gainedXP

	-- ========================================
	-- LEVEL UP
	-- ========================================

	while xp >= xpToNext do

		xp -= xpToNext

		level += 1

		xpToNext =
			getXPRequired(
				level
			)
	end

	xp =
		round1(
			xp
		)

	player:SetAttribute(
		"XP",
		xp
	)

	player:SetAttribute(
		"Level",
		level
	)

	player:SetAttribute(
		"XPToNext",
		xpToNext
	)

	-- XP POPUP

	xpGainPopupEvent:FireClient(
		player,
		gainedXP
	)
end

-- ========================================
-- CUT VALUES
-- ========================================

local function getCutRadius(player)

	local radius = player:GetAttribute(
		"CutRadius"
	) or BASE_CUT_RADIUS

	return radius * MilestoneConfig.GetMultipliers(player).Radius
end

local function getCutCount(player)

	local count =
		player:GetAttribute(
			"CutCount"
		) or BASE_CUT_COUNT

	count += MilestoneConfig.GetMultipliers(player).CutCount

	return math.max(
		1,
		math.floor(count)
	)
end

local function getCutCooldown(player)

	local cooldown = player:GetAttribute(
		"CutCooldown"
	) or BASE_CUT_COOLDOWN

	return math.max(0.1, cooldown * MilestoneConfig.GetMultipliers(player).Cooldown)
end

-- ========================================
-- DAMAGE
-- ========================================

local function getFinalDamage(player)

	local flatDamage =
		player:GetAttribute(
			"FlatDamageBonus"
		) or 0

	local percentDamage =
		player:GetAttribute(
			"PercentDamageBonus"
		) or 0

	local damage =
		(BASE_DAMAGE + flatDamage)
		* (1 + percentDamage)
		* MilestoneConfig.GetMultipliers(player).Damage

	damage =
		round1(
			damage
		)

	return math.max(
		0.1,
		damage
	)
end

-- ========================================
-- CRIT
-- ========================================

local function applyCrit(
	player,
	damage
)

	local critChance =
		player:GetAttribute(
			"CritChance"
		) or 0

	local milestoneMultipliers = MilestoneConfig.GetMultipliers(player)

	local critMultiplier =
		player:GetAttribute(
			"CritMultiplier"
		) or 2

	critChance += milestoneMultipliers.CritChance
	critMultiplier += milestoneMultipliers.CritDamage

	critChance =
		math.clamp(
			critChance,
			0,
			1
		)

	local isCrit =
		math.random()
		< critChance

	if isCrit then
		damage *= critMultiplier
	end

	damage =
		round1(
			damage
		)

	return damage, isCrit
end

-- ========================================
-- GRASS REWARD
-- ========================================

local function getFinalGrass(
	player,
	actualDamage
)

	local flatGrass =
		player:GetAttribute(
			"FlatGrassBonus"
		) or 0

	local percentGrass =
		player:GetAttribute(
			"PercentGrassBonus"
		) or 0

	local finalGrass =
		(actualDamage + flatGrass)
		* (1 + percentGrass)
		* MilestoneConfig.GetMultipliers(player).Grass

	finalGrass =
		round1(
			finalGrass
		)

	return math.max(
		0,
		finalGrass
	)
end

-- ========================================
-- COIN VALUE
-- ========================================

local function getPricePerGrass(player)

	local flatCoins =
		player:GetAttribute(
			"FlatCoinsBonus"
		) or 0

	local percentCoins =
		player:GetAttribute(
			"PercentCoinsBonus"
		) or 0

	return
		(PRICE_PER_GRASS + flatCoins)
		* (1 + percentCoins)
		* MilestoneConfig.GetMultipliers(player).Coins
end

-- ========================================
-- INSTANT SELL
-- ========================================

local function tryInstantSell(
	player,
	grassAmount
)

	local chance =
		player:GetAttribute(
			"InstantSellChance"
		) or 0

	chance =
		math.clamp(
			chance,
			0,
			1
		)

	if chance <= 0 then
		return false, 0
	end

	if math.random() >= chance then
		return false, 0
	end

	local earned =
		grassAmount
		* getPricePerGrass(
			player
		)

	earned =
		round2(
			earned
		)

	local coins =
		player:GetAttribute(
			"Coins"
		) or 0

	player:SetAttribute(
		"Coins",
		round2(
			coins + earned
		)
	)

	return true, earned
end

-- ========================================
-- GRASS PARTICLE
-- ========================================

local function createGrassPiece(
	position,
	color
)

	local piece =
		Instance.new("Part")

	piece.Name =
		"GrassClipping"

	piece.Size =
		Vector3.new(
			math.random(8, 15) / 100,
			math.random(50, 90) / 100,
			math.random(8, 15) / 100
		)

	piece.Color =
		color

	piece.Material =
		Enum.Material.SmoothPlastic

	piece.Anchored = false
	piece.CanCollide = false
	piece.CanTouch = false
	piece.CanQuery = false

	piece.Position =
		position
		+ Vector3.new(
			math.random(-8, 8) / 10,
			math.random(4, 12) / 10,
			math.random(-8, 8) / 10
		)

	piece.Orientation =
		Vector3.new(
			math.random(0, 360),
			math.random(0, 360),
			math.random(0, 360)
		)

	piece.Parent =
		workspace

	local attachment =
		Instance.new("Attachment")

	attachment.Parent =
		piece

	local force =
		Instance.new("VectorForce")

	force.Attachment0 =
		attachment

	force.RelativeTo =
		Enum.ActuatorRelativeTo.World

	force.Force =
		Vector3.new(
			0,

			piece.AssemblyMass
			* workspace.Gravity
			* 0.65,

			0
		)

	force.Parent =
		piece

	piece.AssemblyLinearVelocity =
		Vector3.new(
			math.random(-3, 3),
			math.random(8, 12),
			math.random(-3, 3)
		)

	piece.AssemblyAngularVelocity =
		Vector3.new(
			math.random(-6, 6),
			math.random(-6, 6),
			math.random(-6, 6)
		)

	Debris:AddItem(
		piece,
		4
	)
end

-- ========================================
-- CUT EFFECT
-- ========================================

local function playCutEffect(plant)

	for i = 1, 8 do

		createGrassPiece(
			plant.Position,
			plant.Color
		)
	end
end

-- ========================================
-- GIVE GRASS
-- ========================================

local function giveGrassToPlayer(
	player,
	grassAmount
)

	local stored =
		player:GetAttribute(
			"GrassStored"
		) or 0

	local capacity =
		(player:GetAttribute(
			"BackpackCapacity"
		) or 20)
		* MilestoneConfig.GetMultipliers(player).Backpack

	stored =
		round1(
			stored
		)

	grassAmount =
		round1(
			grassAmount
		)

	if stored >= capacity then
		return 0
	end

	local spaceLeft =
		capacity
	- stored

	local amountToGive =
		math.min(
			grassAmount,
			spaceLeft
		)

	amountToGive =
		round1(
			amountToGive
		)

	if amountToGive <= 0 then
		return 0
	end

	local newStored =
		round1(
			stored
			+ amountToGive
		)

	newStored =
		math.min(
			newStored,
			capacity
		)

	player:SetAttribute(
		"GrassStored",
		newStored
	)

	return amountToGive
end

-- ========================================
-- SHRINK
-- ========================================

local function shrinkPlant(
	plant,
	health,
	maxHealth
)

	local originalSize =
		plant:GetAttribute(
			"OriginalSize"
		)

	if not originalSize then

		originalSize =
			plant.Size

		plant:SetAttribute(
			"OriginalSize",
			originalSize
		)
	end

	local healthPercent = math.clamp(health / maxHealth, 0, 1)

	-- Visual size follows HP percentage, but only within a subtle range.
	-- 100% HP = 100% height, almost 0% HP = 65% height.
	local percentage = 0.65 + (0.35 * healthPercent)

	local targetSize =
		Vector3.new(
			originalSize.X,

			originalSize.Y
			* percentage,

			originalSize.Z
		)

	local bottomY =
		plant.Position.Y
	- plant.Size.Y / 2

	local targetPosition =
		Vector3.new(
			plant.Position.X,

			bottomY
			+ targetSize.Y / 2,

			plant.Position.Z
		)

	TweenService:Create(
		plant,

		TweenInfo.new(
			0.12,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{
			Size =
				targetSize,

			Position =
				targetPosition
		}
	):Play()
end

-- ========================================
-- DESTROY
-- ========================================

local function destroyPlant(plant)

	if not plant
		or not plant.Parent then

		return
	end

	local locationId =
		plant:GetAttribute(
			"LocationId"
		)

	local tween =
		TweenService:Create(
			plant,

			TweenInfo.new(
				0.15,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			),

			{
				Position =
				plant.Position
				- Vector3.new(
					0,
					plant.Size.Y,
					0
				),

				Transparency = 1
			}
		)

	tween:Play()

	tween.Completed:Connect(
		function()

			if not plant
				or not plant.Parent then

				return
			end

			local ownerUserId = plant:GetAttribute("OwnerUserId")
			local ownerPlayer = ownerUserId and Players:GetPlayerByUserId(ownerUserId)

			plant:Destroy()

			if locationId and ownerPlayer then
				local remainingAttribute = locationId .. "GrassRemaining"
				local resettingAttribute = locationId .. "Resetting"

				if ownerPlayer:GetAttribute(resettingAttribute) ~= true then
					local remaining = ownerPlayer:GetAttribute(remainingAttribute)
					if typeof(remaining) == "number" then
						local newRemaining = math.max(0, remaining - 1)
						ownerPlayer:SetAttribute(remainingAttribute, newRemaining)

						if newRemaining <= 0 then
							local unlockByBiome = {
								Plains = "ForestUnlocked",
								Forest = "SavannaUnlocked",
								Savanna = "JungleUnlocked",
							}

							local unlockAttribute = unlockByBiome[locationId]
							if unlockAttribute then
								ownerPlayer:SetAttribute(unlockAttribute, true)
							end
						end
					end
				end

				progressEvent:Fire(locationId, ownerPlayer)
			end
		end
	)
end

-- ========================================
-- CUT EVENT
-- ========================================

cutEvent.OnServerEvent:Connect(
	function(player)

		if player:GetAttribute(
			"UpgradeMenuOpen"
			) == true then

			return
		end

		-- ========================================
		-- COOLDOWN
		-- ========================================

		local now =
			os.clock()

		local cooldown =
			getCutCooldown(
				player
			)

		if lastCut[player]
			and now - lastCut[player]
			< cooldown then

			return
		end

		lastCut[player] =
			now

		-- ========================================
		-- CHARACTER
		-- ========================================

		local character =
			player.Character

		if not character then
			return
		end

		local root =
			character:FindFirstChild(
				"HumanoidRootPart"
			)

		if not root then
			return
		end

		-- ========================================
		-- BACKPACK
		-- ========================================

		local stored =
			player:GetAttribute(
				"GrassStored"
			) or 0

		local capacity =
			player:GetAttribute(
				"BackpackCapacity"
			) or 20

		if stored >= capacity then

			backpackFullEvent:FireClient(
				player
			)

			return
		end

		-- ========================================
		-- CUT VALUES
		-- ========================================

		local cutRadius =
			getCutRadius(
				player
			)

		local cutCount =
			getCutCount(
				player
			)

		local cutCenter =
			root.Position

			+ root.CFrame.LookVector
			* CUT_FORWARD

		- Vector3.new(
			0,
			CUT_DOWN,
			0
		)

		-- ========================================
		-- FIND PLANTS
		-- ========================================

		local candidates = {}

		for _, plant in ipairs(
			CollectionService:GetTagged(
				"Cuttable"
			)
			) do

			if not plant:IsA(
				"BasePart"
				) then

				continue
			end

			if not plant:IsDescendantOf(
				workspace
				) then

				continue
			end

			-- ========================================
			-- PERSONAL GRASS
			-- HRAC MUZE SEKAT JEN SVOJI TRAVU
			-- ========================================

			local ownerUserId =
				plant:GetAttribute(
					"OwnerUserId"
				)

			if ownerUserId
				~= player.UserId then

				continue
			end

			-- ========================================
			-- DESTROYING
			-- ========================================

			if plant:GetAttribute(
				"Destroying"
				) == true then

				continue
			end

			-- ========================================
			-- DISTANCE
			-- ========================================

			local distance =
				(
					plant.Position
					- cutCenter
				).Magnitude

			if distance <= cutRadius then

				table.insert(
					candidates,

					{
						plant =
							plant,

						distance =
							distance
					}
				)
			end
		end

		-- ========================================
		-- SORT NEAREST
		-- ========================================

		table.sort(
			candidates,

			function(a, b)

				return
					a.distance
					< b.distance
			end
		)

		local amount =
			math.min(
				#candidates,
				cutCount
			)

		-- ========================================
		-- DAMAGE PLANTS
		-- ========================================

		for i = 1, amount do

			local plant =
				candidates[i].plant

			if not plant
				or not plant.Parent then

				continue
			end

			-- ještě jednou bezpečnost

			if plant:GetAttribute(
				"OwnerUserId"
				) ~= player.UserId then

				continue
			end

			if plant:GetAttribute(
				"Destroying"
				) == true then

				continue
			end

			-- ========================================
			-- BACKPACK AGAIN
			-- ========================================

			stored =
				player:GetAttribute(
					"GrassStored"
				) or 0

			capacity =
				(player:GetAttribute(
					"BackpackCapacity"
				) or 20)
				* MilestoneConfig.GetMultipliers(player).Backpack

			if stored >= capacity then
				break
			end

			-- ========================================
			-- HEALTH
			-- ========================================

			local health =
				plant:GetAttribute(
					"Health"
				)

			if health == nil then
				health = 1
			end

			local maxHealth =
				plant:GetAttribute(
					"MaxHealth"
				)

			if maxHealth == nil then

				maxHealth =
					health

				plant:SetAttribute(
					"MaxHealth",
					maxHealth
				)
			end

			if not plant:GetAttribute(
				"OriginalSize"
				) then

				plant:SetAttribute(
					"OriginalSize",
					plant.Size
				)
			end

			-- ========================================
			-- DAMAGE + CRIT
			-- ========================================

			local baseDamage =
				getFinalDamage(
					player
				)

			local damageWithCrit,
			isCrit =
				applyCrit(
					player,
					baseDamage
				)

			local actualDamage =
				math.min(
					damageWithCrit,

					math.max(
						health,
						0
					)
				)

			-- Do not round damage before subtracting it from HP.
			-- Tiny remaining HP could round the final hit to 0.0 and leave grass immortal.
			health -=
				actualDamage

			if health < 0.001 then
				health = 0
			else
				health = math.max(0, health)
			end

			plant:SetAttribute(
				"Health",
				health
			)

			damagePopupEvent:FireClient(
				player,
				plant,
				actualDamage,
				isCrit
			)

			-- ========================================
			-- GRASS REWARD
			-- ========================================

			local finalGrass =
				getFinalGrass(
					player,
					actualDamage
				)

			-- ========================================
			-- SPECIAL GRASS MULTIPLIER
			-- pozdeji Gold / Rainbow
			-- ========================================

			local rewardMultiplier =
				plant:GetAttribute(
					"RewardMultiplier"
				) or 1

			finalGrass *=
				rewardMultiplier

			finalGrass =
				round1(
					finalGrass
				)

			-- ========================================
			-- INSTANT SELL
			-- ========================================

			local instantSold,
			earnedCoins =
				tryInstantSell(
					player,
					finalGrass
				)

			if instantSold then

				instantSellPopupEvent:FireClient(
					player,
					earnedCoins,
					finalGrass
				)

			else

				local gainedGrass =
					giveGrassToPlayer(
						player,
						finalGrass
					)

				if gainedGrass > 0 then

					grassGainEvent:FireClient(
						player,
						gainedGrass
					)
				end
			end

			-- ========================================
			-- EFFECT
			-- ========================================

			playCutEffect(
				plant
			)

			-- ========================================
			-- SHRINK / DESTROY / XP
			-- ========================================

			if health > 0 then

				shrinkPlant(
					plant,
					health,
					maxHealth
				)

			else

				plant:SetAttribute(
					"Destroying",
					true
				)

				local xpReward =
					plant:GetAttribute(
						"XPReward"
					) or 1

				giveXP(
					player,
					xpReward
				)

				destroyPlant(
					plant
				)
			end
		end
	end
)

-- ========================================
-- CLEANUP
-- ========================================

Players.PlayerRemoving:Connect(
	function(player)

		lastCut[player] = nil
	end
)
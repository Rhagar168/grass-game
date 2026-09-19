local MilestoneConfig = {}

MilestoneConfig.Biomes = {
	Plains = {
		[1] = {Title = "Grass Boost", BonusText = "1.5x Grass", GrassMultiplier = 1.5},
		[2] = {Title = "Sharper Cuts", BonusText = "1.5x Damage", DamageMultiplier = 1.5},
		[3] = {Title = "Wider Swing", BonusText = "1.25x Cut Radius", RadiusMultiplier = 1.25},
		[4] = {Title = "Better Sales", BonusText = "1.5x Coins", CoinsMultiplier = 1.5},
		[5] = {Title = "Bigger Backpack", BonusText = "1.25x Backpack", BackpackMultiplier = 1.25},
		[6] = {Title = "Quick Cuts", BonusText = "10% Faster Cuts", CooldownMultiplier = 0.9},
		[7] = {Title = "Fast Learner", BonusText = "1.5x XP", XPMultiplier = 1.5},
		[8] = {Title = "Golden Fields", BonusText = "2x Gold Chance", GoldChanceMultiplier = 2},
		[9] = {Title = "Rainbow Fields", BonusText = "2x Rainbow Chance", RainbowChanceMultiplier = 2},
		[10] = {Title = "Plains Mastery", BonusText = "+1 Cut Count", CutCountBonus = 1},
	},

	Forest = {
		[1] = {Title = "Heavy Blades", BonusText = "1.5x Damage", DamageMultiplier = 1.5},
		[2] = {Title = "Forest Pack", BonusText = "1.25x Backpack", BackpackMultiplier = 1.25},
		[3] = {Title = "Forest Reach", BonusText = "1.3x Cut Radius", RadiusMultiplier = 1.3},
		[4] = {Title = "Hunter Instinct", BonusText = "+5% Crit Chance", CritChanceBonus = 0.05},
		[5] = {Title = "Wild Growth", BonusText = "2x Grass", GrassMultiplier = 2},
		[6] = {Title = "Brutal Crits", BonusText = "+50% Crit Damage", CritDamageBonus = 0.5},
		[7] = {Title = "Forest Wisdom", BonusText = "1.75x XP", XPMultiplier = 1.75},
		[8] = {Title = "Golden Grove", BonusText = "2.5x Gold Chance", GoldChanceMultiplier = 2.5},
		[9] = {Title = "Swift Hunter", BonusText = "15% Faster Cuts", CooldownMultiplier = 0.85},
		[10] = {Title = "Forest Mastery", BonusText = "+1 Cut Count", CutCountBonus = 1},
	},

	Savanna = {
		[1] = {Title = "Dry Harvest", BonusText = "1.75x Grass", GrassMultiplier = 1.75},
		[2] = {Title = "Savanna Trade", BonusText = "1.5x Coins", CoinsMultiplier = 1.5},
		[3] = {Title = "Quick Pounce", BonusText = "10% Faster Cuts", CooldownMultiplier = 0.9},
		[4] = {Title = "Predator Instinct", BonusText = "+10% Crit Chance", CritChanceBonus = 0.10},
		[5] = {Title = "Great Harvest", BonusText = "2x Grass", GrassMultiplier = 2},
		[6] = {Title = "Predator Crits", BonusText = "+75% Crit Damage", CritDamageBonus = 0.75},
		[7] = {Title = "Travel Pack", BonusText = "1.5x Backpack", BackpackMultiplier = 1.5},
		[8] = {Title = "Golden Sun", BonusText = "3x Gold Chance", GoldChanceMultiplier = 3},
		[9] = {Title = "Rainbow Mirage", BonusText = "2.5x Rainbow Chance", RainbowChanceMultiplier = 2.5},
		[10] = {Title = "Savanna Mastery", BonusText = "+1 Cut Count", CutCountBonus = 1},
	},

	Jungle = {
		[1] = {Title = "Machete Power", BonusText = "2x Damage", DamageMultiplier = 2},
		[2] = {Title = "Expedition Pack", BonusText = "1.5x Backpack", BackpackMultiplier = 1.5},
		[3] = {Title = "Vine Sweep", BonusText = "1.4x Cut Radius", RadiusMultiplier = 1.4},
		[4] = {Title = "Jungle Instinct", BonusText = "+15% Crit Chance", CritChanceBonus = 0.15},
		[5] = {Title = "Overgrowth", BonusText = "2.5x Grass", GrassMultiplier = 2.5},
		[6] = {Title = "Relentless Cuts", BonusText = "15% Faster Cuts", CooldownMultiplier = 0.85},
		[7] = {Title = "Ancient Knowledge", BonusText = "2.25x XP", XPMultiplier = 2.25},
		[8] = {Title = "Savage Crits", BonusText = "+100% Crit Damage", CritDamageBonus = 1},
		[9] = {Title = "Prismatic Temple", BonusText = "3x Rainbow Chance", RainbowChanceMultiplier = 3},
		[10] = {Title = "Jungle Mastery", BonusText = "+1 Cut Count", CutCountBonus = 1},
	},
}

function MilestoneConfig.GetMultipliers(player)
	local result = {
		Grass = 1,
		Damage = 1,
		Radius = 1,
		Coins = 1,
		XP = 1,
		GoldChance = 1,
		RainbowChance = 1,
		CutCount = 0,
		Backpack = 1,
		Cooldown = 1,
		CritChance = 0,
		CritDamage = 0,
	}

	for biomeId, milestones in pairs(MilestoneConfig.Biomes) do
		local resetCount = math.clamp(player:GetAttribute(biomeId .. "ResetCount") or 0, 0, #milestones)

		for index = 1, resetCount do
			local milestone = milestones[index]
			if milestone then
				result.Grass *= milestone.GrassMultiplier or 1
				result.Damage *= milestone.DamageMultiplier or 1
				result.Radius *= milestone.RadiusMultiplier or 1
				result.Coins *= milestone.CoinsMultiplier or 1
				result.XP *= milestone.XPMultiplier or 1
				result.GoldChance *= milestone.GoldChanceMultiplier or 1
				result.RainbowChance *= milestone.RainbowChanceMultiplier or 1
				result.CutCount += milestone.CutCountBonus or 0
				result.Backpack *= milestone.BackpackMultiplier or 1
				result.Cooldown *= milestone.CooldownMultiplier or 1
				result.CritChance += milestone.CritChanceBonus or 0
				result.CritDamage += milestone.CritDamageBonus or 0
			end
		end
	end

	return result
end

return MilestoneConfig

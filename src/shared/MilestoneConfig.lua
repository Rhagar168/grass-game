local MilestoneConfig = {}

MilestoneConfig.Biomes = {
	Plains = {
		[1] = {Title = "Grass Boost", BonusText = "1.5x Grass", GrassMultiplier = 1.5},
		[2] = {Title = "Sharper Cuts", BonusText = "1.5x Damage", DamageMultiplier = 1.5},
		[3] = {Title = "Wider Swing", BonusText = "1.25x Cut Radius", RadiusMultiplier = 1.25},
		[4] = {Title = "Better Sales", BonusText = "1.5x Coins", CoinsMultiplier = 1.5},
		[5] = {Title = "Bigger Harvest", BonusText = "2x Grass", GrassMultiplier = 2},
		[6] = {Title = "Power Cut", BonusText = "2x Damage", DamageMultiplier = 2},
		[7] = {Title = "Fast Learner", BonusText = "1.5x XP", XPMultiplier = 1.5},
		[8] = {Title = "Golden Fields", BonusText = "2x Gold Chance", GoldChanceMultiplier = 2},
		[9] = {Title = "Rainbow Fields", BonusText = "2x Rainbow Chance", RainbowChanceMultiplier = 2},
		[10] = {Title = "Plains Mastery", BonusText = "+1 Cut Count", CutCountBonus = 1},
	},

	Forest = {
		[1] = {Title = "Thick Harvest", BonusText = "1.5x Grass", GrassMultiplier = 1.5},
		[2] = {Title = "Heavy Blades", BonusText = "1.75x Damage", DamageMultiplier = 1.75},
		[3] = {Title = "Forest Reach", BonusText = "1.3x Cut Radius", RadiusMultiplier = 1.3},
		[4] = {Title = "Timber Profit", BonusText = "1.5x Coins", CoinsMultiplier = 1.5},
		[5] = {Title = "Wild Growth", BonusText = "2x Grass", GrassMultiplier = 2},
		[6] = {Title = "Deep Cut", BonusText = "2x Damage", DamageMultiplier = 2},
		[7] = {Title = "Forest Wisdom", BonusText = "1.75x XP", XPMultiplier = 1.75},
		[8] = {Title = "Golden Grove", BonusText = "2.5x Gold Chance", GoldChanceMultiplier = 2.5},
		[9] = {Title = "Prismatic Grove", BonusText = "2x Rainbow Chance", RainbowChanceMultiplier = 2},
		[10] = {Title = "Forest Mastery", BonusText = "+1 Cut Count", CutCountBonus = 1},
	},

	Savanna = {
		[1] = {Title = "Dry Harvest", BonusText = "1.75x Grass", GrassMultiplier = 1.75},
		[2] = {Title = "Sunforged Edge", BonusText = "2x Damage", DamageMultiplier = 2},
		[3] = {Title = "Wide Plains", BonusText = "1.35x Cut Radius", RadiusMultiplier = 1.35},
		[4] = {Title = "Savanna Trade", BonusText = "1.75x Coins", CoinsMultiplier = 1.75},
		[5] = {Title = "Great Harvest", BonusText = "2.25x Grass", GrassMultiplier = 2.25},
		[6] = {Title = "Predator Cut", BonusText = "2.25x Damage", DamageMultiplier = 2.25},
		[7] = {Title = "Survival Instinct", BonusText = "2x XP", XPMultiplier = 2},
		[8] = {Title = "Golden Sun", BonusText = "3x Gold Chance", GoldChanceMultiplier = 3},
		[9] = {Title = "Rainbow Mirage", BonusText = "2.5x Rainbow Chance", RainbowChanceMultiplier = 2.5},
		[10] = {Title = "Savanna Mastery", BonusText = "+1 Cut Count", CutCountBonus = 1},
	},

	Jungle = {
		[1] = {Title = "Overgrowth", BonusText = "2x Grass", GrassMultiplier = 2},
		[2] = {Title = "Machete Power", BonusText = "2.25x Damage", DamageMultiplier = 2.25},
		[3] = {Title = "Vine Sweep", BonusText = "1.4x Cut Radius", RadiusMultiplier = 1.4},
		[4] = {Title = "Jungle Riches", BonusText = "2x Coins", CoinsMultiplier = 2},
		[5] = {Title = "Dense Harvest", BonusText = "2.5x Grass", GrassMultiplier = 2.5},
		[6] = {Title = "Savage Cut", BonusText = "2.5x Damage", DamageMultiplier = 2.5},
		[7] = {Title = "Ancient Knowledge", BonusText = "2.25x XP", XPMultiplier = 2.25},
		[8] = {Title = "Golden Temple", BonusText = "3.5x Gold Chance", GoldChanceMultiplier = 3.5},
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
			end
		end
	end

	return result
end

return MilestoneConfig

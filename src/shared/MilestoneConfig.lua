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

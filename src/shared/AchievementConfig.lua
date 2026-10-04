local AchievementConfig = {}

AchievementConfig.CategoryOrder = {
	"Grass",
	"Resets",
	"Locations",
	"RareGrass",
	"Level",
}

AchievementConfig.Categories = {
	Grass = {
		DisplayName = "GRASS",
		RewardLabel = "+ GRASS %",
		Entries = {
			{Id = "Grass_1K", Title = "1K GRASS", ProgressType = "Number", Attribute = "TotalGrassCut", Goal = 1000, BonusType = "Grass", Bonus = 0.05},
			{Id = "Grass_10K", Title = "10K GRASS", ProgressType = "Number", Attribute = "TotalGrassCut", Goal = 10000, BonusType = "Grass", Bonus = 0.10},
			{Id = "Grass_100K", Title = "100K GRASS", ProgressType = "Number", Attribute = "TotalGrassCut", Goal = 100000, BonusType = "Grass", Bonus = 0.15},
			{Id = "Grass_1M", Title = "1M GRASS", ProgressType = "Number", Attribute = "TotalGrassCut", Goal = 1000000, BonusType = "Grass", Bonus = 0.20},
			{Id = "Grass_10M", Title = "10M GRASS", ProgressType = "Number", Attribute = "TotalGrassCut", Goal = 10000000, BonusType = "Grass", Bonus = 0.25},
		},
	},
	Resets = {
		DisplayName = "RESETS",
		RewardLabel = "+ RESET TOKEN MULTIPLIER",
		Entries = {
			{Id = "Resets_5", Title = "5 RESETS", ProgressType = "Number", Attribute = "TotalResets", Goal = 5, BonusType = "ResetTokens", Bonus = 0.05},
			{Id = "Resets_25", Title = "25 RESETS", ProgressType = "Number", Attribute = "TotalResets", Goal = 25, BonusType = "ResetTokens", Bonus = 0.10},
			{Id = "Resets_100", Title = "100 RESETS", ProgressType = "Number", Attribute = "TotalResets", Goal = 100, BonusType = "ResetTokens", Bonus = 0.15},
			{Id = "Resets_250", Title = "250 RESETS", ProgressType = "Number", Attribute = "TotalResets", Goal = 250, BonusType = "ResetTokens", Bonus = 0.20},
			{Id = "Resets_500", Title = "500 RESETS", ProgressType = "Number", Attribute = "TotalResets", Goal = 500, BonusType = "ResetTokens", Bonus = 0.25},
		},
	},
	Locations = {
		DisplayName = "LOCATIONS",
		RewardLabel = "+ BACKPACK %",
		Entries = {
			{Id = "Location_Forest", Title = "FOREST", ProgressType = "Boolean", Attribute = "ForestUnlocked", BonusType = "Backpack", Bonus = 0.05},
			{Id = "Location_Savanna", Title = "SAVANNA", ProgressType = "Boolean", Attribute = "SavannaUnlocked", BonusType = "Backpack", Bonus = 0.05},
			{Id = "Location_Jungle", Title = "JUNGLE", ProgressType = "Boolean", Attribute = "JungleUnlocked", BonusType = "Backpack", Bonus = 0.10},
			{Id = "Location_Tundra", Title = "TUNDRA", ProgressType = "Boolean", Attribute = "TundraUnlocked", BonusType = "Backpack", Bonus = 0.10},
			{Id = "Location_Volcano", Title = "VOLCANO", ProgressType = "Boolean", Attribute = "VolcanoUnlocked", BonusType = "Backpack", Bonus = 0.15},
			{Id = "Location_Beach", Title = "BEACH", ProgressType = "Boolean", Attribute = "BeachUnlocked", BonusType = "Backpack", Bonus = 0.25},
		},
	},
	RareGrass = {
		DisplayName = "RARE GRASS",
		RewardLabel = "+ RARE GRASS LUCK",
		Entries = {
			{Id = "Gold_1", Title = "1 GOLD GRASS", ProgressType = "Number", Attribute = "GoldGrassFound", Goal = 1, BonusType = "RareLuck", Bonus = 0.02},
			{Id = "Gold_10", Title = "10 GOLD GRASS", ProgressType = "Number", Attribute = "GoldGrassFound", Goal = 10, BonusType = "RareLuck", Bonus = 0.05},
			{Id = "Gold_50", Title = "50 GOLD GRASS", ProgressType = "Number", Attribute = "GoldGrassFound", Goal = 50, BonusType = "RareLuck", Bonus = 0.08},
			{Id = "Rainbow_1", Title = "1 RAINBOW GRASS", ProgressType = "Number", Attribute = "RainbowGrassFound", Goal = 1, BonusType = "RareLuck", Bonus = 0.10},
			{Id = "Rainbow_10", Title = "10 RAINBOW GRASS", ProgressType = "Number", Attribute = "RainbowGrassFound", Goal = 10, BonusType = "RareLuck", Bonus = 0.15},
		},
	},
	Level = {
		DisplayName = "LEVEL",
		RewardLabel = "+ XP %",
		Entries = {
			{Id = "Level_10", Title = "LEVEL 10", ProgressType = "Number", Attribute = "Level", Goal = 10, BonusType = "XP", Bonus = 0.05},
			{Id = "Level_25", Title = "LEVEL 25", ProgressType = "Number", Attribute = "Level", Goal = 25, BonusType = "XP", Bonus = 0.10},
			{Id = "Level_50", Title = "LEVEL 50", ProgressType = "Number", Attribute = "Level", Goal = 50, BonusType = "XP", Bonus = 0.15},
			{Id = "Level_100", Title = "LEVEL 100", ProgressType = "Number", Attribute = "Level", Goal = 100, BonusType = "XP", Bonus = 0.20},
			{Id = "Level_200", Title = "LEVEL 200", ProgressType = "Number", Attribute = "Level", Goal = 200, BonusType = "XP", Bonus = 0.25},
		},
	},
}

AchievementConfig.ById = {}
for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
	for _, entry in ipairs(AchievementConfig.Categories[categoryId].Entries) do
		entry.Category = categoryId
		AchievementConfig.ById[entry.Id] = entry
	end
end

function AchievementConfig.GetProgress(player, entry)
	if entry.ProgressType == "Boolean" then
		return player:GetAttribute(entry.Attribute) == true and 1 or 0, 1
	end
	local value = tonumber(player:GetAttribute(entry.Attribute)) or 0
	return math.max(0, value), entry.Goal
end

function AchievementConfig.IsComplete(player, entry)
	local value, goal = AchievementConfig.GetProgress(player, entry)
	return value >= goal
end

function AchievementConfig.GetClaimAttribute(id)
	return "AchievementClaimed_" .. id
end

return AchievementConfig

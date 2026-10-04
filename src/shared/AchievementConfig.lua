local AchievementConfig = {}

AchievementConfig.CategoryOrder = {"Grass", "Resets", "Locations", "RareGrass", "Level"}

AchievementConfig.Categories = {
	Grass = {Entries = {
		{Id="Grass_1K", Title="1K GRASS", Attribute="TotalGrassCut", Goal=1000, Reward="+5% GRASS", BonusType="Grass", Bonus=0.05},
		{Id="Grass_10K", Title="10K GRASS", Attribute="TotalGrassCut", Goal=10000, Reward="+10% GRASS", BonusType="Grass", Bonus=0.10},
		{Id="Grass_100K", Title="100K GRASS", Attribute="TotalGrassCut", Goal=100000, Reward="+15% GRASS", BonusType="Grass", Bonus=0.15},
		{Id="Grass_1M", Title="1M GRASS", Attribute="TotalGrassCut", Goal=1000000, Reward="+20% GRASS", BonusType="Grass", Bonus=0.20},
		{Id="Grass_10M", Title="10M GRASS", Attribute="TotalGrassCut", Goal=10000000, Reward="+25% GRASS", BonusType="Grass", Bonus=0.25},
	}},
	Resets = {Entries = {
		{Id="Resets_5", Title="5 RESETS", Attribute="TotalResets", Goal=5, Reward="+5% RESET TOKENS", BonusType="ResetTokens", Bonus=0.05},
		{Id="Resets_25", Title="25 RESETS", Attribute="TotalResets", Goal=25, Reward="+10% RESET TOKENS", BonusType="ResetTokens", Bonus=0.10},
		{Id="Resets_100", Title="100 RESETS", Attribute="TotalResets", Goal=100, Reward="+15% RESET TOKENS", BonusType="ResetTokens", Bonus=0.15},
		{Id="Resets_250", Title="250 RESETS", Attribute="TotalResets", Goal=250, Reward="+20% RESET TOKENS", BonusType="ResetTokens", Bonus=0.20},
		{Id="Resets_500", Title="500 RESETS", Attribute="TotalResets", Goal=500, Reward="+25% RESET TOKENS", BonusType="ResetTokens", Bonus=0.25},
	}},
	Locations = {Entries = {
		{Id="Location_Forest", Title="FOREST", Attribute="ForestUnlocked", Goal=true, Reward="+5% BACKPACK", BonusType="Backpack", Bonus=0.05},
		{Id="Location_Savanna", Title="SAVANNA", Attribute="SavannaUnlocked", Goal=true, Reward="+5% BACKPACK", BonusType="Backpack", Bonus=0.05},
		{Id="Location_Jungle", Title="JUNGLE", Attribute="JungleUnlocked", Goal=true, Reward="+10% BACKPACK", BonusType="Backpack", Bonus=0.10},
		{Id="Location_Tundra", Title="TUNDRA", Attribute="TundraUnlocked", Goal=true, Reward="+10% BACKPACK", BonusType="Backpack", Bonus=0.10},
		{Id="Location_Volcano", Title="VOLCANO", Attribute="VolcanoUnlocked", Goal=true, Reward="+15% BACKPACK", BonusType="Backpack", Bonus=0.15},
		{Id="Location_Beach", Title="BEACH", Attribute="BeachUnlocked", Goal=true, Reward="+25% BACKPACK", BonusType="Backpack", Bonus=0.25},
	}},
	RareGrass = {Entries = {
		{Id="Gold_1", Title="1 GOLD GRASS", Attribute="GoldGrassFound", Goal=1, Reward="+2% RARE LUCK", BonusType="RareLuck", Bonus=0.02},
		{Id="Gold_10", Title="10 GOLD GRASS", Attribute="GoldGrassFound", Goal=10, Reward="+5% RARE LUCK", BonusType="RareLuck", Bonus=0.05},
		{Id="Gold_50", Title="50 GOLD GRASS", Attribute="GoldGrassFound", Goal=50, Reward="+8% RARE LUCK", BonusType="RareLuck", Bonus=0.08},
		{Id="Rainbow_1", Title="1 RAINBOW GRASS", Attribute="RainbowGrassFound", Goal=1, Reward="+10% RARE LUCK", BonusType="RareLuck", Bonus=0.10},
		{Id="Rainbow_10", Title="10 RAINBOW GRASS", Attribute="RainbowGrassFound", Goal=10, Reward="+15% RARE LUCK", BonusType="RareLuck", Bonus=0.15},
	}},
	Level = {Entries = {
		{Id="Level_10", Title="LEVEL 10", Attribute="Level", Goal=10, Reward="+5% XP", BonusType="XP", Bonus=0.05},
		{Id="Level_25", Title="LEVEL 25", Attribute="Level", Goal=25, Reward="+10% XP", BonusType="XP", Bonus=0.10},
		{Id="Level_50", Title="LEVEL 50", Attribute="Level", Goal=50, Reward="+15% XP", BonusType="XP", Bonus=0.15},
		{Id="Level_100", Title="LEVEL 100", Attribute="Level", Goal=100, Reward="+20% XP", BonusType="XP", Bonus=0.20},
		{Id="Level_200", Title="LEVEL 200", Attribute="Level", Goal=200, Reward="+25% XP", BonusType="XP", Bonus=0.25},
	}},
}

AchievementConfig.ById = {}
for _, categoryId in ipairs(AchievementConfig.CategoryOrder) do
	for _, entry in ipairs(AchievementConfig.Categories[categoryId].Entries) do
		AchievementConfig.ById[entry.Id] = entry
	end
end

function AchievementConfig.ClaimAttribute(id)
	return "AchievementClaimed_" .. id
end

function AchievementConfig.IsComplete(player, entry)
	local value = player:GetAttribute(entry.Attribute)
	if entry.Goal == true then return value == true end
	return (tonumber(value) or 0) >= entry.Goal
end

return AchievementConfig

local GrassConfig = {}

GrassConfig.ResetHealthMultiplier = 5

GrassConfig.BiomeOrder = {
	"Plains",
	"Forest",
	"Savanna",
	"Jungle",
	"Tundra",
	"Volcano",
	"Beach",
}

GrassConfig.Biomes = {
	Plains = {
		DisplayName = "PLAINS",
		GrassCount = 500,
		HealthMultiplier = 1,
	},
	Forest = {
		DisplayName = "FOREST",
		GrassCount = 1000,
		HealthMultiplier = 3,
	},
	Savanna = {
		DisplayName = "SAVANNA",
		GrassCount = 1000,
		HealthMultiplier = 6,
	},
	Jungle = {
		DisplayName = "JUNGLE",
		GrassCount = 1000,
		HealthMultiplier = 10,
	},
	Tundra = {
		DisplayName = "TUNDRA",
		GrassCount = 1000,
		HealthMultiplier = 16,
	},
	Volcano = {
		DisplayName = "VOLCANO",
		GrassCount = 1000,
		HealthMultiplier = 25,
	},
	Beach = {
		DisplayName = "BEACH",
		GrassCount = 1000,
		HealthMultiplier = 38,
	},
}

GrassConfig.TypeOrder = {
	"Small",
	"Big",
}

GrassConfig.Types = {
	Small = {
		DisplayName = "SMALL GRASS",
		BaseHealth = 3,
	},
	Big = {
		DisplayName = "BIG GRASS",
		BaseHealth = 15,
	},
}

GrassConfig.RarityOrder = {
	"Normal",
	"Gold",
	"Rainbow",
}

GrassConfig.Rarities = {
	Normal = {
		DisplayName = "NORMAL",
		HealthMultiplier = 1,
	},
	Gold = {
		DisplayName = "GOLD",
		HealthMultiplier = 2.5,
	},
	Rainbow = {
		DisplayName = "RAINBOW",
		HealthMultiplier = 5,
	},
}

function GrassConfig.GetHealth(biomeId, grassType, rarity, resetCount)
	local biome = GrassConfig.Biomes[biomeId]
	local typeConfig = GrassConfig.Types[grassType]
	local rarityConfig = GrassConfig.Rarities[rarity or "Normal"]

	if not biome or not typeConfig or not rarityConfig then
		return nil
	end

	resetCount = math.max(0, math.floor(tonumber(resetCount) or 0))

	return typeConfig.BaseHealth
		* biome.HealthMultiplier
		* (GrassConfig.ResetHealthMultiplier ^ resetCount)
		* rarityConfig.HealthMultiplier
end

return GrassConfig

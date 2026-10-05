local PetConfig = {}

PetConfig.MaxEquipped = 3

PetConfig.Pets = {
	SavannaCub = {DisplayName = "Savanna Cub", Rarity = "Common", Damage = 8, Egg = "Savanna"},
	SunFox = {DisplayName = "Sun Fox", Rarity = "Rare", Damage = 12, Egg = "Savanna"},
	GoldenMeerkat = {DisplayName = "Golden Meerkat", Rarity = "Epic", Damage = 18, Egg = "Savanna"},
	SavannaLion = {DisplayName = "Savanna Lion", Rarity = "Legendary", Damage = 28, Egg = "Savanna"},
	SunSpirit = {DisplayName = "Sun Spirit", Rarity = "Mythic", Damage = 45, Egg = "Savanna"},

	SnowBunny = {DisplayName = "Snow Bunny", Rarity = "Common", Damage = 120, Egg = "Tundra"},
	IceFox = {DisplayName = "Ice Fox", Rarity = "Rare", Damage = 180, Egg = "Tundra"},
	FrostWolf = {DisplayName = "Frost Wolf", Rarity = "Epic", Damage = 270, Egg = "Tundra"},
	PolarGuardian = {DisplayName = "Polar Guardian", Rarity = "Legendary", Damage = 420, Egg = "Tundra"},
	FrostSpirit = {DisplayName = "Frost Spirit", Rarity = "Mythic", Damage = 650, Egg = "Tundra"},

	Crab = {DisplayName = "Crab", Rarity = "Common", Damage = 1800, Egg = "Beach"},
	Parrot = {DisplayName = "Parrot", Rarity = "Rare", Damage = 2800, Egg = "Beach"},
	TropicalTurtle = {DisplayName = "Tropical Turtle", Rarity = "Epic", Damage = 4200, Egg = "Beach"},
	SharkPup = {DisplayName = "Shark Pup", Rarity = "Legendary", Damage = 6500, Egg = "Beach"},
	OceanSpirit = {DisplayName = "Ocean Spirit", Rarity = "Mythic", Damage = 10000, Egg = "Beach"},
}

function PetConfig.GetPet(id)
	return PetConfig.Pets[id]
end

return PetConfig

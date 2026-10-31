local PetConfig = {}

PetConfig.MaxEquipped = 3

PetConfig.Eggs = {
	Savanna = {
		DisplayName = "Savanna Egg",
		Price = 2500,
		Currency = "Coins",
		RequiredUnlock = "SavannaUnlocked",
		Pets = {
			{Id = "SavannaCub", Chance = 50},
			{Id = "SunFox", Chance = 30},
			{Id = "GoldenMeerkat", Chance = 14},
			{Id = "SavannaLion", Chance = 5},
			{Id = "SunSpirit", Chance = 1},
		},
	},
	Tundra = {
		DisplayName = "Tundra Egg",
		Price = 75000,
		Currency = "Coins",
		RequiredUnlock = "TundraUnlocked",
		Pets = {
			{Id = "TundraCub", Chance = 50},
			{Id = "SnowyOwl", Chance = 30},
			{Id = "FrostWolf", Chance = 16.5},
			{Id = "Mammoth", Chance = 3},
			{Id = "IceSpirit", Chance = 0.5},
		},
	},
	Beach = {
		DisplayName = "Beach Egg",
		Price = 1500000,
		Currency = "Coins",
		RequiredUnlock = "BeachUnlocked",
		Pets = {
			{Id = "BeachPup", Chance = 55},
			{Id = "Crab", Chance = 30},
			{Id = "SeaShellTurtle", Chance = 13.9},
			{Id = "Parrot", Chance = 1},
			{Id = "OceanSpirit", Chance = 0.1},
		},
	},
}

PetConfig.Pets = {
	SavannaCub = {DisplayName = "Savanna Cub", Rarity = "Common", Damage = 8, Egg = "Savanna"},
	SunFox = {DisplayName = "Sun Fox", Rarity = "Rare", Damage = 12, Egg = "Savanna"},
	GoldenMeerkat = {DisplayName = "Golden Meerkat", Rarity = "Epic", Damage = 18, Egg = "Savanna"},
	SavannaLion = {DisplayName = "Savanna Lion", Rarity = "Legendary", Damage = 28, Egg = "Savanna"},
	SunSpirit = {DisplayName = "Sun Spirit", Rarity = "Mythic", Damage = 45, Egg = "Savanna"},

	TundraCub = {DisplayName = "Tundra Cub", Rarity = "Common", Damage = 120, Egg = "Tundra"},
	SnowyOwl = {DisplayName = "Snowy Owl", Rarity = "Rare", Damage = 180, Egg = "Tundra"},
	FrostWolf = {DisplayName = "Frost Wolf", Rarity = "Epic", Damage = 270, Egg = "Tundra"},
	Mammoth = {DisplayName = "Mammoth", Rarity = "Legendary", Damage = 420, Egg = "Tundra"},
	IceSpirit = {DisplayName = "Ice Spirit", Rarity = "Mythic", Damage = 650, Egg = "Tundra"},

	BeachPup = {DisplayName = "Beach Pup", Rarity = "Common", Damage = 1800, Egg = "Beach"},
	Crab = {DisplayName = "Crab", Rarity = "Rare", Damage = 2800, Egg = "Beach"},
	SeaShellTurtle = {DisplayName = "Sea Shell Turtle", Rarity = "Epic", Damage = 4200, Egg = "Beach"},
	Parrot = {DisplayName = "Parrot", Rarity = "Legendary", Damage = 6500, Egg = "Beach"},
	OceanSpirit = {DisplayName = "Ocean Spirit", Rarity = "Mythic", Damage = 10000, Egg = "Beach"},

	-- Legacy IDs remain readable so previously saved inventories are not discarded.
	SnowBunny = {DisplayName = "Snow Bunny", Rarity = "Common", Damage = 120, Egg = "Tundra"},
	IceFox = {DisplayName = "Ice Fox", Rarity = "Rare", Damage = 180, Egg = "Tundra"},
	PolarGuardian = {DisplayName = "Polar Guardian", Rarity = "Legendary", Damage = 420, Egg = "Tundra"},
	FrostSpirit = {DisplayName = "Frost Spirit", Rarity = "Mythic", Damage = 650, Egg = "Tundra"},
	TropicalTurtle = {DisplayName = "Tropical Turtle", Rarity = "Epic", Damage = 4200, Egg = "Beach"},
	SharkPup = {DisplayName = "Shark Pup", Rarity = "Legendary", Damage = 6500, Egg = "Beach"},
}

function PetConfig.GetPet(id)
	return PetConfig.Pets[id]
end

return PetConfig

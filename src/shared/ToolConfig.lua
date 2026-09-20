local ToolConfig = {}

ToolConfig.Order = {
	"BasicScissors",
	"Pliers",
	"HedgeShears",
	"GrassCutter",
	"PowerCutter",
}

ToolConfig.Tools = {
	BasicScissors = {
		DisplayName = "BASIC SCISSORS",
		UnlockLevel = 1,
		BaseDamage = 1,
		BaseCooldown = 1.00,
		BaseRadius = 4.5,
		BaseCutCount = 1,
		Upgrades = {
			Damage = {MaxLevel = 10, AmountPerLevel = 1, Prices = {1, 1, 2, 2, 3, 3, 4, 5, 6, 8}},
			Cooldown = {MaxLevel = 5, AmountPerLevel = 0.06, Prices = {2, 3, 4, 6, 8}},
			Radius = {MaxLevel = 5, AmountPerLevel = 0.4, Prices = {1, 2, 3, 5, 7}},
			CutCount = {MaxLevel = 3, AmountPerLevel = 1, Prices = {4, 8, 15}},
		},
	},

	Pliers = {
		DisplayName = "PLIERS",
		UnlockLevel = 10,
		BaseDamage = 3,
		BaseCooldown = 0.90,
		BaseRadius = 4.8,
		BaseCutCount = 1,
		Upgrades = {
			Damage = {MaxLevel = 10, AmountPerLevel = 1, Prices = {2, 2, 3, 3, 4, 5, 6, 8, 10, 12}},
			Cooldown = {MaxLevel = 5, AmountPerLevel = 0.05, Prices = {3, 5, 7, 9, 12}},
			Radius = {MaxLevel = 5, AmountPerLevel = 0.4, Prices = {2, 3, 5, 7, 10}},
			CutCount = {MaxLevel = 3, AmountPerLevel = 1, Prices = {6, 12, 20}},
		},
	},

	HedgeShears = {
		DisplayName = "HEDGE SHEARS",
		UnlockLevel = 25,
		BaseDamage = 8,
		BaseCooldown = 0.80,
		BaseRadius = 5.5,
		BaseCutCount = 2,
		Upgrades = {
			Damage = {MaxLevel = 10, AmountPerLevel = 2, Prices = {3, 4, 5, 6, 7, 9, 11, 13, 15, 18}},
			Cooldown = {MaxLevel = 5, AmountPerLevel = 0.05, Prices = {5, 8, 11, 14, 18}},
			Radius = {MaxLevel = 5, AmountPerLevel = 0.5, Prices = {4, 6, 8, 11, 15}},
			CutCount = {MaxLevel = 3, AmountPerLevel = 1, Prices = {10, 18, 30}},
		},
	},

	GrassCutter = {
		DisplayName = "GRASS CUTTER",
		UnlockLevel = 50,
		BaseDamage = 20,
		BaseCooldown = 0.70,
		BaseRadius = 6.5,
		BaseCutCount = 3,
		Upgrades = {
			Damage = {MaxLevel = 10, AmountPerLevel = 4, Prices = {5, 6, 8, 10, 12, 15, 18, 20, 22, 25}},
			Cooldown = {MaxLevel = 5, AmountPerLevel = 0.04, Prices = {8, 12, 16, 20, 25}},
			Radius = {MaxLevel = 5, AmountPerLevel = 0.6, Prices = {6, 9, 12, 16, 22}},
			CutCount = {MaxLevel = 3, AmountPerLevel = 1, Prices = {15, 28, 45}},
		},
	},

	PowerCutter = {
		DisplayName = "POWER CUTTER",
		UnlockLevel = 100,
		BaseDamage = 50,
		BaseCooldown = 0.55,
		BaseRadius = 8.0,
		BaseCutCount = 4,
		Upgrades = {
			Damage = {MaxLevel = 10, AmountPerLevel = 8, Prices = {8, 10, 12, 15, 18, 22, 26, 30, 35, 40}},
			Cooldown = {MaxLevel = 5, AmountPerLevel = 0.03, Prices = {12, 18, 24, 32, 40}},
			Radius = {MaxLevel = 5, AmountPerLevel = 0.8, Prices = {10, 14, 19, 26, 35}},
			CutCount = {MaxLevel = 3, AmountPerLevel = 1, Prices = {25, 45, 70}},
		},
	},
}

function ToolConfig.GetTool(toolId)
	return ToolConfig.Tools[toolId]
end

function ToolConfig.GetUpgrade(toolId, statName)
	local tool = ToolConfig.Tools[toolId]
	if not tool then
		return nil
	end
	return tool.Upgrades[statName]
end

function ToolConfig.GetUpgradePrice(toolId, statName, currentLevel)
	local upgrade = ToolConfig.GetUpgrade(toolId, statName)
	if not upgrade or currentLevel >= upgrade.MaxLevel then
		return nil
	end
	return upgrade.Prices[currentLevel + 1]
end

return ToolConfig

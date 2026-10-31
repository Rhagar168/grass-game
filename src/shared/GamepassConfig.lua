local GamepassConfig = {}
GamepassConfig.Order = {"Damage", "Coins", "XP", "PetEquip", "AutoHatch", "InfiniteBackpack"}
GamepassConfig.Passes = {
    Damage = {Id = 2061877333, Name = "2x Damage", Description = "Double your cutting damage", Color = Color3.fromRGB(220, 65, 65)},
    Coins = {Id = 2060737859, Name = "2x Coins", Description = "Earn twice as many coins", Color = Color3.fromRGB(240, 177, 37)},
    XP = {Id = 2057792730, Name = "2x XP", Description = "Earn twice as much XP", Color = Color3.fromRGB(161, 75, 230)},
    PetEquip = {Id = 2057150675, Name = "+2 Pet Equip", Description = "Equip two additional pets", Color = Color3.fromRGB(47, 150, 246)},
    AutoHatch = {Id = 2063292884, Name = "Auto Hatch", Description = "Automatically open eggs", Color = Color3.fromRGB(45, 190, 92)},
    InfiniteBackpack = {Id = 2059580750, Name = "Infinite Backpack", Description = "Never run out of backpack space", Color = Color3.fromRGB(237, 132, 35)},
}
return GamepassConfig

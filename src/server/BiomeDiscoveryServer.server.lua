local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event = ReplicatedStorage:FindFirstChild("BiomeDiscoveryEvent")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "BiomeDiscoveryEvent"
    event.Parent = ReplicatedStorage
end

local allowed = {
    PLAINS = true, SAVANNA = true, TUNDRA = true,
    BEACH = true, JUNGLE = true, FOREST = true, MOLTEN = true,
}
local unlocks = {
    SAVANNA = "SavannaUnlocked",
    TUNDRA = "TundraUnlocked",
    BEACH = "BeachUnlocked",
    JUNGLE = "JungleUnlocked",
    FOREST = "ForestUnlocked",
    MOLTEN = "VolcanoUnlocked",
}

event.OnServerEvent:Connect(function(player, biome)
    if player:GetAttribute("DataLoaded") ~= true then return end
    if typeof(biome) ~= "string" or not allowed[biome] then return end
    local unlock = unlocks[biome]
    if unlock and player:GetAttribute(unlock) ~= true then return end
    local saved = player:GetAttribute("DiscoveredBiomes") or "PLAINS"
    for value in string.gmatch(saved, "[^,]+") do
        if value == biome then return end
    end
    player:SetAttribute("DiscoveredBiomes", saved .. "," .. biome)
end)

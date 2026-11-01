-- Reset board progress is rendered locally for each player.
-- Never write player-specific progress to a shared Workspace SurfaceGui.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local progressEvent = ReplicatedStorage:WaitForChild("LocationProgressUpdate")
local BIOMES = {Plains=500,Forest=1000,Savanna=1000,Jungle=1000,Tundra=1000,Volcano=1000,Beach=1000}
local function update(player, biome)
    if not player or not player.Parent then return end
    local total = BIOMES[biome]
    if not total then return end
    local remaining = player:GetAttribute(biome .. "GrassRemaining")
    if typeof(remaining) ~= "number" then remaining = total end
    player:SetAttribute(biome .. "CanReset", remaining <= 0)
end
local function setup(player)
    if player:GetAttribute("DataLoaded") ~= true then
        player:GetAttributeChangedSignal("DataLoaded"):Wait()
    end
    if not player.Parent then return end
    for biome in pairs(BIOMES) do
        update(player, biome)
        player:GetAttributeChangedSignal(biome .. "GrassRemaining"):Connect(function()
            update(player, biome)
        end)
    end
end
Players.PlayerAdded:Connect(function(p) task.spawn(setup,p) end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(setup,p) end
progressEvent.Event:Connect(function(biome, player) update(player, biome) end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local event = Instance.new("RemoteEvent")
event.Name = "BuyPetUpgrade"
event.Parent = ReplicatedStorage
event.OnServerEvent:Connect(function(player, id)
    if player:GetAttribute("DataLoaded") ~= true or typeof(id) ~= "string" then return end
    local info = PetConfig.Upgrades[id]
    if not info then return end
    local attr = "Pet" .. id .. "Level"
    local level = math.clamp(player:GetAttribute(attr) or 0, 0, info.Max)
    if level >= info.Max then return end
    local price = PetConfig.UpgradeCost(id, level)
    local balance = player:GetAttribute("ResetTokens") or 0
    if balance < price then return end
    player:SetAttribute("ResetTokens", balance - price)
    player:SetAttribute(attr, level + 1)
end)

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local function refresh(player)
    local passId = PetConfig.EquipGamepassId
    if not passId or passId <= 0 then
        player:SetAttribute("HasPetEquipGamepass", false)
        return
    end
    local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
    if ok then
        player:SetAttribute("HasPetEquipGamepass", owns == true)
    else
        warn("[PetEquipGamepass] Failed to verify gamepass for " .. player.Name)
    end
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(refresh, player)
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(refresh, player) end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    if gamePassId == PetConfig.EquipGamepassId and wasPurchased then
        task.spawn(refresh, player)
    end
end)

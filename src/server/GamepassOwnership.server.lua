local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("GamepassConfig"))

local function check(player, key)
    local pass = Config.Passes[key]
    if not pass or pass.Id <= 0 then return end
    local ok, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
    end)
    if ok and player.Parent then
        player:SetAttribute("Gamepass_" .. key, owns == true)
    elseif not ok then
        warn("[Gamepasses] Could not check " .. key .. " for " .. player.Name)
    end
end

local function setup(player)
    for _, key in ipairs(Config.Order) do
        task.spawn(check, player, key)
    end
end
Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do setup(player) end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
    if not purchased then return end
    for key, pass in pairs(Config.Passes) do
        if pass.Id == id then
            if RunService:IsStudio() then
                -- Studio test purchases are not returned by UserOwnsGamePassAsync.
                -- Grant the session-only server attribute so all gameplay systems react.
                player:SetAttribute("Gamepass_" .. key, true)
                if key == "PetEquip" then player:SetAttribute("HasPetEquipGamepass", true) end
            else
                task.spawn(check, player, key)
            end
            break
        end
    end
end)

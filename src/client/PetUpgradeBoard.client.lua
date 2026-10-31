local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local config = require(RS:WaitForChild("PetConfig"))
local buy = RS:WaitForChild("BuyPetUpgrade")
local board = workspace:WaitForChild("Boards"):WaitForChild("Tundra"):WaitForChild("PetsUpgrades")
local source = board:FindFirstChild("PetUpgradeSurface", true)
if not source then
    warn("[PetUpgrades] Run tools/CreatePetUpgradeBoard.command.lua in Studio Command Bar (Edit mode), then save")
    return
end
local adornee = source.Parent
if not adornee:IsA("BasePart") then
    warn("[PetUpgrades] SurfaceGui must be inside the display MeshPart")
    return
end
local playerGui = player:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("PetUpgradeSurface")
if previous then previous:Destroy() end
local gui = source:Clone()
gui.Adornee = adornee
gui.Enabled = true
gui.Active = true
gui.Parent = playerGui
source.Enabled = false
local scroll = gui:WaitForChild("Background"):WaitForChild("UpgradeScroll")
for _, id in ipairs({"Damage", "Speed", "AttackSpeed", "Equip"}) do
    local info = config.Upgrades[id]
    local card = scroll:WaitForChild(id)
    local levelLabel = card:WaitForChild("Level")
    local button = card:WaitForChild("Buy")
    local description = card:WaitForChild("Description")
    local priceLabel = card:FindFirstChild("Price")
    local function refresh()
        local current = math.clamp(player:GetAttribute("Pet" .. id .. "Level") or 0, 0, info.Max)
        levelLabel.Text = ("LEVEL %d / %d"):format(current, info.Max)
        local increments = {Damage = 15, Speed = 10, AttackSpeed = 8}
        if id == "Equip" then
            description.Text = ("%d PETS  →  %d PETS"):format(3 + current, 3 + math.min(current + 1, info.Max))
        else
            local step = increments[id]
            description.Text = ("%d%%  →  %d%%"):format(current * step, math.min(current + 1, info.Max) * step)
        end
        if current >= info.Max then
            button.Text = "MAX LEVEL"
            if priceLabel then priceLabel.Text = "MAX" end
            button.BackgroundColor3 = Color3.fromRGB(75, 91, 102)
        else
            local cost = config.UpgradeCost(id, current)
            button.Text = "BUY"
            if priceLabel then priceLabel.Text = ("%d RT"):format(cost) else button.Text = ("BUY  -  %d RT"):format(cost) end
            button.BackgroundColor3 = (player:GetAttribute("ResetTokens") or 0) >= cost
                and Color3.fromRGB(36, 159, 105) or Color3.fromRGB(125, 69, 75)
        end
    end
    button.MouseButton1Click:Connect(function()
        local level = player:GetAttribute("Pet" .. id .. "Level") or 0
        if level < info.Max and (player:GetAttribute("ResetTokens") or 0) >= config.UpgradeCost(id, level) then
            buy:FireServer(id)
        end
    end)
    player:GetAttributeChangedSignal("Pet" .. id .. "Level"):Connect(refresh)
    player:GetAttributeChangedSignal("ResetTokens"):Connect(refresh)
    refresh()
end
print("[PetUpgrades] Board ready:", adornee:GetFullName())

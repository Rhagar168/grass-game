local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local config = require(RS:WaitForChild("PetConfig"))
local buy = RS:WaitForChild("BuyPetUpgrade")
local board = workspace:WaitForChild("Boards"):WaitForChild("Tundra"):WaitForChild("PetsUpgrades")
local playerGui = player:WaitForChild("PlayerGui")
local upgradeSound = Instance.new("Sound")
upgradeSound.Name = "PetUpgradePurchaseSound"
upgradeSound.SoundId = "rbxassetid://98911839276314"
upgradeSound.Volume = 0.35
upgradeSound.Parent = SoundService
local pendingPurchases = {}

-- Studio-created SurfaceGui lives inside the imported Cube MODEL.
-- Its sibling Cube.001 etc. MeshParts may stream to the client later.
local function findDisplay()
    local source = board:FindFirstChild("PetUpgradeSurface", true)
    if not source then return nil end
    local display = source.Adornee
    if not (display and display:IsA("BasePart") and display:IsDescendantOf(workspace)) then
        display = nil
        local bestArea = -1
        for _, obj in ipairs(board:GetDescendants()) do
            if obj:IsA("BasePart") then
                local d = {obj.Size.X, obj.Size.Y, obj.Size.Z}
                table.sort(d, function(a,b) return a > b end)
                local area = d[1] * d[2]
                if area > bestArea then
                    bestArea = area
                    display = obj
                end
            end
        end
    end
    return source, display
end

local source, adornee
repeat
    source, adornee = findDisplay()
    if source and adornee then break end
    task.wait(0.5)
until not board.Parent
if not source or not adornee then return end

local previous = playerGui:FindFirstChild("PetUpgradeSurface")
if previous then previous:Destroy() end
local gui = source:Clone()
gui.Adornee = adornee
gui.Enabled = true
gui.Active = true
gui.Parent = playerGui
source.Enabled = false
print("[PetUpgrades] UI connected:", adornee:GetFullName())
local scroll = gui:WaitForChild("Background"):WaitForChild("UpgradeScroll")
for _, id in ipairs({"Damage", "Speed", "AttackSpeed", "Equip"}) do
    local info = config.Upgrades[id]
    local card = scroll:WaitForChild(id)
    local levelLabel = card:WaitForChild("Level")
    local button = card:WaitForChild("Buy")
    local description = card:WaitForChild("Description")
    local priceLabel = card:FindFirstChild("Price")
    local flashId = 0
    local function purchaseFlash(isMax)
        flashId += 1
        local token = flashId
        local scale = button:FindFirstChild("PurchaseFeedbackScale")
        if not scale then
            scale = Instance.new("UIScale")
            scale.Name = "PurchaseFeedbackScale"
            scale.Parent = button
        end
        local stroke = button:FindFirstChild("PurchaseFeedbackStroke")
        if not stroke then
            stroke = Instance.new("UIStroke")
            stroke.Name = "PurchaseFeedbackStroke"
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Thickness = 2
            stroke.Transparency = 1
            stroke.Parent = button
        end
        local baseColor = button.BackgroundColor3
        stroke.Color = isMax and Color3.fromRGB(255, 205, 86) or Color3.fromRGB(105, 255, 165)
        button.BackgroundColor3 = isMax and Color3.fromRGB(181, 141, 52) or Color3.fromRGB(62, 209, 125)
        scale.Scale = 1.06
        stroke.Transparency = 0
        TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
        task.delay(0.3, function()
            if token == flashId and button.Parent then button.BackgroundColor3 = baseColor end
        end)
    end
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
                and Color3.fromRGB(36, 159, 105) or Color3.fromRGB(105, 112, 121)
        end
    end
    button.MouseButton1Click:Connect(function()
        local level = player:GetAttribute("Pet" .. id .. "Level") or 0
        if level < info.Max and (player:GetAttribute("ResetTokens") or 0) >= config.UpgradeCost(id, level) then
            pendingPurchases[id] = level
            buy:FireServer(id)
        end
    end)
    player:GetAttributeChangedSignal("Pet" .. id .. "Level"):Connect(function()
        local newLevel = player:GetAttribute("Pet" .. id .. "Level") or 0
        if pendingPurchases[id] ~= nil then
            if newLevel > pendingPurchases[id] then
                upgradeSound.TimePosition = 0
                upgradeSound:Play()
                refresh()
                purchaseFlash(newLevel >= info.Max)
            end
            pendingPurchases[id] = nil
        end
        refresh()
    end)
    player:GetAttributeChangedSignal("ResetTokens"):Connect(refresh)
    refresh()
end
print("[PetUpgrades] Board ready:", adornee:GetFullName())

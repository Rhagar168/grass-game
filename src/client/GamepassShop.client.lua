local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GamepassConfig"))
local playerGui = player:WaitForChild("PlayerGui")

-- The entire shop layout is authored in StarterGui/GamepassShop.
-- Do not generate a second copy at runtime.
local gui = playerGui:WaitForChild("GamepassShop")
local shade = gui:FindFirstChildWhichIsA("Frame")
assert(shade, "GamepassShop: missing shade")
local panel = shade:FindFirstChildWhichIsA("Frame")
assert(panel, "GamepassShop: missing shop panel")
local header = panel:FindFirstChildWhichIsA("Frame")
assert(header, "GamepassShop: missing header")
local close = header:FindFirstChildWhichIsA("TextButton")
assert(close, "GamepassShop: missing close button")
local scroll = panel:FindFirstChildWhichIsA("ScrollingFrame")
assert(scroll, "GamepassShop: missing scroll")
local content = scroll:FindFirstChildWhichIsA("Frame")
assert(content, "GamepassShop: missing content")
local cardHolder = content:WaitForChild("Gamepasses")

local function owns(key)
    return player:GetAttribute("Gamepass_" .. key) == true
        or (key == "PetEquip" and player:GetAttribute("HasPetEquipGamepass") == true)
end

-- The copied cards already exist. Attach purchase behavior without recreating them.
local cards = {}
for _, child in ipairs(cardHolder:GetChildren()) do
    if child:IsA("Frame") then table.insert(cards, child) end
end
table.sort(cards, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

for i, key in ipairs(Config.Order) do
    local pass = Config.Passes[key]
    local card = cards[i]
    if card then
        local buy
        for _, child in ipairs(card:GetChildren()) do
            if child:IsA("TextButton") then buy = child; break end
        end
        if buy then
            local currentPrice
            local function update()
                if owns(key) then
                    buy.Text = "OWNED"
                    buy.BackgroundColor3 = Color3.fromRGB(51,133,83)
                else
                    buy.Text = currentPrice and (tostring(currentPrice) .. " R$") or "BUY"
                    buy.BackgroundColor3 = Color3.fromRGB(73,199,73)
                end
            end
            player:GetAttributeChangedSignal("Gamepass_" .. key):Connect(update)
            if key == "PetEquip" then
                player:GetAttributeChangedSignal("HasPetEquipGamepass"):Connect(update)
            end
            update()
            buy.Activated:Connect(function()
                if not owns(key) and pass.Id > 0 then
                    MarketplaceService:PromptGamePassPurchase(player, pass.Id)
                end
            end)
            task.spawn(function()
                local ok, info = pcall(function()
                    return MarketplaceService:GetProductInfo(pass.Id, Enum.InfoType.GamePass)
                end)
                if ok and info then
                    currentPrice = info.PriceInRobux
                    update()
                end
            end)
        end
    else
        warn("GamepassShop: missing physical card for " .. key)
    end
end

local codes = content:WaitForChild("RedeemCodes")
local input = codes:WaitForChild("CodeInput")
local redeem
local feedback
for _, child in ipairs(codes:GetChildren()) do
    if child:IsA("TextButton") then
        redeem = child
    elseif child:IsA("TextLabel") and child.Text == "" then
        feedback = child
    end
end
assert(redeem and feedback, "GamepassShop: missing redeem controls")

local redeemRemote = ReplicatedStorage:WaitForChild("RedeemCode")
local pending = false
local feedbackVersion = 0
local function showFeedback(message, color)
    feedbackVersion += 1
    local version = feedbackVersion
    feedback.Text = message
    feedback.TextColor3 = color
    task.delay(4, function()
        if feedbackVersion == version and feedback.Parent then
            feedback.Text = ""
        end
    end)
end
local function redeemCode()
    if pending or input.Text == "" then return end
    pending = true
    redeem.Text = "..."
    local ok, success, message = pcall(function()
        return redeemRemote:InvokeServer(input.Text)
    end)
    pending = false
    redeem.Text = "REDEEM"
    if ok then
        showFeedback(message or "UNKNOWN RESULT", success and Color3.fromRGB(92,230,126) or Color3.fromRGB(240,118,118))
        if success then input.Text = "" end
    else
        showFeedback("PLEASE TRY AGAIN", Color3.fromRGB(240,118,118))
    end
end
redeem.Activated:Connect(redeemCode)
input.FocusLost:Connect(function(enterPressed)
    if enterPressed then redeemCode() end
end)

-- Hide the other HUD/menu elements while the shop is open.
-- Keep the currency HUDs visible and restore each element's previous state on close.
local hiddenState = {}
local currencyNames = {
    CoinsHUD = true,
    ResetTokensHUD = true,
    GrassCoresHUD = true,
}
local popupScale = panel:FindFirstChildWhichIsA("UIScale")
if not popupScale then
    popupScale = Instance.new("UIScale")
    popupScale.Parent = panel
end
popupScale.Scale = 1
local popupTween
local function setShopOpen(isOpen)
    if isOpen == shade.Visible then return end
    if popupTween then
        popupTween:Cancel()
        popupTween = nil
    end
    shade.Visible = isOpen
    if isOpen then
        popupScale.Scale = 0.88
        popupTween = TweenService:Create(popupScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
        popupTween:Play()
        table.clear(hiddenState)
        local mainUI = playerGui:FindFirstChild("MainUI")
        if mainUI then
            for _, child in ipairs(mainUI:GetChildren()) do
                if child:IsA("GuiObject") and not currencyNames[child.Name] then
                    hiddenState[child] = child.Visible
                    child.Visible = false
                end
            end
        end
    else
        for child, wasVisible in pairs(hiddenState) do
            if child.Parent then
                child.Visible = wasVisible
            end
        end
        table.clear(hiddenState)
    end
end

-- Bind directly to the existing MainUI.RightMenu.ShopButton.
-- Retry after UI recreation and support both click and touch via Activated.
local boundButtons = {}
local function bindShopButton(button)
    if not button:IsA("GuiButton") or boundButtons[button] then return end
    boundButtons[button] = true
    button.Activated:Connect(function()
        setShopOpen(not shade.Visible)
    end)
end

local function scanButtons()
    for _, child in ipairs(playerGui:GetDescendants()) do
        if child.Name == "ShopButton" then
            bindShopButton(child)
        end
    end
end

scanButtons()
playerGui.DescendantAdded:Connect(function(child)
    if child.Name == "ShopButton" then
        bindShopButton(child)
    end
end)
close.Activated:Connect(function()
    setShopOpen(false)
end)

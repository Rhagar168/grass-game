local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GamepassConfig"))
local playerGui = player:WaitForChild("PlayerGui")

local MICHROMA = Font.new("rbxasset://fonts/families/Michroma.json")

local gui = Instance.new("ScreenGui")
gui.Name = "GamepassShop"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 25
gui.Parent = playerGui

local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end
local function stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Parent = obj
end
local function text(parent, value, size, color, font)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = value
    t.TextSize = size
    t.TextColor3 = color or Color3.new(1,1,1)
    t.FontFace = MICHROMA
    t.Parent = parent
    return t
end

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1,1)
shade.BackgroundColor3 = Color3.new(0,0,0)
shade.BackgroundTransparency = 1
shade.Visible = false
shade.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.Position = UDim2.fromScale(0.5,0.5)
panel.Size = UDim2.fromScale(0.78,0.79)
panel.BackgroundColor3 = Color3.fromRGB(28,34,39)
panel.Parent = shade
round(panel,14)
stroke(panel,Color3.fromRGB(83,99,104),2)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(850,680)
limit.MinSize = Vector2.new(290,290)
limit.Parent = panel

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,65)
header.BackgroundColor3 = Color3.fromRGB(43,49,54)
header.Parent = panel
round(header,12)
local bar = Instance.new("Frame")
bar.Position = UDim2.new(0,0,1,-5)
bar.Size = UDim2.new(1,0,0,5)
bar.BackgroundColor3 = Color3.fromRGB(77,211,104)
bar.BorderSizePixel = 0
bar.Parent = header

local title = text(header,"EXCLUSIVE SHOP",34,Color3.fromRGB(90,235,120))
title.Position = UDim2.fromOffset(20,5)
title.Size = UDim2.new(1,-85,0,50)
title.TextXAlignment = Enum.TextXAlignment.Left
-- Subtitle removed




local close = Instance.new("TextButton")
close.Position = UDim2.new(1,-54,0,13)
close.Size = UDim2.fromOffset(39,39)
close.BackgroundColor3 = Color3.fromRGB(202,62,62)
close.Text = "X"
close.TextSize = 21
close.TextColor3 = Color3.new(1,1,1)
close.FontFace = MICHROMA
close.Parent = header
round(close,9)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(18,79)
scroll.Size = UDim2.new(1,-36,1,-94)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(91,189,112)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.fromOffset(0,0)
scroll.Parent = panel

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Size = UDim2.new(1,-8,0,0)
content.AutomaticSize = Enum.AutomaticSize.Y
content.Parent = scroll
local vertical = Instance.new("UIListLayout")
vertical.SortOrder = Enum.SortOrder.LayoutOrder
vertical.Padding = UDim.new(0,18)
vertical.Parent = content

local cardHolder = Instance.new("Frame")
cardHolder.Name = "Gamepasses"
cardHolder.LayoutOrder = 1
cardHolder.BackgroundTransparency = 1
cardHolder.Size = UDim2.new(1,0,0,887)
cardHolder.Parent = content

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.5,-9,0,285)
grid.CellPadding = UDim2.new(0,14,0,16)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = cardHolder

local function owns(key)
    return player:GetAttribute("Gamepass_" .. key) == true
        or (key == "PetEquip" and player:GetAttribute("HasPetEquipGamepass") == true)
end

for i, key in ipairs(Config.Order) do
    local pass = Config.Passes[key]
    local card = Instance.new("Frame")
    card.LayoutOrder = i
    card.BackgroundColor3 = Color3.fromRGB(39,46,52)
    card.Parent = cardHolder
    round(card,12)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Color3.fromRGB(51,61,67),Color3.fromRGB(30,36,42))
    gradient.Rotation = 90
    gradient.Parent = card

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1,0,0,7)
    accent.BackgroundColor3 = pass.Color
    accent.BorderSizePixel = 0
    accent.Parent = card
    round(accent,5)

    local name = text(card,pass.Name,27)
    name.Position = UDim2.fromOffset(12,18)
    name.Size = UDim2.new(1,-24,0,45)
    name.TextXAlignment = Enum.TextXAlignment.Center
    name.TextScaled = true
    local nameLimit = Instance.new("UITextSizeConstraint")
    nameLimit.MaxTextSize = 27
    nameLimit.Parent = name

    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.Position = UDim2.fromOffset(14,79)
    image.Size = UDim2.fromOffset(172,172)
    image.Image = "rbxthumb://type=GamePass&id=" .. tostring(pass.Id) .. "&w=150&h=150"
    image.ScaleType = Enum.ScaleType.Fit
    image.Parent = card
    -- The thumbnail already contains the circular icon; no square frame.

    local desc = text(card,pass.Description,18,Color3.fromRGB(222,229,225),Enum.Font.GothamMedium)
    desc.Position = UDim2.new(0,204,0,87)
    desc.Size = UDim2.new(1,-219,0,88)
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left

    local buy = Instance.new("TextButton")
    buy.Position = UDim2.new(0,204,1,-78)
    buy.Size = UDim2.new(1,-219,0,54)
    buy.BackgroundColor3 = Color3.fromRGB(69,191,78)
    buy.TextColor3 = Color3.new(1,1,1)
    buy.TextSize = 21
    buy.FontFace = MICHROMA
    buy.Parent = card
    round(buy,9)
    local currentPrice = nil
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
    buy.MouseButton1Click:Connect(function()
        if not owns(key) and pass.Id > 0 then
            MarketplaceService:PromptGamePassPurchase(player,pass.Id)
        end
    end)
    task.spawn(function()
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(pass.Id,Enum.InfoType.GamePass)
        end)
        if ok and info then
            currentPrice = info.PriceInRobux
            update()
        end
    end)
end

local codes = Instance.new("Frame")
codes.Name = "RedeemCodes"
codes.LayoutOrder = 2
codes.Size = UDim2.new(1,0,0,155)
codes.BackgroundColor3 = Color3.fromRGB(31,38,43)
codes.Parent = content
round(codes,12)
stroke(codes,Color3.fromRGB(111,124,132),2)

local codeTitle = text(codes,"REDEEM CODES",24,Color3.fromRGB(90,235,120))
codeTitle.Position = UDim2.fromOffset(15,9)
codeTitle.Size = UDim2.new(1,-30,0,40)
codeTitle.TextXAlignment = Enum.TextXAlignment.Left

local input = Instance.new("TextBox")
input.Name = "CodeInput"
input.Position = UDim2.new(0,15,0,55)
input.Size = UDim2.new(0.66,-20,0,46)
input.BackgroundColor3 = Color3.fromRGB(20,26,30)
input.TextColor3 = Color3.new(1,1,1)
input.PlaceholderColor3 = Color3.fromRGB(155,165,172)
input.PlaceholderText = "ENTER CODE..."
input.Text = ""
input.TextSize = 16
input.FontFace = MICHROMA
input.ClearTextOnFocus = false
input.Parent = codes
round(input,8)
input.TextStrokeTransparency = 1

local redeem = Instance.new("TextButton")
redeem.Position = UDim2.new(0.66,5,0,55)
redeem.Size = UDim2.new(0.34,-20,0,46)
redeem.BackgroundColor3 = Color3.fromRGB(50,153,80)
redeem.Text = "REDEEM"
redeem.TextSize = 16
redeem.TextColor3 = Color3.new(1,1,1)
redeem.FontFace = MICHROMA
redeem.Parent = codes
round(redeem,8)
redeem.TextStrokeTransparency = 1

local feedback = text(codes,"",13,Color3.fromRGB(185,220,193))
feedback.Position = UDim2.fromOffset(15,109)
feedback.Size = UDim2.new(1,-30,0,35)
feedback.TextXAlignment = Enum.TextXAlignment.Left
feedback.TextWrapped = true

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
local popupScale = Instance.new("UIScale")
popupScale.Scale = 1
popupScale.Parent = panel
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

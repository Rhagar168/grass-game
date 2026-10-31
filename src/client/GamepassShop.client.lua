local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GamepassConfig"))
local playerGui = player:WaitForChild("PlayerGui")

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
    t.Font = font or Enum.Font.GothamBold
    t.Parent = parent
    return t
end

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1,1)
shade.BackgroundColor3 = Color3.new(0,0,0)
shade.BackgroundTransparency = 0.4
shade.Visible = false
shade.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.Position = UDim2.fromScale(0.5,0.5)
panel.Size = UDim2.fromScale(0.82,0.82)
panel.BackgroundColor3 = Color3.fromRGB(28,34,39)
panel.Parent = shade
round(panel,14)
stroke(panel,Color3.fromRGB(83,99,104),2)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(860,720)
limit.MinSize = Vector2.new(290,290)
limit.Parent = panel

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,75)
header.BackgroundColor3 = Color3.fromRGB(36,64,49)
header.Parent = panel
round(header,12)
local bar = Instance.new("Frame")
bar.Position = UDim2.new(0,0,1,-5)
bar.Size = UDim2.new(1,0,0,5)
bar.BackgroundColor3 = Color3.fromRGB(77,211,104)
bar.BorderSizePixel = 0
bar.Parent = header

local title = text(header,"EXCLUSIVE SHOP",27)
title.Position = UDim2.fromOffset(20,8)
title.Size = UDim2.new(1,-85,0,36)
title.TextXAlignment = Enum.TextXAlignment.Left
local subtitle = text(header,"PERMANENT GAMEPASS BOOSTS",12,Color3.fromRGB(179,218,190))
subtitle.Position = UDim2.fromOffset(21,44)
subtitle.Size = UDim2.new(1,-90,0,20)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton")
close.Position = UDim2.new(1,-54,0,13)
close.Size = UDim2.fromOffset(39,39)
close.BackgroundColor3 = Color3.fromRGB(202,62,62)
close.Text = "X"
close.TextSize = 21
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.Parent = header
round(close,9)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(18,91)
scroll.Size = UDim2.new(1,-36,1,-109)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(91,189,112)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.fromOffset(0,0)
scroll.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.5,-9,0,178)
grid.CellPadding = UDim2.new(0,14,0,14)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local function owns(key)
    return player:GetAttribute("Gamepass_" .. key) == true
        or (key == "PetEquip" and player:GetAttribute("HasPetEquipGamepass") == true)
end

for i, key in ipairs(Config.Order) do
    local pass = Config.Passes[key]
    local card = Instance.new("Frame")
    card.LayoutOrder = i
    card.BackgroundColor3 = Color3.fromRGB(46,52,58)
    card.Parent = scroll
    round(card,12)
    stroke(card,Color3.fromRGB(83,92,99),1.5)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1,0,0,7)
    accent.BackgroundColor3 = pass.Color
    accent.BorderSizePixel = 0
    accent.Parent = card
    round(accent,5)

    local name = text(card,pass.Name,19)
    name.Position = UDim2.fromOffset(12,15)
    name.Size = UDim2.new(1,-24,0,30)
    name.TextXAlignment = Enum.TextXAlignment.Center
    name.TextScaled = true
    local nameLimit = Instance.new("UITextSizeConstraint")
    nameLimit.MaxTextSize = 19
    nameLimit.Parent = name

    local image = Instance.new("ImageLabel")
    image.BackgroundColor3 = Color3.fromRGB(34,40,46)
    image.Position = UDim2.fromOffset(13,55)
    image.Size = UDim2.fromOffset(75,75)
    image.Image = "rbxthumb://type=GamePass&id=" .. tostring(pass.Id) .. "&w=150&h=150"
    image.ScaleType = Enum.ScaleType.Fit
    image.Parent = card
    round(image,10)

    local desc = text(card,pass.Description,13,Color3.fromRGB(222,229,225),Enum.Font.GothamMedium)
    desc.Position = UDim2.new(0,99,0,57)
    desc.Size = UDim2.new(1,-111,0,67)
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Center

    local buy = Instance.new("TextButton")
    buy.Position = UDim2.new(0,13,1,-44)
    buy.Size = UDim2.new(1,-26,0,35)
    buy.BackgroundColor3 = Color3.fromRGB(69,191,78)
    buy.TextColor3 = Color3.new(1,1,1)
    buy.TextSize = 17
    buy.Font = Enum.Font.GothamBold
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

local function findShopButton()
    for _, child in ipairs(playerGui:GetDescendants()) do
        if child.Name == "ShopButton" and child:IsA("GuiButton") then
            return child
        end
    end
    while true do
        local child = playerGui.DescendantAdded:Wait()
        if child.Name == "ShopButton" and child:IsA("GuiButton") then
            return child
        end
    end
end
task.spawn(function()
    local shopButton = findShopButton()
    shopButton.MouseButton1Click:Connect(function()
        shade.Visible = not shade.Visible
    end)
end)
close.MouseButton1Click:Connect(function() shade.Visible = false end)

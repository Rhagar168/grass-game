local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GamepassConfig"))
local gui = Instance.new("ScreenGui")
gui.Name = "GamepassShop"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end
local function label(parent, text, size, color)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 0, 26)
    t.Text = text
    t.TextSize = size
    t.TextColor3 = color or Color3.new(1,1,1)
    t.Font = Enum.Font.GothamBold
    t.Parent = parent
    return t
end

local playerGui = player:WaitForChild("PlayerGui")
local shopButton = playerGui:WaitForChild("MainGui", 5)
if shopButton then
    shopButton = shopButton:FindFirstChild("ShopButton", true)
end
if not shopButton then
    for _, descendant in ipairs(playerGui:GetDescendants()) do
        if descendant.Name == "ShopButton" and descendant:IsA("GuiButton") then
            shopButton = descendant
            break
        end
    end
end
if not shopButton then
    local found = false
    repeat
        local descendant = playerGui.DescendantAdded:Wait()
        if descendant.Name == "ShopButton" and descendant:IsA("GuiButton") then
            shopButton = descendant
            found = true
        end
    until found
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
panel.Size = UDim2.new(0.82,0,0.8,0)
panel.BackgroundColor3 = Color3.fromRGB(29, 34, 39)
panel.Parent = shade
corner(panel, 14)
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(720, 640)
constraint.MinSize = Vector2.new(290, 290)
constraint.Parent = panel

local title = label(panel, "GAMEPASS SHOP", 25)
title.Size = UDim2.new(1,-60,0,55)
title.Position = UDim2.fromOffset(15,0)
title.TextXAlignment = Enum.TextXAlignment.Left
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(39,39)
close.Position = UDim2.new(1,-48,0,8)
close.Text = "X"
close.TextSize = 20
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.new(1,1,1)
close.BackgroundColor3 = Color3.fromRGB(180,60,60)
close.Parent = panel
corner(close,8)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(15,60)
scroll.Size = UDim2.new(1,-30,1,-74)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.fromOffset(0,0)
scroll.Parent = panel
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.48,-4,0,155)
grid.CellPadding = UDim2.new(0.025,0,0,10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

for i, key in ipairs(Config.Order) do
    local pass = Config.Passes[key]
    local card = Instance.new("Frame")
    card.LayoutOrder = i
    card.BackgroundColor3 = Color3.fromRGB(44,49,57)
    card.Parent = scroll
    corner(card, 10)
    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(1,0,0,6)
    strip.BackgroundColor3 = pass.Color
    strip.Parent = card
    corner(strip,5)
    local name = label(card,pass.Name,17)
    name.Position = UDim2.fromOffset(5,15)
    name.Size = UDim2.new(1,-10,0,26)
    local desc = label(card,pass.Description,12,Color3.fromRGB(185,190,199))
    desc.Position = UDim2.fromOffset(7,47)
    desc.Size = UDim2.new(1,-14,0,36)
    desc.TextWrapped = true
    local buy = Instance.new("TextButton")
    buy.Position = UDim2.new(0,12,1,-49)
    buy.Size = UDim2.new(1,-24,0,38)
    buy.BackgroundColor3 = pass.Color
    buy.TextColor3 = Color3.new(1,1,1)
    buy.TextSize = 16
    buy.Font = Enum.Font.GothamBold
    buy.Parent = card
    corner(buy,8)
    local function update()
        if pass.Id <= 0 then
            buy.Text = "COMING SOON"
            buy.BackgroundColor3 = Color3.fromRGB(90,95,103)
        elseif player:GetAttribute("Gamepass_" .. key) == true or (key == "PetEquip" and player:GetAttribute("HasPetEquipGamepass") == true) then
            buy.Text = "OWNED"
            buy.BackgroundColor3 = Color3.fromRGB(55,145,78)
        else
            buy.Text = "BUY"
            buy.BackgroundColor3 = pass.Color
        end
    end
    player:GetAttributeChangedSignal("Gamepass_" .. key):Connect(update)
    if key == "PetEquip" then player:GetAttributeChangedSignal("HasPetEquipGamepass"):Connect(update) end
    update()
    buy.MouseButton1Click:Connect(function()
        if pass.Id <= 0 or player:GetAttribute("Gamepass_" .. key) == true or (key == "PetEquip" and player:GetAttribute("HasPetEquipGamepass") == true) then return end
        MarketplaceService:PromptGamePassPurchase(player, pass.Id)
    end)
    task.spawn(function()
        if pass.Id <= 0 then return end
        local ok, info = pcall(function() return MarketplaceService:GetProductInfo(pass.Id, Enum.InfoType.GamePass) end)
        if ok and info and info.PriceInRobux then
            local price = info.PriceInRobux
            local function refresh()
                if player:GetAttribute("Gamepass_" .. key) ~= true and not (key == "PetEquip" and player:GetAttribute("HasPetEquipGamepass") == true) then
                    buy.Text = tostring(price) .. " R$"
                end
            end
            player:GetAttributeChangedSignal("Gamepass_" .. key):Connect(refresh)
            refresh()
        end
    end)
end
shopButton.MouseButton1Click:Connect(function() shade.Visible = not shade.Visible end)
close.MouseButton1Click:Connect(function() shade.Visible = false end)

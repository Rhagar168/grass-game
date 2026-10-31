-- Compact owned-gamepass badges in the bottom-left corner.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("GamepassConfig"))
local gui = Instance.new("ScreenGui")
gui.Name = "OwnedGamepassHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 12
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.Name = "Icons"
holder.AnchorPoint = Vector2.new(0,1)
holder.Position = UDim2.new(0,16,1,-20)
holder.Size = UDim2.fromOffset(340,58)
holder.BackgroundTransparency = 1
holder.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0,8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = holder

local tooltip = Instance.new("Frame")
tooltip.Name = "GamepassTooltip"
tooltip.AnchorPoint = Vector2.new(0,1)
tooltip.Size = UDim2.fromOffset(320,108)
tooltip.BackgroundColor3 = Color3.fromRGB(24,30,34)
tooltip.BorderSizePixel = 0
tooltip.Visible = false
tooltip.ZIndex = 30
tooltip.Parent = gui
local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0,9)
tooltipCorner.Parent = tooltip
local tooltipStroke = Instance.new("UIStroke")
tooltipStroke.Thickness = 1.5
tooltipStroke.Parent = tooltip
local tooltipTitle = Instance.new("TextLabel")
tooltipTitle.Name = "Title"
tooltipTitle.BackgroundTransparency = 1
tooltipTitle.Position = UDim2.fromOffset(14,10)
tooltipTitle.Size = UDim2.new(1,-28,0,34)
tooltipTitle.Font = Enum.Font.Michroma
tooltipTitle.TextSize = 20
tooltipTitle.TextColor3 = Color3.fromRGB(255,255,255)
tooltipTitle.TextXAlignment = Enum.TextXAlignment.Left
tooltipTitle.ZIndex = 31
tooltipTitle.Parent = tooltip
local tooltipDescription = Instance.new("TextLabel")
tooltipDescription.Name = "Description"
tooltipDescription.BackgroundTransparency = 1
tooltipDescription.Position = UDim2.fromOffset(14,47)
tooltipDescription.Size = UDim2.new(1,-28,0,50)
tooltipDescription.Font = Enum.Font.Michroma
tooltipDescription.TextSize = 15
tooltipDescription.TextColor3 = Color3.fromRGB(215,225,222)
tooltipDescription.TextXAlignment = Enum.TextXAlignment.Left
tooltipDescription.TextYAlignment = Enum.TextYAlignment.Center
tooltipDescription.TextWrapped = true
tooltipDescription.ZIndex = 31
tooltipDescription.Parent = tooltip

local function showTooltip(badge, pass)
    if not badge.Visible or not holder.Visible then return end
    tooltipTitle.Text = pass.Name
    tooltipDescription.Text = pass.Description
    tooltipStroke.Color = pass.Color
    local viewportWidth = gui.AbsoluteSize.X
    local x = math.clamp(badge.AbsolutePosition.X, 8, math.max(8, viewportWidth - tooltip.AbsoluteSize.X - 8))
    local y = badge.AbsolutePosition.Y - 10
    tooltip.Position = UDim2.fromOffset(x,y)
    tooltip.Visible = true
end

local badges = {}
for index,key in ipairs(config.Order) do
    local pass = config.Passes[key]
    local badge = Instance.new("ImageLabel")
    badge.Name = key
    badge.LayoutOrder = index
    badge.Size = UDim2.fromOffset(50,50)
    badge.BackgroundColor3 = Color3.fromRGB(26,32,36)
    badge.BackgroundTransparency = 0.08
    badge.Image = "rbxthumb://type=GamePass&id=" .. tostring(pass.Id) .. "&w=150&h=150"
    badge.ScaleType = Enum.ScaleType.Fit
    badge.Visible = false
    badge.Parent = holder
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,9)
    corner.Parent = badge
    local border = Instance.new("UIStroke")
    border.Color = pass.Color
    border.Thickness = 1.5
    border.Parent = badge
    badge.MouseEnter:Connect(function() showTooltip(badge,pass) end)
    badge.MouseLeave:Connect(function() tooltip.Visible = false end)
    badges[key] = badge
    local function refresh()
        badge.Visible = player:GetAttribute("Gamepass_" .. key) == true
            or (key == "PetEquip" and player:GetAttribute("HasPetEquipGamepass") == true)
    end
    player:GetAttributeChangedSignal("Gamepass_" .. key):Connect(refresh)
    if key == "PetEquip" then
        player:GetAttributeChangedSignal("HasPetEquipGamepass"):Connect(refresh)
    end
    refresh()
end

-- Hide badges while the shop is open; return after closing.
local function watchShop(shop)
    if not shop:IsA("ScreenGui") or shop.Name ~= "GamepassShop" then return end
    local shade = shop:FindFirstChildWhichIsA("Frame")
    if not shade then
        shade = shop:WaitForChild("Frame",5)
    end
    if not shade then return end
    local function refresh()
        holder.Visible = not shade.Visible
        if shade.Visible then tooltip.Visible = false end
    end
    shade:GetPropertyChangedSignal("Visible"):Connect(refresh)
    refresh()
end
local pg = player:WaitForChild("PlayerGui")
pg.ChildAdded:Connect(function(child)
    if child.Name == "GamepassShop" then
        task.defer(watchShop,child)
    end
end)
for _, child in ipairs(pg:GetChildren()) do
    if child.Name == "GamepassShop" then task.defer(watchShop,child) end
end

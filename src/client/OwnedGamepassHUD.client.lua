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

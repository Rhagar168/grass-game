local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("PetConfig"))
local buy = ReplicatedStorage:WaitForChild("BuyPetUpgrade")
local boards = workspace:WaitForChild("Boards")
local tundra = boards:WaitForChild("Tundra")
local board = tundra:WaitForChild("PetsUpgrades")
-- Imported Cube is a Model, not a display Part. Use a dedicated invisible
-- rectangular screen in front of the imported board rather than guessing
-- which of its MeshParts represents the screen.
local cube = board:FindFirstChild("Cube")
if not cube then warn("[PetUpgrades] Missing Cube model") return end
local boundsCF, boundsSize = cube:GetBoundingBox()
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("PetUpgradeSurface")
if old then old:Destroy() end
local oldPanel = board:FindFirstChild("PetUpgradeDisplay")
if oldPanel then oldPanel:Destroy() end
local panel = Instance.new("Part")
panel.Name = "PetUpgradeDisplay"
panel.Anchored = true
panel.CanCollide = false
panel.CanTouch = false
panel.CanQuery = false
panel.Transparency = 1
panel.Size = Vector3.new(math.max(7, boundsSize.X * 0.78), math.max(3.5, boundsSize.Y * 0.65), 0.08)
panel.CFrame = boundsCF * CFrame.new(0, 0, -boundsSize.Z * 0.5 - 0.25)
panel.Parent = board
local gui = Instance.new("SurfaceGui")
gui.Name = "PetUpgradeSurface"
gui.Face = Enum.NormalId.Front
gui.Enabled = true
gui.Active = true
gui.AlwaysOnTop = true
gui.LightInfluence = 0
gui.Adornee = panel
gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
gui.CanvasSize = Vector2.new(1100, 520)
gui.Parent = playerGui
local original = cube:FindFirstChildOfClass("SurfaceGui")
if original then original.Enabled = false end
print("[PetUpgrades] Dedicated display created:", panel:GetFullName(), "size:", panel.Size)

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(12, 22, 33)
bg.BorderSizePixel = 0
bg.Parent = gui
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.20, 0)
title.BackgroundTransparency = 1
title.Text = "PET UPGRADES"
title.TextColor3 = Color3.fromRGB(155, 225, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Parent = bg
local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromScale(0.03, 0.24)
scroll.Size = UDim2.fromScale(0.94, 0.72)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 9
scroll.ScrollingDirection = Enum.ScrollingDirection.X
scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = bg
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 14)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll
local function label(parent, y, height, size, color, font)
    local obj = Instance.new("TextLabel")
    obj.BackgroundTransparency = 1
    obj.Position = UDim2.fromScale(0.04, y)
    obj.Size = UDim2.fromScale(0.92, height)
    obj.TextColor3 = color
    obj.TextScaled = true
    obj.Font = font or Enum.Font.GothamBold
    obj.Parent = parent
    return obj
end
local order = {"Damage", "Speed", "AttackSpeed", "Equip"}
for i, id in ipairs(order) do
    local info = config.Upgrades[id]
    local card = Instance.new("Frame")
    card.Name = id
    card.LayoutOrder = i
    card.Size = UDim2.new(0, 240, 0.94, 0)
    card.BackgroundColor3 = Color3.fromRGB(25, 42, 57)
    card.BorderSizePixel = 0
    card.Parent = scroll
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(58, 153, 212)
    stroke.Thickness = 2
    stroke.Parent = card
    local name = label(card, 0.06, 0.20, 18, Color3.fromRGB(210, 244, 255), Enum.Font.GothamBlack)
    name.Text = info.Title
    local desc = label(card, 0.30, 0.16, 14, Color3.fromRGB(171, 191, 208))
    desc.Text = info.Description
    local level = label(card, 0.51, 0.14, 17, Color3.fromRGB(255, 255, 255))
    local button = Instance.new("TextButton")
    button.Position = UDim2.fromScale(0.07, 0.72)
    button.Size = UDim2.fromScale(0.86, 0.22)
    button.BackgroundColor3 = Color3.fromRGB(45, 152, 101)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = card
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    local function refresh()
        local current = player:GetAttribute("Pet" .. id .. "Level") or 0
        level.Text = "LEVEL " .. current .. " / " .. info.Max
        if current >= info.Max then
            button.Text = "MAX LEVEL"
            button.BackgroundColor3 = Color3.fromRGB(68, 90, 105)
        else
            local price = config.UpgradeCost(id, current)
            button.Text = "BUY  •  " .. price .. " RT"
            button.BackgroundColor3 = (player:GetAttribute("ResetTokens") or 0) >= price
                and Color3.fromRGB(45, 152, 101) or Color3.fromRGB(120, 73, 75)
        end
    end
    button.MouseButton1Click:Connect(function()
        if (player:GetAttribute("Pet" .. id .. "Level") or 0) < info.Max then buy:FireServer(id) end
    end)
    player:GetAttributeChangedSignal("Pet" .. id .. "Level"):Connect(refresh)
    player:GetAttributeChangedSignal("ResetTokens"):Connect(refresh)
    refresh()
end

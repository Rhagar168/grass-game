-- Run ONCE in Roblox Studio Command Bar in EDIT mode, then save.
local board = workspace:WaitForChild("Boards"):WaitForChild("Tundra"):WaitForChild("PetsUpgrades")
local cube = board:WaitForChild("Cube")
local display, bestArea = nil, -1
for _, part in ipairs(cube:GetDescendants()) do
    if part:IsA("BasePart") then
        local dimensions = {part.Size.X, part.Size.Y, part.Size.Z}
        table.sort(dimensions, function(a,b) return a > b end)
        local area = dimensions[1] * dimensions[2]
        if area > bestArea then display, bestArea = part, area end
    end
end
assert(display, "No MeshPart inside Cube model")
local old = board:FindFirstChild("PetUpgradeSurface", true)
if old then old:Destroy() end
local original = cube:FindFirstChildOfClass("SurfaceGui")
if original then original.Enabled = false end

local gui = Instance.new("SurfaceGui")
gui.Name = "PetUpgradeSurface"
gui.Face = original and original.Face or Enum.NormalId.Front
gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
gui.CanvasSize = Vector2.new(1200, 620)
gui.LightInfluence = 0
gui.Active = true
gui.Enabled = true
gui.Parent = display

local function round(parent, radius)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, radius)
    u.Parent = parent
end
local function text(parent, name, content, pos, size, fontSize, color, font)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Position = pos
    l.Size = size
    l.BackgroundTransparency = 1
    l.Text = content
    l.TextColor3 = color
    l.TextSize = fontSize
    l.Font = font or Enum.Font.GothamBold
    l.Parent = parent
    return l
end
local bg = Instance.new("Frame")
bg.Name = "Background"
bg.Size = UDim2.fromScale(1, 1)
bg.BorderSizePixel = 0
bg.BackgroundColor3 = Color3.fromRGB(9, 22, 34)
bg.Parent = gui
local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(60, 174, 225)
outline.Thickness = 5
outline.Parent = bg
text(bg, "Title", "PET UPGRADES", UDim2.fromScale(0, 0.03), UDim2.fromScale(1, 0.15), 58, Color3.fromRGB(188, 237, 255), Enum.Font.GothamBlack)
text(bg, "Hint", "SPEND RESET TOKENS TO UPGRADE YOUR PETS", UDim2.fromScale(0, 0.17), UDim2.fromScale(1, 0.07), 22, Color3.fromRGB(141, 166, 181))
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "UpgradeScroll"
scroll.Position = UDim2.fromScale(0.035, 0.29)
scroll.Size = UDim2.fromScale(0.93, 0.65)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 12
scroll.ScrollingDirection = Enum.ScrollingDirection.X
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
scroll.Parent = bg
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 22)
layout.Parent = scroll
local items = {
    {"Damage", "PET DAMAGE", "+15% DAMAGE / LEVEL", 10},
    {"Speed", "PET SPEED", "+10% SPEED / LEVEL", 10},
    {"AttackSpeed", "ATTACK SPEED", "+8% ATTACK SPEED / LEVEL", 10},
    {"Equip", "PET EQUIP", "+1 EQUIPPED PET / LEVEL", 2},
}
for i, item in ipairs(items) do
    local id, title, desc, max = unpack(item)
    local card = Instance.new("Frame")
    card.Name = id
    card.LayoutOrder = i
    card.Size = UDim2.fromOffset(355, 360)
    card.BackgroundColor3 = Color3.fromRGB(26, 48, 67)
    card.BorderSizePixel = 0
    card.Parent = scroll
    round(card, 16)
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(66, 157, 215)
    border.Thickness = 3
    border.Parent = card
    text(card, "Name", title, UDim2.fromScale(0.05, 0.06), UDim2.fromScale(0.9, 0.18), 31, Color3.fromRGB(225, 248, 255), Enum.Font.GothamBlack)
    text(card, "Description", desc, UDim2.fromScale(0.05, 0.31), UDim2.fromScale(0.9, 0.13), 19, Color3.fromRGB(170, 197, 216))
    text(card, "Level", "LEVEL 0 / " .. max, UDim2.fromScale(0.05, 0.51), UDim2.fromScale(0.9, 0.14), 26, Color3.new(1, 1, 1))
    local button = Instance.new("TextButton")
    button.Name = "Buy"
    button.Position = UDim2.fromScale(0.08, 0.74)
    button.Size = UDim2.fromScale(0.84, 0.2)
    button.BackgroundColor3 = Color3.fromRGB(36, 159, 105)
    button.Text = "BUY"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 26
    button.Font = Enum.Font.GothamBlack
    button.Parent = card
    round(button, 10)
end
print("[PetUpgrades] GUI created on", display:GetFullName(), "Face", gui.Face.Name, "- SAVE the place!")

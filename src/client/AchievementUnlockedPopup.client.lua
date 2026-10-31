local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("AchievementConfig"))

local gui = Instance.new("ScreenGui")
gui.Name = "AchievementUnlockedPopup"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 90
gui.Parent = player:WaitForChild("PlayerGui")

local queue = {}
local showing = false
local completed = {}
local ready = false

local function label(parent, text, size, color, y, height)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Position = UDim2.new(0, 72, 0, y)
    item.Size = UDim2.new(1, -88, 0, height)
    item.Font = Enum.Font.GothamBold
    item.Text = text
    item.TextSize = size
    item.TextColor3 = color
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextTruncate = Enum.TextTruncate.AtEnd
    item.Parent = parent
    return item
end

local function show(entry)
    local panel = Instance.new("Frame")
    panel.Name = "AchievementCard"
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.Position = UDim2.new(0.5, 0, 0, -120)
    panel.Size = UDim2.fromOffset(390, 104)
    panel.BackgroundColor3 = Color3.fromRGB(23, 29, 40)
    panel.BorderSizePixel = 0
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 205, 79)
    stroke.Thickness = 2
    stroke.Parent = panel

    local icon = Instance.new("TextLabel")
    icon.BackgroundColor3 = Color3.fromRGB(85, 65, 28)
    icon.Position = UDim2.fromOffset(13, 17)
    icon.Size = UDim2.fromOffset(52, 65)
    icon.Font = Enum.Font.GothamBlack
    icon.Text = "★"
    icon.TextSize = 35
    icon.TextColor3 = Color3.fromRGB(255, 217, 97)
    icon.Parent = panel
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 10)

    label(panel, "ACHIEVEMENT UNLOCKED!", 16, Color3.fromRGB(255, 213, 94), 10, 23)
    label(panel, entry.Title or "ACHIEVEMENT", 17, Color3.fromRGB(255, 255, 255), 37, 24)
    label(panel, "REWARD: " .. (entry.Reward or "UNLOCKED"), 13, Color3.fromRGB(126, 240, 171), 70, 21)

    TweenService:Create(panel, TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 75)
    }):Play()
    task.wait(3.4)
    local exit = TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 0, -120)
    })
    exit:Play()
    exit.Completed:Wait()
    panel:Destroy()
end

local function drain()
    if showing then return end
    showing = true
    while #queue > 0 do
        show(table.remove(queue, 1))
    end
    showing = false
end

local function check()
    if not ready then return end
    for id, entry in pairs(config.ById) do
        if not completed[id] and config.IsComplete(player, entry) then
            completed[id] = true
            if player:GetAttribute(config.ClaimAttribute(id)) ~= true then
                table.insert(queue, entry)
            end
        end
    end
    if #queue > 0 then task.spawn(drain) end
end

local function initialize()
    if ready or player:GetAttribute("DataLoaded") ~= true then return end
    -- Saved progress must not trigger unlock popups on joining.
    for id, entry in pairs(config.ById) do
        completed[id] = config.IsComplete(player, entry)
    end
    ready = true
    local watched = {}
    for _, entry in pairs(config.ById) do
        if not watched[entry.Attribute] then
            watched[entry.Attribute] = true
            player:GetAttributeChangedSignal(entry.Attribute):Connect(check)
        end
    end
    player:GetAttributeChangedSignal("GoldGrassFound"):Connect(check)
    player:GetAttributeChangedSignal("RainbowGrassFound"):Connect(check)
end

player:GetAttributeChangedSignal("DataLoaded"):Connect(initialize)
initialize()

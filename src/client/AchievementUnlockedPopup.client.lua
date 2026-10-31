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
    local popup = Instance.new("TextLabel")
    popup.Name = "AchievementText"
    popup.AnchorPoint = Vector2.new(0.5, 0)
    popup.Position = UDim2.new(0.5, 0, 0, -80)
    popup.Size = UDim2.new(0.85, 0, 0, 55)
    popup.BackgroundTransparency = 1
    popup.Font = Enum.Font.GothamBold
    popup.Text = "★  " .. (entry.Title or "ACHIEVEMENT")
    popup.TextSize = 26
    popup.TextColor3 = Color3.fromRGB(255, 216, 65)
    popup.TextStrokeTransparency = 0.65
    popup.TextXAlignment = Enum.TextXAlignment.Center
    popup.TextTruncate = Enum.TextTruncate.AtEnd
    popup.Parent = gui

    TweenService:Create(popup, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 75)
    }):Play()
    task.wait(3.4)
    local exit = TweenService:Create(popup, TweenInfo.new(0.4), {
        Position = UDim2.new(0.5, 0, 0, 35),
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    exit:Play()
    exit.Completed:Wait()
    popup:Destroy()
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

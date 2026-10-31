local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local lastResets = tonumber(player:GetAttribute("TotalResets")) or 0

local function celebrate(newTotal)
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "ResetCelebration"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    gui.Parent = playerGui

    local flash = Instance.new("Frame")
    flash.Size = UDim2.fromScale(1, 1)
    flash.BackgroundColor3 = Color3.fromRGB(255, 218, 115)
    flash.BackgroundTransparency = 0.72
    flash.BorderSizePixel = 0
    flash.Parent = gui
    TweenService:Create(flash, TweenInfo.new(1.1), {BackgroundTransparency = 1}):Play()

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.fromScale(0.5, 0.38)
    title.Size = UDim2.fromOffset(180, 45)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = "RESET!"
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(255, 217, 65)
    title.TextStrokeColor3 = Color3.fromRGB(80, 40, 5)
    title.TextStrokeTransparency = 0.05
    title.Parent = gui

    local subtitle = Instance.new("TextLabel")
    subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
    subtitle.Position = UDim2.fromScale(0.5, 0.47)
    subtitle.Size = UDim2.fromOffset(280, 36)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = "TOTAL RESETS: " .. tostring(newTotal)
    subtitle.TextScaled = true
    subtitle.TextColor3 = Color3.fromRGB(255, 245, 200)
    subtitle.TextStrokeTransparency = 0.25
    subtitle.Parent = gui

    TweenService:Create(title, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(330, 85)
    }):Play()

    for i = 1, 12 do
        local particle = Instance.new("TextLabel")
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.Position = UDim2.fromScale(0.5, 0.4)
        particle.Size = UDim2.fromOffset(18, 18)
        particle.BackgroundTransparency = 1
        particle.Text = "✦"
        particle.Font = Enum.Font.GothamBold
        particle.TextScaled = true
        particle.TextColor3 = Color3.fromRGB(255, 220, 95)
        particle.Parent = gui
        local angle = 2 * math.pi * i / 12
        TweenService:Create(particle, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, math.cos(angle) * 220, 0.4, math.sin(angle) * 145),
            TextTransparency = 1
        }):Play()
    end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://93360393539898"
    sound.Volume = 0.12
    sound.Parent = SoundService
    sound:Play()

    task.delay(2.3, function()
        for _, label in ipairs({title, subtitle}) do
            TweenService:Create(label, TweenInfo.new(0.7), {
                TextTransparency = 1,
                TextStrokeTransparency = 1
            }):Play()
        end
    end)
    task.delay(3.2, function()
        gui:Destroy()
    end)
    task.delay(6, function()
        sound:Destroy()
    end)
end

player:GetAttributeChangedSignal("TotalResets"):Connect(function()
    local total = tonumber(player:GetAttribute("TotalResets")) or 0
    if total > lastResets then
        task.spawn(celebrate, total)
    end
    lastResets = total
end)

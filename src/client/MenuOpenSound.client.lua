-- Gentle UI pop when opening a menu from the main HUD icons.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local mainUI = playerGui:WaitForChild("MainUI")

local template = Instance.new("Sound")
template.Name = "MenuOpenPop"
template.SoundId = "rbxasset://sounds/button.wav"
template.Volume = 0.22
template.PlaybackSpeed = 1.15
template.Parent = SoundService

local lastPlayed = 0
local function playPop()
    if os.clock() - lastPlayed < 0.12 then return end
    lastPlayed = os.clock()
    local sound = template:Clone()
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Once(function() sound:Destroy() end)
    task.delay(3, function()
        if sound.Parent then sound:Destroy() end
    end)
end

local attached = {}
local function attach(button)
    if not button:IsA("GuiButton") or attached[button] then return end
    if button.Name == "CloseButton" or button.Name == "Close" then return end
    attached[button] = true
    button.Activated:Connect(playPop)
end

-- Only main navigation icons, not every purchase, toggle or inventory item.
for _, name in ipairs({"BottomMenu", "RightMenu"}) do
    local menu = mainUI:FindFirstChild(name) or mainUI:WaitForChild(name, 15)
    if menu then
        for _, item in ipairs(menu:GetDescendants()) do attach(item) end
        menu.DescendantAdded:Connect(attach)
    end
end

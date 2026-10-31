-- Shared click sound for every interactive GUI button.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local clickSound = Instance.new("Sound")
clickSound.Name = "GlobalUIClick"
clickSound.SoundId = "rbxassetid://17779566040"
clickSound.Volume = 0.18
clickSound.Parent = SoundService

local menuSound = Instance.new("Sound")
menuSound.Name = "MenuOpenPop"
menuSound.SoundId = "rbxasset://sounds/button.wav"
menuSound.Volume = 0.22
menuSound.PlaybackSpeed = 1.15
menuSound.Parent = SoundService

local attached = {}
local function attach(instance)
    if not instance:IsA("GuiButton") or attached[instance] then return end
    attached[instance] = true
    instance.Activated:Connect(function()
        -- Restart on each click, including rapid clicks.
        local mainUI = playerGui:FindFirstChild("MainUI")
        local isMenuIcon = false
        if mainUI then
            for _, menuName in ipairs({"BottomMenu", "RightMenu"}) do
                local menu = mainUI:FindFirstChild(menuName)
                if menu and instance:IsDescendantOf(menu) then
                    isMenuIcon = true
                    break
                end
            end
        end
        local sound = isMenuIcon and menuSound or clickSound
        sound.TimePosition = 0
        sound:Play()
    end)
end

for _, descendant in ipairs(playerGui:GetDescendants()) do
    attach(descendant)
end
playerGui.DescendantAdded:Connect(attach)

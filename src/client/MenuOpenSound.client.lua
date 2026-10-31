-- Shared click sound for every interactive GUI button.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local clickSound = Instance.new("Sound")
clickSound.Name = "GlobalUIClick"
clickSound.SoundId = "rbxassetid://17779566040"
clickSound.Volume = 0.18
clickSound.Parent = SoundService

local attached = {}
local function attach(instance)
    if not instance:IsA("GuiButton") or attached[instance] then return end
    attached[instance] = true
    instance.Activated:Connect(function()
        -- Restart on each click, including rapid clicks.
        clickSound.TimePosition = 0
        clickSound:Play()
    end)
end

for _, descendant in ipairs(playerGui:GetDescendants()) do
    attach(descendant)
end
playerGui.DescendantAdded:Connect(attach)

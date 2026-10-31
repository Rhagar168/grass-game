local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local sound = Instance.new("Sound")
sound.Name = "ToolUpgradePurchaseSound"
sound.SoundId = "rbxassetid://98911839276314"
sound.Volume = 0.35
sound.Parent = SoundService

ReplicatedStorage:WaitForChild("ToolUpgradeSuccess").OnClientEvent:Connect(function()
    sound.TimePosition = 0
    sound:Play()
end)

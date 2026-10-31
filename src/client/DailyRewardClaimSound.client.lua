local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Play only after the server confirms a successful daily reward claim.
local resultEvent = ReplicatedStorage:WaitForChild("DailyRewardResult")

local claimSound = Instance.new("Sound")
claimSound.Name = "DailyRewardClaimSound"
claimSound.SoundId = "rbxassetid://80854650043151"
claimSound.Volume = 0.12
claimSound.Parent = SoundService

resultEvent.OnClientEvent:Connect(function()
    claimSound:Play()
end)

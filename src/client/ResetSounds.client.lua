-- Reset feedback: a soft pop on success and a short ascending sparkle
-- while the grass grows back. Uses Roblox's built-in sound assets.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local resetRewardAnimation = ReplicatedStorage:WaitForChild("ResetRewardAnimation")

local pop = Instance.new("Sound")
pop.Name = "ResetPop"
pop.SoundId = "rbxasset://sounds/button.wav"
pop.Volume = 0.45
pop.PlaybackSpeed = 0.85
pop.Parent = SoundService

local function sparkle(speed)
    local sound = Instance.new("Sound")
    sound.Name = "ResetGrassSparkle"
    sound.SoundId = "rbxasset://sounds/button.wav"
    sound.Volume = 0.12
    sound.PlaybackSpeed = speed
    sound.Parent = SoundService
    sound.Ended:Once(function() sound:Destroy() end)
    sound:Play()
    task.delay(3, function()
        if sound.Parent then sound:Destroy() end
    end)
end

local sequence = 0
resetRewardAnimation.OnClientEvent:Connect(function()
    sequence += 1
    local thisSequence = sequence
    pop:Play()
    -- Light, fast "tinini-tin" notes matching the 1.5s grass grow animation.
    task.spawn(function()
        task.wait(0.18)
        for i = 1, 9 do
            if thisSequence ~= sequence then return end
            sparkle(1.15 + (i % 5) * 0.14)
            task.wait(0.13)
        end
    end)
end)

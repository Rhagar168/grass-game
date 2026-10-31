-- Client-side volume control for game sound effects.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer

local group = SoundService:FindFirstChild("GrassSimulatorSFXGroup")
if not group then
    group = Instance.new("SoundGroup")
    group.Name = "GrassSimulatorSFXGroup"
    group.Parent = SoundService
end

local function refresh()
    local enabled = player:GetAttribute("Setting_SoundEffects") ~= false
    local percent = math.clamp(player:GetAttribute("Setting_SFXVolume") or 100, 0, 100)
    group.Volume = enabled and percent / 100 or 0
end

local function attach(sound)
    if not sound:IsA("Sound") then return end
    if sound.Name == "GrassSimulatorBackgroundMusic" then return end
    -- Preserve any pre-existing custom SoundGroup routing.
    if sound.SoundGroup == nil then
        sound.SoundGroup = group
    end
end

for _, root in ipairs({SoundService, workspace, player:WaitForChild("PlayerGui")}) do
    for _, descendant in ipairs(root:GetDescendants()) do
        attach(descendant)
    end
    root.DescendantAdded:Connect(attach)
end

player:GetAttributeChangedSignal("Setting_SoundEffects"):Connect(refresh)
player:GetAttributeChangedSignal("Setting_SFXVolume"):Connect(refresh)
refresh()

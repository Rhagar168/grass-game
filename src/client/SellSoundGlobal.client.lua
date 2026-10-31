-- Make the existing selling sound audible from anywhere.
-- The sound may be attached to a part in Workspace; use a large full-volume
-- rolloff radius rather than changing its playback or triggering it twice.
local Workspace = game:GetService("Workspace")

local SELL_SOUND_ID = "107132538017055"

local function configure(sound)
    if not sound:IsA("Sound") then return end
    if not string.find(sound.SoundId, SELL_SOUND_ID, 1, true) then return end

    -- A non-spatial sound (SoundService/PlayerGui) already plays everywhere.
    -- For sounds under Workspace, keep their existing trigger and remove
    -- the near-camera requirement.
    if sound:IsDescendantOf(Workspace) then
        sound.Volume = sound.Volume * 0.7
        sound.RollOffMode = Enum.RollOffMode.Linear
        sound.RollOffMinDistance = 100000
        sound.RollOffMaxDistance = 100001
    end
end

for _, instance in ipairs(Workspace:GetDescendants()) do
    configure(instance)
end

Workspace.DescendantAdded:Connect(configure)

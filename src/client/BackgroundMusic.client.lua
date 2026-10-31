-- Quiet, non-positional background playlist for Grass Simulator.
-- Tracks must be available to this experience through Roblox audio permissions.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local TRACK_IDS = {
    9048039288,
    140439107589392,
    127020790013403,
    115822380193049,
    84833494984135,
    126255923222769,
}
local TARGET_VOLUME = 0.30 -- intentionally very quiet background music
local FADE_SECONDS = 2
local PAUSE_MIN, PAUSE_MAX = 3, 5
local MAX_TRACK_SECONDS = 420
local rng = Random.new()

local music = Instance.new("Sound")
music.Name = "GrassSimulatorBackgroundMusic"
music.Volume = 0
music.Looped = false
music.Parent = SoundService

local previousIndex
local function chooseTrack()
    if #TRACK_IDS == 1 then return 1 end
    local index
    repeat
        index = rng:NextInteger(1, #TRACK_IDS)
    until index ~= previousIndex
    previousIndex = index
    return index
end

local function fadeTo(volume)
    local tween = TweenService:Create(music, TweenInfo.new(FADE_SECONDS, Enum.EasingStyle.Sine), {Volume = volume})
    tween:Play()
    tween.Completed:Wait()
end

while true do
    music.SoundId = "rbxassetid://" .. TRACK_IDS[chooseTrack()]
    music.Volume = 0
    local loaded = false
    local connection = music.Loaded:Connect(function()
        loaded = true
    end)
    local deadline = os.clock() + 12
    while not music.IsLoaded and not loaded and os.clock() < deadline do
        task.wait(0.2)
    end
    connection:Disconnect()

    if music.IsLoaded then
        music:Play()
        fadeTo(TARGET_VOLUME)
        local started = os.clock()
        while music.IsPlaying and os.clock() - started < MAX_TRACK_SECONDS do
            task.wait(0.25)
        end
        if music.IsPlaying then
            fadeTo(0)
            music:Stop()
        end
    else
        warn("[BackgroundMusic] Could not load audio " .. music.SoundId .. " (check Creator Store permissions)")
    end
    task.wait(rng:NextInteger(PAUSE_MIN, PAUSE_MAX))
end

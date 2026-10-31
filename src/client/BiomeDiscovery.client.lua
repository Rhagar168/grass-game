-- Client-only biome discovery announcement. Does not change unlocks or progression.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local names = {
    Plains = "PLAINS", Savanna = "SAVANNA", Tundra = "TUNDRA",
    Beach = "BEACH", Jungle = "JUNGLE", Ancient = "FOREST",
    Forest = "FOREST", Molten = "MOLTEN", Volcano = "MOLTEN",
}
local seen = {}
local discoveryEvent = ReplicatedStorage:WaitForChild("BiomeDiscoveryEvent")
local current = nil
local running = false
local queue = {}
local ready = false

local gui = Instance.new("ScreenGui")
gui.Name = "BiomeDiscovery"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 85
gui.Parent = player:WaitForChild("PlayerGui")

local function announce(name)
    local sound = Instance.new("Sound")
    sound.Name = "BiomeDiscoverySound"
    sound.SoundId = "rbxassetid://5402177459"
    sound.Volume = 0.6
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Once(function() sound:Destroy() end)
    task.delay(10, function()
        if sound.Parent then sound:Destroy() end
    end)
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.fromScale(0.5, 0.38)
    title.Size = UDim2.new(0.9, 0, 0, 90)
    title.Font = Enum.Font.GothamBlack
    title.Text = name
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextTransparency = 1
    title.TextStrokeTransparency = 1
    title.Parent = gui

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
    subtitle.Position = UDim2.fromScale(0.5, 0.31)
    subtitle.Size = UDim2.new(0.9, 0, 0, 40)
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = "NEW BIOME DISCOVERED"
    subtitle.TextSize = 26
    subtitle.TextColor3 = Color3.fromRGB(255, 214, 91)
    subtitle.TextTransparency = 1
    subtitle.Parent = gui

    TweenService:Create(title, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        TextTransparency = 0, TextStrokeTransparency = 0.65,
        Position = UDim2.fromScale(0.5, 0.44)
    }):Play()
    TweenService:Create(subtitle, TweenInfo.new(0.45), {TextTransparency = 0}):Play()
    task.wait(2.7)
    local fade = TweenService:Create(title, TweenInfo.new(0.65), {TextTransparency = 1, TextStrokeTransparency = 1})
    fade:Play()
    TweenService:Create(subtitle, TweenInfo.new(0.65), {TextTransparency = 1}):Play()
    fade.Completed:Wait()
    title:Destroy()
    subtitle:Destroy()
end

local function drain()
    if running then return end
    running = true
    while #queue > 0 do announce(table.remove(queue, 1)) end
    running = false
end

-- Use the ground under the player, so neighboring biomes do not trigger early.
local function biomeAt(root)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    local hit = workspace:Raycast(root.Position + Vector3.new(0, 3, 0), Vector3.new(0, -35, 0), params)
    if not hit then return nil end
    local node = hit.Instance
    while node and node ~= workspace do
        if names[node.Name] then return names[node.Name] end
        node = node.Parent
    end
    return nil
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < 0.35 then return end
    elapsed = 0
    if player:GetAttribute("DataLoaded") ~= true then return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local biome = biomeAt(root)
    if not biome then return end
    if not ready then
        ready = true
        for saved in string.gmatch(player:GetAttribute("DiscoveredBiomes") or "", "[^,]+") do
            seen[saved] = true
        end
        -- Never replay the biome occupied at login.
        seen[biome] = true
        current = biome
        return
    end
    if biome == current then return end
    current = biome
    if seen[biome] then return end
    seen[biome] = true
    discoveryEvent:FireServer(biome)
    table.insert(queue, biome)
    task.spawn(drain)
end)

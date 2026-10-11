-- PetFollow.client.lua
-- Client-side visuals for every player's equipped pets.
-- Models must exist in ReplicatedStorage/PetModels with names matching PetConfig IDs.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local templates = ReplicatedStorage:WaitForChild("PetModels")
local MAX_SLOTS = PetConfig.MaxEquipped
local SPACING = 4
local FOLLOW_DISTANCE = 7.5
local SMOOTH_SPEED = 9
local WALK_BOB_SPEED = 9
local WALK_BOB_HEIGHT = 0.13
local FLY_BOB_HEIGHT = 0.35
local FLY_HEIGHT = 2
local NAMEPLATE_HEIGHT = 3.8 -- same world height relative to player for all pets
-- If faces point backwards, change this to math.pi.
local MODEL_YAW_OFFSET = 0

local visualRoot = workspace:FindFirstChild("ClientPetFollowers")
if not visualRoot then
    visualRoot = Instance.new("Folder")
    visualRoot.Name = "ClientPetFollowers"
    visualRoot.Parent = workspace
end

-- Legacy pet visuals are colored balls in Workspace/LocalPets.
-- Remove only their client-side visuals; never touch equipped attributes or damage.
local function hideLegacyPets(folder)
    if not folder:IsA("Folder") or folder.Name ~= "LocalPets" then return end
    for _, child in ipairs(folder:GetChildren()) do
        child:Destroy()
    end
    folder.ChildAdded:Connect(function(child)
        child:Destroy()
    end)
end

local oldFolder = workspace:FindFirstChild("LocalPets")
if oldFolder then hideLegacyPets(oldFolder) end
workspace.ChildAdded:Connect(hideLegacyPets)

local RARITY_COLORS = {
    Common = Color3.fromRGB(195, 205, 215),
    Rare = Color3.fromRGB(80, 170, 255),
    Epic = Color3.fromRGB(190, 110, 255),
    Legendary = Color3.fromRGB(255, 195, 65),
    Mythic = Color3.fromRGB(255, 90, 155),
}

local function makeNameplate(model, id)
    local config = PetConfig.GetPet(id)
    if not config then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PetNameplate"
    billboard.Size = UDim2.fromOffset(145, 42)
    billboard.StudsOffsetWorldSpace = Vector3.zero
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 90
    -- Do not insert a new BasePart: it can change an imported model's pivot/bounds.
    billboard.Parent = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)

    local name = Instance.new("TextLabel")
    name.Name = "PetName"
    name.BackgroundTransparency = 1
    name.Size = UDim2.new(1, 0, 0.52, 0)
    name.Text = config.DisplayName
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextStrokeColor3 = Color3.new(0, 0, 0)
    name.TextStrokeTransparency = 0.1
    name.Font = Enum.Font.GothamBold
    name.TextScaled = true
    name.Parent = billboard

    local rarity = Instance.new("TextLabel")
    rarity.Name = "PetRarity"
    rarity.BackgroundTransparency = 1
    rarity.Position = UDim2.fromScale(0, 0.52)
    rarity.Size = UDim2.new(1, 0, 0.42, 0)
    rarity.Text = config.Rarity
    rarity.TextColor3 = RARITY_COLORS[config.Rarity] or Color3.new(1, 1, 1)
    rarity.TextStrokeColor3 = Color3.new(0, 0, 0)
    rarity.TextStrokeTransparency = 0.1
    rarity.Font = Enum.Font.GothamBold
    rarity.TextScaled = true
    rarity.Parent = billboard

    return billboard
end

local states = {}

local function isFlying(id)
    return id == "SunSpirit" or id == "FrostSpirit" or id == "OceanSpirit"
end

local function clearSlot(state, slot)
    local entry = state.pets[slot]
    if entry then
        entry.model:Destroy()
        state.pets[slot] = nil
    end
end

local function createSlot(state, slot, id)
    clearSlot(state, slot)
    if id == "" or not PetConfig.GetPet(id) then return end

    local template = templates:FindFirstChild(id)
    if not template or not template:IsA("Model") then
        warn("[PetFollow] Missing Model ReplicatedStorage/PetModels/" .. id)
        return
    end

    local model = template:Clone()
    model.Name = state.player.Name .. "_" .. id .. "_" .. slot
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Massless = true
        end
    end
    -- Hide any old nameplates inside imported pet models.
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BillboardGui") then descendant.Enabled = false end
    end
    model.Parent = visualRoot

    local boundsCF, size = model:GetBoundingBox()
    local centerOffset = model:GetPivot():ToObjectSpace(boundsCF)
    local billboard = makeNameplate(model, id)
    print(string.format("[PetFollow] %s size = %.2f, %.2f, %.2f", id, size.X, size.Y, size.Z))
    state.pets[slot] = {
        id = id,
        model = model,
        height = size.Y,
        current = nil,
        centerOffset = centerOffset,
        billboard = billboard,
    }
end

local function sync(state)
    for slot = 1, MAX_SLOTS do
        local id = state.player:GetAttribute("EquippedPet" .. slot) or ""
        local entry = state.pets[slot]
        if not entry or entry.id ~= id then
            createSlot(state, slot, id)
        end
    end
end

local function setupPlayer(player)
    if states[player] then return end
    local state = {player = player, pets = {}, connections = {}}
    states[player] = state

    for slot = 1, MAX_SLOTS do
        table.insert(state.connections,
            player:GetAttributeChangedSignal("EquippedPet" .. slot):Connect(function()
                sync(state)
            end)
        )
    end
    sync(state)
end

local function removePlayer(player)
    local state = states[player]
    if not state then return end
    for _, connection in ipairs(state.connections) do
        connection:Disconnect()
    end
    for slot = 1, MAX_SLOTS do
        clearSlot(state, slot)
    end
    states[player] = nil
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removePlayer)
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
    elapsed += dt
    local alpha = 1 - math.exp(-SMOOTH_SPEED * math.min(dt, 0.1))

    for player, state in pairs(states) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then
            for _, entry in pairs(state.pets) do
                entry.model.Parent = nil
                entry.current = nil
            end
            continue
        end

        local moving = humanoid.MoveDirection.Magnitude > 0.05
        local count = 0
        for slot = 1, MAX_SLOTS do
            if state.pets[slot] then count += 1 end
        end
        local index = 0
        for slot = 1, MAX_SLOTS do
            local entry = state.pets[slot]
            if not entry then continue end
            if entry.model.Parent ~= visualRoot then entry.model.Parent = visualRoot end
            index += 1

            local lateral = (index - (count + 1) / 2) * SPACING
            local groundCenterY = root.Position.Y - humanoid.HipHeight - root.Size.Y * 0.5 + entry.height * 0.5
            local flying = isFlying(entry.id)
            local bob = flying
                and math.sin(elapsed * 3 + slot) * FLY_BOB_HEIGHT
                or (moving and math.abs(math.sin(elapsed * WALK_BOB_SPEED + slot)) * WALK_BOB_HEIGHT or 0)
            local y = groundCenterY + (flying and FLY_HEIGHT or 0) + bob
            local pos = root.Position
                - root.CFrame.LookVector * FOLLOW_DISTANCE
                + root.CFrame.RightVector * lateral
            pos = Vector3.new(pos.X, y, pos.Z)

            local flatForward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
            if flatForward.Magnitude < 0.01 then flatForward = Vector3.new(0, 0, -1) end
            local target = CFrame.lookAt(pos, pos + flatForward.Unit) * CFrame.Angles(0, MODEL_YAW_OFFSET, 0)
            if entry.current == nil or (entry.current.Position - pos).Magnitude > 40 then
                entry.current = target
            else
                entry.current = entry.current:Lerp(target, alpha)
            end
            entry.model:PivotTo(entry.current * entry.centerOffset:Inverse())
            if entry.billboard then
                local adornee = entry.billboard.Parent
                if adornee and adornee:IsA("BasePart") then
                    entry.billboard.StudsOffsetWorldSpace = Vector3.new(0, root.Position.Y + NAMEPLATE_HEIGHT - adornee.Position.Y, 0)
                end
            end
        end
    end
end)

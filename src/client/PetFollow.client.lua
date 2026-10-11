-- PetFollow.client.lua
-- Client-side visuals for every player's equipped pets.
-- Models must exist in ReplicatedStorage/PetModels with names matching PetConfig IDs.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local templates = ReplicatedStorage:WaitForChild("PetModels")
local MAX_SLOTS = PetConfig.MaxEquipped
local SPACING = 3.5
local FOLLOW_DISTANCE = 4.5
local SMOOTH_SPEED = 9
local WALK_BOB_SPEED = 9
local WALK_BOB_HEIGHT = 0.13
local FLY_BOB_HEIGHT = 0.35
local FLY_HEIGHT = 2
-- If faces point backwards, change this to math.pi.
local MODEL_YAW_OFFSET = 0

local visualRoot = workspace:FindFirstChild("ClientPetFollowers")
if not visualRoot then
    visualRoot = Instance.new("Folder")
    visualRoot.Name = "ClientPetFollowers"
    visualRoot.Parent = workspace
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
    model.Parent = visualRoot

    local _, size = model:GetBoundingBox()
    state.pets[slot] = {
        id = id,
        model = model,
        height = size.Y,
        current = nil,
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
            entry.model:PivotTo(entry.current)
        end
    end
end)

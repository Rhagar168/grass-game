local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local vegetationFolder = workspace:WaitForChild("Vegetation")

local petMine = ReplicatedStorage:FindFirstChild("PetMine")
if not petMine then
	petMine = Instance.new("BindableEvent")
	petMine.Name = "PetMine"
	petMine.Parent = ReplicatedStorage
end

local function getPlayerBiome(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local locations = workspace:FindFirstChild("Locations")
	if not root or not locations then return nil end

	local bestId, bestDistance
	for _, biome in ipairs(locations:GetChildren()) do
		local area = biome:FindFirstChild("GrassArea")
		if area and area:IsA("BasePart") then
			local localPos = area.CFrame:PointToObjectSpace(root.Position)
			local inside = math.abs(localPos.X) <= area.Size.X * 0.5
				and math.abs(localPos.Z) <= area.Size.Z * 0.5
				and math.abs(localPos.Y) <= math.max(20, area.Size.Y * 0.5 + 12)
			if inside then return biome.Name end
			local d = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(area.Position.X, area.Position.Z)).Magnitude
			if not bestDistance or d < bestDistance then bestId, bestDistance = biome.Name, d end
		end
	end
	return bestDistance and bestDistance <= 35 and bestId or nil
end

local function nearbyBossAnyBiome(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local active = workspace:FindFirstChild("Bosses")
    active = active and active:FindFirstChild("Active")
    if not root or not active then return nil end
    local best, bestDistance = nil, 28
    for _, model in ipairs(active:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId then
            local hitbox = model:FindFirstChild("BossHitbox")
            if hitbox and hitbox:IsA("BasePart") and (hitbox:GetAttribute("Health") or 0) > 0
                and root.Position.Y >= hitbox.Position.Y - 0.5 then
                local a = Vector2.new(root.Position.X, root.Position.Z)
                local b = Vector2.new(hitbox.Position.X, hitbox.Position.Z)
                local distance = (a - b).Magnitude - math.max(hitbox.Size.X, hitbox.Size.Z) * 0.5
                if distance < bestDistance then best, bestDistance = hitbox, distance end
            end
        end
    end
    return best
end

local function chooseTarget(player, biomeId)
    local boss = nearbyBossAnyBiome(player)
    if boss then return boss end
	local folder = vegetationFolder:FindFirstChild(tostring(player.UserId))
	if not folder then return nil end
	local candidates = {}
	for _, plant in ipairs(folder:GetChildren()) do
		if plant:IsA("BasePart")
			and plant:GetAttribute("OwnerUserId") == player.UserId
			and plant:GetAttribute("LocationId") == biomeId
			and plant:GetAttribute("BossGrass") ~= true
			and plant:GetAttribute("Destroying") ~= true
			and (plant:GetAttribute("Health") or 0) > 0
            then
			table.insert(candidates, plant)
		end
	end
	if #candidates == 0 then return nil end
	return candidates[math.random(1, #candidates)]
end

-- Replicated ObjectValues tell each client's visual pet which grass to visit.
local function targetValue(player, slot)
    local name = "PetTarget" .. slot
    local value = player:FindFirstChild(name)
    if not value then
        value = Instance.new("ObjectValue")
        value.Name = name
        value.Parent = player
    end
    return value
end

-- Client visual confirms arrival; never infer arrival from elapsed time.
local arrivedEvent = ReplicatedStorage:FindFirstChild("PetArrived")
if not arrivedEvent then
    arrivedEvent = Instance.new("RemoteEvent")
    arrivedEvent.Name = "PetArrived"
    arrivedEvent.Parent = ReplicatedStorage
end
local arrived = {}
arrivedEvent.OnServerEvent:Connect(function(player, slot, target)
    if typeof(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > PetConfig.MaxEquipped then return end
    if typeof(target) ~= "Instance" or not target:IsA("BasePart") then return end
    if not PetConfig.GetPet(player:GetAttribute("EquippedPet" .. slot) or "") then return end
    local marker = player:FindFirstChild("PetTarget" .. slot)
    if not marker or marker.Value ~= target or (target:GetAttribute("Health") or 0) <= 0 then return end
    if target:GetAttribute("OwnerUserId") ~= player.UserId then return end
    arrived[player] = arrived[player] or {}
    arrived[player][slot] = target
end)
Players.PlayerRemoving:Connect(function(player) arrived[player] = nil end)

local function runPet(player, slot)
    local marker = targetValue(player, slot)
    local previousPosition = nil
    local lastBiome = nil
    marker:GetPropertyChangedSignal("Value"):Connect(function()
        if arrived[player] then arrived[player][slot] = nil end
    end)
    while player.Parent do
        if player:GetAttribute("DataLoaded") ~= true then
            marker.Value = nil
            task.wait(1)
            continue
        end
        local petId = player:GetAttribute("EquippedPet" .. slot) or ""
        local pet = slot <= PetConfig.EquipLimit(player) and PetConfig.GetPet(petId) or nil
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local bossNear = nearbyBossAnyBiome(player)
        local biomeId = (bossNear and bossNear:GetAttribute("LocationId")) or (root and getPlayerBiome(player))
        if biomeId ~= lastBiome then
            marker.Value = nil
            previousPosition = nil
            lastBiome = biomeId
        end
        local stored = player:GetAttribute("GrassStored") or 0
        local capacity = player:GetAttribute("BackpackCapacity") or 20
        if not pet or not biomeId then
            marker.Value = nil
            task.wait(0.5)
            continue
        end

        local target = marker.Value
        local bossTarget = bossNear
        if bossTarget and bossTarget:GetAttribute("BossGrass") == true then
            target = bossTarget
            marker.Value = target
        end
        if not target or not target.Parent
            or target:GetAttribute("Destroying") == true
            or (target:GetAttribute("Health") or 0) <= 0
            or target:GetAttribute("LocationId") ~= biomeId then
            target = chooseTarget(player, biomeId, slot)
            marker.Value = target
        end
        if target and stored >= capacity and target:GetAttribute("BossGrass") ~= true then
            marker.Value = nil
            task.wait(0.5)
            continue
        end
        if not target then task.wait(0.5) continue end

        -- Damage is locked until the displayed pet reaches its actual destination.
        while player.Parent and marker.Value == target and target.Parent
            and not (arrived[player] and arrived[player][slot] == target) do
            if player:GetAttribute("EquippedPet" .. slot) ~= petId then break end
            local currentBoss = nearbyBossAnyBiome(player)
            local currentBiome = (currentBoss and currentBoss:GetAttribute("LocationId")) or getPlayerBiome(player)
            if currentBiome ~= biomeId or (currentBoss and currentBoss ~= target) then break end
            task.wait(0.08)
        end
        if not player.Parent or marker.Value ~= target or not target.Parent
            or player:GetAttribute("EquippedPet" .. slot) ~= petId
            or ((nearbyBossAnyBiome(player) and nearbyBossAnyBiome(player):GetAttribute("LocationId")) or getPlayerBiome(player)) ~= biomeId
            or (target:GetAttribute("BossGrass") ~= true and nearbyBossAnyBiome(player))
            or (target:GetAttribute("BossGrass") == true and nearbyBossAnyBiome(player) ~= target) then
            marker.Value = nil
            continue
        end

        if not (arrived[player] and arrived[player][slot] == target) then
            marker.Value = nil
            continue
        end
        previousPosition = target.Position
        -- Stay on the same grass until it is mined, then select another.
        while player.Parent and marker.Value == target and target.Parent
            and (target:GetAttribute("Health") or 0) > 0
            and target:GetAttribute("Destroying") ~= true
            and player:GetAttribute("EquippedPet" .. slot) == petId
            and ((nearbyBossAnyBiome(player) and nearbyBossAnyBiome(player):GetAttribute("LocationId")) or getPlayerBiome(player)) == biomeId
            and (target:GetAttribute("BossGrass") == true or not nearbyBossAnyBiome(player))
            and (target:GetAttribute("BossGrass") == true or (player:GetAttribute("GrassStored") or 0) < (player:GetAttribute("BackpackCapacity") or 20)) do
            if target:GetAttribute("BossGrass") == true and nearbyBossAnyBiome(player) ~= target then break end
            if not (arrived[player] and arrived[player][slot] == target) then break end
            local damage = pet.Damage * (1 + 0.15 * (player:GetAttribute("PetDamageLevel") or 0))
            petMine:Fire(player, target, damage, slot, petId)
            task.wait(1 / (1 + 0.08 * (player:GetAttribute("PetAttackSpeedLevel") or 0)))
        end
        -- Keep a continuous target: no return trip to the player between plants.
        if player:GetAttribute("EquippedPet" .. slot) == petId
            and ((nearbyBossAnyBiome(player) and nearbyBossAnyBiome(player):GetAttribute("LocationId")) or getPlayerBiome(player)) == biomeId
            and (target:GetAttribute("BossGrass") == true or (player:GetAttribute("GrassStored") or 0) < (player:GetAttribute("BackpackCapacity") or 20)) then
            marker.Value = chooseTarget(player, biomeId)
        else
            marker.Value = nil
            previousPosition = nil
        end
        task.wait(0.05)
    end
    marker.Value = nil
end

local function setup(player)
	for slot = 1, PetConfig.MaxEquipped do
		task.spawn(runPet, player, slot)
	end
end

Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do setup(player) end

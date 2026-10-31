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

local function nearbyBoss(player, biomeId)
    -- Bosses are shared targets for all equipped pets, including across slots.
    local bosses = workspace:FindFirstChild("Bosses")
    local active = bosses and bosses:FindFirstChild("Active")
    if active then
        for _, model in ipairs(active:GetChildren()) do
            if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId
                and model:GetAttribute("LocationId") == biomeId then
                local hitbox = model:FindFirstChild("BossHitbox")
                if hitbox and hitbox:IsA("BasePart")
                    and (hitbox:GetAttribute("Health") or 0) > 0
                    and hitbox:GetAttribute("Destroying") ~= true then
                    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if root and (Vector3.new(root.Position.X, 0, root.Position.Z)
                        - Vector3.new(hitbox.Position.X, 0, hitbox.Position.Z)).Magnitude <= 55 then
                        return hitbox
                    end
                end
            end
        end
    end
    return nil
end

local function chooseTarget(player, biomeId)
    local boss = nearbyBoss(player, biomeId)
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

local function runPet(player, slot)
    local marker = targetValue(player, slot)
    local previousPosition = nil
    local lastBiome = nil
    while player.Parent do
        if player:GetAttribute("DataLoaded") ~= true then
            marker.Value = nil
            task.wait(1)
            continue
        end
        local petId = player:GetAttribute("EquippedPet" .. slot) or ""
        local pet = PetConfig.GetPet(petId)
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local biomeId = root and getPlayerBiome(player)
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
        local bossTarget = nearbyBoss(player, biomeId)
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

        -- Let the pet physically reach the grass before dealing damage.
        -- Distance is checked against the current player position to avoid
        -- instant damage on far-away targets.
        local start = os.clock()
        local speed = 13
        local origin = previousPosition or root.Position
        while player.Parent and marker.Value == target and target.Parent do
            local currentRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not currentRoot or player:GetAttribute("EquippedPet" .. slot) ~= petId
                or getPlayerBiome(player) ~= biomeId
                or (target:GetAttribute("BossGrass") ~= true and nearbyBoss(player, biomeId))
                or (target:GetAttribute("BossGrass") == true and nearbyBoss(player, biomeId) ~= target) then break end
            local distance = (Vector3.new(target.Position.X, 0, target.Position.Z)
                - Vector3.new(origin.X, 0, origin.Z)).Magnitude
            if os.clock() - start >= math.max(0.4, (distance - 3) / speed) then break end
            task.wait(0.1)
        end
        if not player.Parent or marker.Value ~= target or not target.Parent
            or player:GetAttribute("EquippedPet" .. slot) ~= petId
            or getPlayerBiome(player) ~= biomeId
            or (target:GetAttribute("BossGrass") ~= true and nearbyBoss(player, biomeId))
            or (target:GetAttribute("BossGrass") == true and nearbyBoss(player, biomeId) ~= target) then
            marker.Value = nil
            continue
        end

        previousPosition = target.Position
        -- Stay on the same grass until it is mined, then select another.
        while player.Parent and marker.Value == target and target.Parent
            and (target:GetAttribute("Health") or 0) > 0
            and target:GetAttribute("Destroying") ~= true
            and player:GetAttribute("EquippedPet" .. slot) == petId
            and getPlayerBiome(player) == biomeId
            and (target:GetAttribute("BossGrass") == true or not nearbyBoss(player, biomeId))
            and (target:GetAttribute("BossGrass") == true or (player:GetAttribute("GrassStored") or 0) < (player:GetAttribute("BackpackCapacity") or 20)) do
            if target:GetAttribute("BossGrass") == true and nearbyBoss(player, biomeId) ~= target then break end
            petMine:Fire(player, target, pet.Damage, slot, petId)
            task.wait(1)
        end
        -- Keep a continuous target: no return trip to the player between plants.
        if player:GetAttribute("EquippedPet" .. slot) == petId
            and getPlayerBiome(player) == biomeId
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

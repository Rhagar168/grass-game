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

local function chooseTarget(player, biomeId)
	local folder = vegetationFolder:FindFirstChild(tostring(player.UserId))
	if not folder then return nil end
	local candidates = {}
	for _, plant in ipairs(folder:GetChildren()) do
		if plant:IsA("BasePart")
			and plant:GetAttribute("OwnerUserId") == player.UserId
			and plant:GetAttribute("LocationId") == biomeId
			and plant:GetAttribute("BossGrass") ~= true
			and plant:GetAttribute("Destroying") ~= true
			and (plant:GetAttribute("Health") or 0) > 0 then
			table.insert(candidates, plant)
		end
	end
	if #candidates == 0 then return nil end
	return candidates[math.random(1, #candidates)]
end

local function runPet(player, slot)
	while player.Parent do
		if player:GetAttribute("DataLoaded") ~= true then task.wait(1) continue end
		local petId = player:GetAttribute("EquippedPet" .. slot) or ""
		local pet = PetConfig.GetPet(petId)
		if not pet then task.wait(0.5) continue end

		local stored = player:GetAttribute("GrassStored") or 0
		local capacity = player:GetAttribute("BackpackCapacity") or 20
		if stored >= capacity then task.wait(0.75) continue end

		local biomeId = getPlayerBiome(player)
		local target = biomeId and chooseTarget(player, biomeId)
		if not target then task.wait(0.5) continue end

		petMine:Fire(player, target, pet.Damage, slot, petId)
		task.wait(1)
	end
end

local function setup(player)
	for slot = 1, PetConfig.MaxEquipped do
		task.spawn(runPet, player, slot)
	end
end

Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do setup(player) end

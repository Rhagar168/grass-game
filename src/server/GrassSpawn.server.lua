local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local GrassConfig = require(ReplicatedStorage:WaitForChild("GrassConfig"))

local smallGrass = ServerStorage:WaitForChild("MalaTravaTemplate")
local bigGrass = ServerStorage:WaitForChild("VelkaTravaTemplate")

local locations = workspace:WaitForChild("Locations")
local vegetationFolder = workspace:WaitForChild("Vegetation")
local progressEvent = ReplicatedStorage:WaitForChild("LocationProgressUpdate")

local respawnAllEvent = ReplicatedStorage:FindFirstChild("RespawnAllGrass")
if not respawnAllEvent then
	respawnAllEvent = Instance.new("BindableEvent")
	respawnAllEvent.Name = "RespawnAllGrass"
	respawnAllEvent.Parent = ReplicatedStorage
end

local resetEvent = ReplicatedStorage:FindFirstChild("ResetBiome")
if not resetEvent then
	resetEvent = Instance.new("RemoteEvent")
	resetEvent.Name = "ResetBiome"
	resetEvent.Parent = ReplicatedStorage
end

local BIOMES = {
	Plains = {
		grassCount = 500,
		spacing = 2.2,
		colorMin = Color3.fromRGB(70, 150, 52),
		colorMax = Color3.fromRGB(120, 195, 82),
		healthMultiplier = 1,
	},
	Forest = {
		grassCount = 1000,
		spacing = 1.45,
		colorMin = Color3.fromRGB(28, 78, 32),
		colorMax = Color3.fromRGB(48, 105, 42),
		healthMultiplier = 3,
	},
	Savanna = {
		grassCount = 1000,
		spacing = 1.45,
		colorMin = Color3.fromRGB(150, 132, 54),
		colorMax = Color3.fromRGB(170, 150, 66),
		healthMultiplier = 6,
	},
	Jungle = {
		grassCount = 1000,
		spacing = 1.45,
		colorMin = Color3.fromRGB(38, 105, 42),
		colorMax = Color3.fromRGB(75, 145, 58),
		healthMultiplier = 10,
	},
}

local MAX_GROW_DELAY = 1.5
local GROW_TIME = 0.65

local grassTypes = {
	{
		name = "Small",
		template = smallGrass,
		chance = 70,
		minScale = 0.8,
		maxScale = 1.15,
		health = 3,
		grassPerCut = 1,
	},
	{
		name = "Big",
		template = bigGrass,
		chance = 30,
		minScale = 0.9,
		maxScale = 1.25,
		health = 15,
		grassPerCut = 1,
	},
}

local function waitForData(player)
	if player:GetAttribute("DataLoaded") == true then
		return true
	end

	local deadline = os.clock() + 20
	while player.Parent and player:GetAttribute("DataLoaded") ~= true and os.clock() < deadline do
		task.wait(0.1)
	end

	return player.Parent ~= nil and player:GetAttribute("DataLoaded") == true
end

local function getPlayerVegetationFolder(player)
	local folderName = tostring(player.UserId)
	local folder = vegetationFolder:FindFirstChild(folderName)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder:SetAttribute("OwnerUserId", player.UserId)
		folder.Parent = vegetationFolder
	end

	return folder
end

local function chooseGrassType()
	local totalChance = 0
	for _, grassType in ipairs(grassTypes) do
		totalChance += grassType.chance
	end

	local roll = math.random() * totalChance
	local current = 0

	for _, grassType in ipairs(grassTypes) do
		current += grassType.chance
		if roll <= current then
			return grassType
		end
	end

	return grassTypes[1]
end

local function randomPositionInArea(area, margin)
	local halfX = math.max(0, area.Size.X / 2 - margin)
	local halfZ = math.max(0, area.Size.Z / 2 - margin)

	local localX = (math.random() * 2 - 1) * halfX
	local localZ = (math.random() * 2 - 1) * halfZ
	local worldPosition = area.CFrame:PointToWorldSpace(Vector3.new(localX, 0, localZ))

	return Vector2.new(worldPosition.X, worldPosition.Z)
end

local function randomBiomeColor(config)
	return Color3.fromRGB(
		math.random(config.colorMin.R * 255, config.colorMax.R * 255),
		math.random(config.colorMin.G * 255, config.colorMax.G * 255),
		math.random(config.colorMin.B * 255, config.colorMax.B * 255)
	)
end

local function spawnPlant(player, biomeId, config, position2D, area, grassType, animateSpawn)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {area, vegetationFolder}
	rayParams.IgnoreWater = true

	local rayStartY = area.Position.Y + area.Size.Y / 2 + 5
	local result = workspace:Raycast(
		Vector3.new(position2D.X, rayStartY, position2D.Y),
		Vector3.new(0, -200, 0),
		rayParams
	)

	if not result or CollectionService:HasTag(result.Instance, "NoGrass") then
		return false
	end

	local grass = grassType.template:Clone()
	grass:SetAttribute("OwnerUserId", player.UserId)

	local scale = grassType.minScale + math.random() * (grassType.maxScale - grassType.minScale)
	local finalSize = grass.Size * scale
	local finalPosition = Vector3.new(result.Position.X, result.Position.Y + finalSize.Y / 2, result.Position.Z)

	grass.Orientation = Vector3.new(0, math.random(0, 359), 0)
	local biomeColor = randomBiomeColor(config)
	grass:SetAttribute("BaseGrassColor", biomeColor)
	grass.Color = biomeColor
	grass.Anchored = true
	grass.CanCollide = false
	grass.CanTouch = false
	grass.CanQuery = false
	grass.Massless = true

	CollectionService:AddTag(grass, "Cuttable")
	local resetCount = player:GetAttribute(biomeId .. "ResetCount") or 0
	-- Infinite reset scaling: every reset multiplies HP by another 5x.
	-- Reset 0 = 1x, reset 1 = 5x, reset 2 = 25x, reset 3 = 125x, ...
	local biomeHealth = GrassConfig.GetHealth(biomeId, grassType.name, "Normal", resetCount)
		or (grassType.health * (config.healthMultiplier or 1) * (5 ^ resetCount))
	grass:SetAttribute("Health", biomeHealth)
	grass:SetAttribute("MaxHealth", biomeHealth)
	grass:SetAttribute("GrassPerCut", grassType.grassPerCut)
	grass:SetAttribute("LocationId", biomeId)
	grass:SetAttribute("OriginalSize", finalSize)
	grass:SetAttribute("GrassType", grassType.name)

	if grass:GetAttribute("XPReward") == nil then
		grass:SetAttribute("XPReward", grassType.name == "Big" and 3 or 1)
	end

	if animateSpawn then
		local startSize = Vector3.new(finalSize.X * 0.15, finalSize.Y * 0.05, finalSize.Z * 0.15)
		grass.Size = startSize
		grass.Position = Vector3.new(finalPosition.X, result.Position.Y - startSize.Y, finalPosition.Z)
		grass.Parent = getPlayerVegetationFolder(player)

		task.delay(math.random() * MAX_GROW_DELAY, function()
			if grass.Parent then
				TweenService:Create(
					grass,
					TweenInfo.new(GROW_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{Size = finalSize, Position = finalPosition}
				):Play()
			end
		end)
	else
		grass.Size = finalSize
		grass.Position = finalPosition
		grass.Parent = getPlayerVegetationFolder(player)
	end

	return true
end

local function clearPlayerBiome(player, biomeId)
	local folder = vegetationFolder:FindFirstChild(tostring(player.UserId))
	if not folder then return end

	for _, grass in ipairs(folder:GetChildren()) do
		if grass:GetAttribute("LocationId") == biomeId then
			grass:Destroy()
		end
	end
end

local function spawnBiomeForPlayer(player, biomeId, animateSpawn)
	local config = BIOMES[biomeId]
	local biome = locations:FindFirstChild(biomeId)
	if not config or not biome then
		return
	end

	local area = biome:FindFirstChild("GrassArea")
	if not area or not area:IsA("BasePart") then
		warn(biomeId .. " is missing GrassArea")
		return
	end

	local remainingAttribute = biomeId .. "GrassRemaining"
	local resettingAttribute = biomeId .. "Resetting"

	player:SetAttribute(resettingAttribute, true)
	clearPlayerBiome(player, biomeId)

	local targetCount = math.clamp(
		math.floor((player:GetAttribute(remainingAttribute) or config.grassCount) + 0.5),
		0,
		config.grassCount
	)

	local spawned = 0
	local attempts = 0
	local maxAttempts = math.max(targetCount * 12, 1000)
	local margin = config.spacing * 0.35

	while spawned < targetCount and attempts < maxAttempts do
		attempts += 1

		local position2D = randomPositionInArea(area, margin)
		if spawnPlant(player, biomeId, config, position2D, area, chooseGrassType(), animateSpawn) then
			spawned += 1
		end
	end

	if spawned < targetCount then
		warn(
			biomeId,
			"could only spawn",
			spawned,
			"of",
			targetCount,
			"grass after",
			attempts,
			"attempts"
		)
	end

	-- IMPORTANT: remaining grass is player progress loaded from DataStore.
	-- Spawning is only a visual reconstruction and must never overwrite saved progress.
	-- If a few random positions fail, keep the saved count instead of changing progress.
	player:SetAttribute(resettingAttribute, false)

	print(
		biomeId:upper(),
		"SPAWNED FOR:",
		player.Name,
		"| SAVED REMAINING:",
		targetCount,
		"| ACTUALLY SPAWNED:",
		spawned
	)
	progressEvent:Fire(biomeId, player)
end

local function resetBiomeForPlayer(player, biomeId)
	local config = BIOMES[biomeId]
	if not config then return end

	local remainingAttribute = biomeId .. "GrassRemaining"
	if (player:GetAttribute(remainingAttribute) or config.grassCount) > 0 then
		return
	end

	local resetCountAttribute = biomeId .. "ResetCount"
	local resetCount = player:GetAttribute(resetCountAttribute) or 0
	player:SetAttribute(resetCountAttribute, resetCount + 1)

	local totalResets = player:GetAttribute("TotalResets") or 0
	player:SetAttribute("TotalResets", totalResets + 1)

	player:SetAttribute(remainingAttribute, config.grassCount)
	spawnBiomeForPlayer(player, biomeId, true)

	local RESET_TOKEN_REWARDS = {
		Plains = 1,
		Forest = 2,
		Savanna = 3,
		Jungle = 4,
	}

	local tokens = player:GetAttribute("ResetTokens") or 0
	local reward = RESET_TOKEN_REWARDS[biomeId] or 1
	player:SetAttribute("ResetTokens", tokens + reward)
end

resetEvent.OnServerEvent:Connect(function(player, biomeId)
	resetBiomeForPlayer(player, biomeId or "Plains")
end)

respawnAllEvent.Event:Connect(function(player)
	if not player or not player.Parent then
		return
	end

	for biomeId in pairs(BIOMES) do
		spawnBiomeForPlayer(player, biomeId, false)
	end
end)

local function setupPlayer(player)
	if not waitForData(player) or not player.Parent then
		return
	end

	for biomeId in pairs(BIOMES) do
		spawnBiomeForPlayer(player, biomeId, false)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	for biomeId in pairs(BIOMES) do
		player:SetAttribute(biomeId .. "Resetting", true)
	end

	local folder = vegetationFolder:FindFirstChild(tostring(player.UserId))
	if folder then
		folder:Destroy()
	end
end)

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local smallGrass = ServerStorage:WaitForChild("MalaTravaTemplate")
local bigGrass = ServerStorage:WaitForChild("VelkaTravaTemplate")

local locations = workspace:WaitForChild("Locations")
local busStop = locations:WaitForChild("BusStop")
local busStopArea = busStop:WaitForChild("GrassArea")
local vegetationFolder = workspace:WaitForChild("Vegetation")

local resetEvent = ReplicatedStorage:WaitForChild("ResetBusStop")
local progressEvent = ReplicatedStorage:WaitForChild("LocationProgressUpdate")

local LOCATION_ID = "BusStop"
local GRASS_COUNT = 500
local GRASS_SPACING = 2.2
local SMALL_GRASS_CHANCE = 70
local BIG_GRASS_CHANCE = 30
local MAX_GROW_DELAY = 1.5
local GROW_TIME = 0.65

local grassTypes = {
	{
		name = "Small",
		template = smallGrass,
		chance = SMALL_GRASS_CHANCE,
		minScale = 0.8,
		maxScale = 1.15,
		health = 3,
		grassPerCut = 1,
	},
	{
		name = "Big",
		template = bigGrass,
		chance = BIG_GRASS_CHANCE,
		minScale = 0.9,
		maxScale = 1.25,
		health = 15,
		grassPerCut = 1,
	},
}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {busStopArea, vegetationFolder}
rayParams.IgnoreWater = true

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

	local randomNumber = math.random() * totalChance
	local currentChance = 0

	for _, grassType in ipairs(grassTypes) do
		currentChance += grassType.chance
		if randomNumber <= currentChance then
			return grassType
		end
	end

	return grassTypes[1]
end

local function createPositions(area, spacing)
	local positions = {}
	local margin = spacing * 0.6
	local startX = -area.Size.X / 2 + margin
	local endX = area.Size.X / 2 - margin
	local startZ = -area.Size.Z / 2 + margin
	local endZ = area.Size.Z / 2 - margin

	for x = startX, endX, spacing do
		for z = startZ, endZ, spacing do
			local jitterX = (math.random() - 0.5) * spacing * 0.35
			local jitterZ = (math.random() - 0.5) * spacing * 0.35
			local localPosition = Vector3.new(x + jitterX, 0, z + jitterZ)
			local worldPosition = area.CFrame:PointToWorldSpace(localPosition)
			table.insert(positions, Vector2.new(worldPosition.X, worldPosition.Z))
		end
	end

	for i = #positions, 2, -1 do
		local j = math.random(i)
		positions[i], positions[j] = positions[j], positions[i]
	end

	return positions
end

local function spawnPlant(player, position2D, area, grassType, animateSpawn)
	local playerVegetationFolder = getPlayerVegetationFolder(player)
	local rayStartY = area.Position.Y + area.Size.Y / 2 + 5
	local rayOrigin = Vector3.new(position2D.X, rayStartY, position2D.Y)
	local result = workspace:Raycast(rayOrigin, Vector3.new(0, -200, 0), rayParams)

	if not result then
		return false
	end

	if CollectionService:HasTag(result.Instance, "NoGrass") then
		return false
	end

	local grass = grassType.template:Clone()
	grass:SetAttribute("OwnerUserId", player.UserId)

	local scale = grassType.minScale + math.random() * (grassType.maxScale - grassType.minScale)
	local finalSize = grass.Size * scale
	local finalPosition = Vector3.new(
		result.Position.X,
		result.Position.Y + finalSize.Y / 2,
		result.Position.Z
	)

	grass.Orientation = Vector3.new(0, math.random(0, 359), 0)
	grass.Color = Color3.fromRGB(
		math.random(45, 70),
		math.random(105, 145),
		math.random(35, 65)
	)

	grass.Anchored = true
	grass.CanCollide = false
	grass.CanTouch = false
	grass.CanQuery = false
	grass.Massless = true

	CollectionService:AddTag(grass, "Cuttable")
	grass:SetAttribute("Health", grassType.health)
	grass:SetAttribute("MaxHealth", grassType.health)
	grass:SetAttribute("GrassPerCut", grassType.grassPerCut)
	grass:SetAttribute("LocationId", LOCATION_ID)
	grass:SetAttribute("OriginalSize", finalSize)
	grass:SetAttribute("GrassType", grassType.name)

	if grass:GetAttribute("XPReward") == nil then
		grass:SetAttribute("XPReward", grassType.name == "Big" and 3 or 1)
	end

	if animateSpawn then
		local startSize = Vector3.new(finalSize.X * 0.15, finalSize.Y * 0.05, finalSize.Z * 0.15)
		local startPosition = Vector3.new(
			finalPosition.X,
			result.Position.Y - startSize.Y,
			finalPosition.Z
		)

		grass.Size = startSize
		grass.Position = startPosition
		grass.Parent = playerVegetationFolder

		task.delay(math.random() * MAX_GROW_DELAY, function()
			if not grass.Parent then
				return
			end

			TweenService:Create(
				grass,
				TweenInfo.new(GROW_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Size = finalSize, Position = finalPosition}
			):Play()
		end)
	else
		grass.Size = finalSize
		grass.Position = finalPosition
		grass.Parent = playerVegetationFolder
	end

	return true
end

local function spawnBusStopForPlayer(player, animateSpawn)
	if not player or not player.Parent then
		return
	end

	local playerFolder = getPlayerVegetationFolder(player)
	player:SetAttribute("BusStopResetting", true)
	playerFolder:ClearAllChildren()

	local targetCount = math.clamp(
		math.floor((player:GetAttribute("BusStopGrassRemaining") or GRASS_COUNT) + 0.5),
		0,
		GRASS_COUNT
	)

	local positions = createPositions(busStopArea, GRASS_SPACING)
	local spawned = 0
	local smallCount = 0
	local bigCount = 0

	for _, position2D in ipairs(positions) do
		if spawned >= targetCount then
			break
		end

		local grassType = chooseGrassType()
		if spawnPlant(player, position2D, busStopArea, grassType, animateSpawn) then
			spawned += 1
			if grassType.name == "Small" then
				smallCount += 1
			else
				bigCount += 1
			end
		end
	end

	-- If a few positions were blocked, store what actually exists so progress stays consistent.
	player:SetAttribute("BusStopGrassRemaining", spawned)
	player:SetAttribute("BusStopResetting", false)

	print(
		"BUS STOP SPAWNED FOR:", player.Name,
		"| REMAINING:", spawned,
		"| SMALL:", smallCount,
		"| BIG:", bigCount
	)

	progressEvent:Fire(LOCATION_ID, player)
	return spawned
end

local function clearPlayerLocation(player, locationId)
	local playerFolder = vegetationFolder:FindFirstChild(tostring(player.UserId))
	if not playerFolder then
		return
	end

	for _, grass in ipairs(playerFolder:GetChildren()) do
		if grass:GetAttribute("LocationId") == locationId then
			grass:Destroy()
		end
	end
end

local function resetBusStopForPlayer(player)
	print("RESETTING BUS STOP FOR:", player.Name)
	player:SetAttribute("BusStopResetting", true)
	player:SetAttribute("BusStopGrassRemaining", GRASS_COUNT)
	clearPlayerLocation(player, LOCATION_ID)
	task.wait(0.25)
	spawnBusStopForPlayer(player, true)
	print("BUS STOP RESET COMPLETE FOR:", player.Name)
end

resetEvent.OnServerEvent:Connect(function(player)
	local remaining = player:GetAttribute("BusStopGrassRemaining") or GRASS_COUNT
	if remaining > 0 then
		warn(player.Name, "tried to reset BusStop before completion")
		return
	end

	resetBusStopForPlayer(player)

	local currentTokens = player:GetAttribute("ResetTokens") or 0
	player:SetAttribute("ResetTokens", currentTokens + 1)
	print(player.Name, "received +1 Reset Token | Total:", currentTokens + 1)
end)

local function setupPlayer(player)
	if not waitForData(player) then
		return
	end

	if not player.Parent then
		return
	end

	spawnBusStopForPlayer(player, false)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	player:SetAttribute("BusStopResetting", true)
	local playerFolder = vegetationFolder:FindFirstChild(tostring(player.UserId))
	if playerFolder then
		playerFolder:Destroy()
	end
end)

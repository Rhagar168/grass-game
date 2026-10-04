local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local bossRewardAnimation = ReplicatedStorage:FindFirstChild("BossRewardAnimation")
if not bossRewardAnimation then
	bossRewardAnimation = Instance.new("RemoteEvent")
	bossRewardAnimation.Name = "BossRewardAnimation"
	bossRewardAnimation.Parent = ReplicatedStorage
end

local BOSS_CONFIGS = {
	AncientGrass = {
		DisplayName = "ANCIENT GRASS",
		MaxHealth = 50000,
		LocationId = "Forest",
		UnlockAttribute = "ForestUnlocked",
		RespawnSeconds = 2 * 60 * 60,
		GrassCoreReward = 1,
		ResetTokenMin = 1,
		ResetTokenMax = 5,
		HealthColor = Color3.fromRGB(48, 180, 82),
	},
	OvergrownGrass = {
		DisplayName = "OVERGROWN GRASS",
		MaxHealth = 500000,
		LocationId = "Jungle",
		UnlockAttribute = "JungleUnlocked",
		RespawnSeconds = 4 * 60 * 60,
		GrassCoreReward = 2,
		ResetTokenMin = 3,
		ResetTokenMax = 8,
		HealthColor = Color3.fromRGB(42, 145, 58),
	},
	MoltenGrass = {
		DisplayName = "MOLTEN GRASS",
		MaxHealth = 5000000,
		LocationId = "Volcano",
		UnlockAttribute = "VolcanoUnlocked",
		RespawnSeconds = 8 * 60 * 60,
		GrassCoreReward = 3,
		ResetTokenMin = 5,
		ResetTokenMax = 12,
		HealthColor = Color3.fromRGB(235, 82, 28),
	},
}

local bossesFolder = workspace:WaitForChild("Bosses")
local activeFolder = bossesFolder:FindFirstChild("Active")
if not activeFolder then
	activeFolder = Instance.new("Folder")
	activeFolder.Name = "Active"
	activeFolder.Parent = bossesFolder
end

local templates = {}
for bossId, config in pairs(BOSS_CONFIGS) do
	local folder = bossesFolder:WaitForChild(bossId)
	local sourceBoss = folder:WaitForChild("Boss")
	local template = sourceBoss:Clone()
	template.Name = bossId .. "Template"
	template.Parent = ServerStorage
	templates[bossId] = template
	sourceBoss:Destroy()
end

local activeByPlayer = {}
local respawnTokens = {}
local cooldownMarkers = {}

local function stateKey(player, bossId)
	return tostring(player.UserId) .. "_" .. bossId
end

local function healthAttribute(bossId)
	return bossId .. "Health"
end

local function respawnAttribute(bossId)
	return bossId .. "RespawnAt"
end

local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function removeCooldownMarker(player, bossId)
	local key = stateKey(player, bossId)
	local marker = cooldownMarkers[key]
	cooldownMarkers[key] = nil
	if marker and marker.Parent then marker:Destroy() end
end

local function removeBoss(player, bossId)
	local key = stateKey(player, bossId)
	local model = activeByPlayer[key]
	activeByPlayer[key] = nil
	if model and model.Parent then model:Destroy() end
end

local function templateCenter(template)
	local parts = {}
	for _, obj in ipairs(template:GetDescendants()) do
		if obj:IsA("BasePart") then table.insert(parts, obj) end
	end
	if template:IsA("BasePart") then table.insert(parts, template) end
	if #parts == 0 then return nil end
	local minV, maxV
	for _, part in ipairs(parts) do
		local p = part.Position
		minV = minV and Vector3.new(math.min(minV.X,p.X),math.min(minV.Y,p.Y),math.min(minV.Z,p.Z)) or p
		maxV = maxV and Vector3.new(math.max(maxV.X,p.X),math.max(maxV.Y,p.Y),math.max(maxV.Z,p.Z)) or p
	end
	return (minV + maxV) / 2
end

local function showCooldownMarker(player, bossId, position)
	local config = BOSS_CONFIGS[bossId]
	removeCooldownMarker(player, bossId)
	local key = stateKey(player, bossId)

	local marker = Instance.new("Model")
	marker.Name = bossId .. "Cooldown_" .. player.UserId
	marker:SetAttribute("OwnerUserId", player.UserId)
	marker.Parent = activeFolder

	local anchor = Instance.new("Part")
	anchor.Name = "CooldownAnchor"
	anchor.Size = Vector3.new(1,1,1)
	anchor.CFrame = CFrame.new(position)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Parent = marker

	local gui = Instance.new("BillboardGui")
	gui.Name = "CooldownBillboard"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(280,72)
	gui.StudsOffsetWorldSpace = Vector3.new(0,4,0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 45
	gui.Parent = marker

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,0,0,30)
	title.Font = Enum.Font.GothamBlack
	title.Text = config.DisplayName .. " RESPAWNS IN"
	title.TextColor3 = Color3.fromRGB(235,245,235)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.3
	title.Parent = gui

	local timer = Instance.new("TextLabel")
	timer.BackgroundTransparency = 1
	timer.Position = UDim2.fromOffset(0,32)
	timer.Size = UDim2.new(1,0,0,34)
	timer.Font = Enum.Font.GothamBlack
	timer.TextColor3 = config.HealthColor
	timer.TextScaled = true
	timer.TextStrokeTransparency = 0.25
	timer.Parent = gui

	cooldownMarkers[key] = marker
	task.spawn(function()
		while marker.Parent and player.Parent do
			local left = (player:GetAttribute(respawnAttribute(bossId)) or 0) - os.time()
			if left <= 0 then break end
			timer.Text = formatTime(left)
			task.wait(1)
		end
	end)
end

local spawnBoss

local function scheduleRespawn(player, bossId)
	local key = stateKey(player, bossId)
	respawnTokens[key] = (respawnTokens[key] or 0) + 1
	local token = respawnTokens[key]
	local respawnAt = player:GetAttribute(respawnAttribute(bossId)) or 0
	local delaySeconds = math.max(0, respawnAt - os.time())
	if delaySeconds <= 0 then return end

	task.delay(delaySeconds, function()
		if not player.Parent or respawnTokens[key] ~= token then return end
		local config = BOSS_CONFIGS[bossId]
		if player:GetAttribute("DataLoaded") ~= true or player:GetAttribute(config.UnlockAttribute) ~= true then return end
		if (player:GetAttribute(respawnAttribute(bossId)) or 0) > os.time() then
			scheduleRespawn(player, bossId)
			return
		end
		player:SetAttribute(respawnAttribute(bossId), 0)
		removeCooldownMarker(player, bossId)
		spawnBoss(player, bossId)
	end)
end

local function addHealthBar(model, hitbox, bossId)
	local config = BOSS_CONFIGS[bossId]
	local anchor = Instance.new("Part")
	anchor.Name = "BossHealthAnchor"
	anchor.Size = Vector3.new(1,1,1)
	anchor.CFrame = hitbox.CFrame
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor:SetAttribute("OwnerUserId", model:GetAttribute("OwnerUserId"))
	anchor.Parent = activeFolder

	local gui = Instance.new("BillboardGui")
	gui.Name = "BossHealthBar"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(260,64)
	gui.StudsOffsetWorldSpace = Vector3.new(0,7,0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,0,0,25)
	title.Font = Enum.Font.GothamBlack
	title.Text = config.DisplayName
	title.TextColor3 = Color3.fromRGB(235,245,235)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.35
	title.Parent = gui

	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(0,31)
	back.Size = UDim2.new(1,0,0,20)
	back.BackgroundColor3 = Color3.fromRGB(20,27,23)
	back.BorderSizePixel = 0
	back.Parent = gui
	Instance.new("UICorner", back).CornerRadius = UDim.new(0,6)
	local stroke = Instance.new("UIStroke", back)
	stroke.Color = Color3.fromRGB(58,74,79)
	stroke.Thickness = 2

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1,1)
	fill.BackgroundColor3 = config.HealthColor
	fill.BorderSizePixel = 0
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0,6)

	local hp = Instance.new("TextLabel")
	hp.BackgroundTransparency = 1
	hp.Size = UDim2.fromScale(1,1)
	hp.Font = Enum.Font.GothamBlack
	hp.TextColor3 = Color3.new(1,1,1)
	hp.TextScaled = true
	hp.TextStrokeTransparency = 0.25
	hp.ZIndex = 2
	hp.Parent = back

	local function update()
		local health = math.max(0, hitbox:GetAttribute("Health") or 0)
		fill.Size = UDim2.fromScale(math.clamp(health / config.MaxHealth,0,1),1)
		hp.Text = string.format("%s / %s HP", math.floor(health+0.5), config.MaxHealth)
	end
	hitbox:GetAttributeChangedSignal("Health"):Connect(update)
	model.Destroying:Connect(function() if anchor.Parent then anchor:Destroy() end end)
	update()
end

spawnBoss = function(player, bossId)
	local config = BOSS_CONFIGS[bossId]
	local key = stateKey(player, bossId)
	if not config or (activeByPlayer[key] and activeByPlayer[key].Parent) then return end
	if player:GetAttribute("DataLoaded") ~= true or player:GetAttribute(config.UnlockAttribute) ~= true then return end

	local respawnAt = player:GetAttribute(respawnAttribute(bossId)) or 0
	if respawnAt > os.time() then
		if not cooldownMarkers[key] then
			local center = templateCenter(templates[bossId])
			if center then showCooldownMarker(player, bossId, center) end
		end
		scheduleRespawn(player, bossId)
		return
	elseif respawnAt ~= 0 then
		player:SetAttribute(respawnAttribute(bossId), 0)
	end

	local cloned = templates[bossId]:Clone()
	local model
	if cloned:IsA("Model") then
		model = cloned
	else
		model = Instance.new("Model")
		for _, child in ipairs(cloned:GetChildren()) do child.Parent = model end
		cloned:Destroy()
	end

	model.Name = bossId .. "_" .. player.UserId
	model:SetAttribute("BossGrass", true)
	model:SetAttribute("BossId", bossId)
	model:SetAttribute("LocationId", config.LocationId)
	model:SetAttribute("OwnerUserId", player.UserId)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
		end
	end
	model.Parent = activeFolder

	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottomY = boxCFrame.Position.Y - boxSize.Y/2
	local hitbox = Instance.new("Part")
	hitbox.Name = "BossHitbox"
	hitbox.Size = Vector3.new(math.max(4,boxSize.X),math.max(4,boxSize.Y),math.max(4,boxSize.Z))
	hitbox.CFrame = CFrame.new(boxCFrame.Position.X, bottomY + math.min(2.5,hitbox.Size.Y/2), boxCFrame.Position.Z)
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = false
	hitbox:SetAttribute("BossGrass", true)
	hitbox:SetAttribute("BossId", bossId)
	hitbox:SetAttribute("LocationId", config.LocationId)
	hitbox:SetAttribute("OwnerUserId", player.UserId)

	local savedHealth = player:GetAttribute(healthAttribute(bossId))
	if typeof(savedHealth) ~= "number" or savedHealth <= 0 or savedHealth > config.MaxHealth then
		savedHealth = config.MaxHealth
	end
	hitbox:SetAttribute("Health", savedHealth)
	hitbox:SetAttribute("MaxHealth", config.MaxHealth)
	hitbox:SetAttribute("XPReward", 0)
	hitbox:SetAttribute("RewardMultiplier", 1)
	hitbox.Parent = model
	CollectionService:AddTag(hitbox, "Cuttable")
	addHealthBar(model, hitbox, bossId)
	activeByPlayer[key] = model

	local dead = false
	local previousHealth = savedHealth
	hitbox:GetAttributeChangedSignal("Health"):Connect(function()
		if dead then return end
		local health = hitbox:GetAttribute("Health") or 0
		player:SetAttribute(healthAttribute(bossId), math.clamp(health,0,config.MaxHealth))
		if health < previousHealth then
			model:SetAttribute("HitAnimationId", (model:GetAttribute("HitAnimationId") or 0) + 1)
		end
		previousHealth = health
		if health > 0 then return end

		dead = true
		player:SetAttribute(healthAttribute(bossId), config.MaxHealth)
		local cores = player:GetAttribute("GrassCores") or 0
		player:SetAttribute("GrassCores", cores + config.GrassCoreReward)
		local rtReward = math.random(config.ResetTokenMin, config.ResetTokenMax)
		local tokens = player:GetAttribute("ResetTokens") or 0
		player:SetAttribute("ResetTokens", tokens + rtReward)
		bossRewardAnimation:FireClient(player, config.GrassCoreReward, rtReward)

		local defeatAnimationDuration = 2.2
		local markerPosition = model:GetBoundingBox().Position
		local newRespawnAt = os.time() + math.ceil(defeatAnimationDuration) + config.RespawnSeconds
		player:SetAttribute(respawnAttribute(bossId), newRespawnAt)
		print(config.DisplayName .. " DEFEATED:", player.Name, "| +" .. config.GrassCoreReward .. " GC | +" .. rtReward .. " RT")

		task.delay(defeatAnimationDuration, function()
			if not player.Parent then return end
			showCooldownMarker(player, bossId, markerPosition)
			scheduleRespawn(player, bossId)
		end)
		task.delay(defeatAnimationDuration, function()
			if activeByPlayer[key] == model then activeByPlayer[key] = nil end
			if model.Parent then model:Destroy() end
		end)
	end)
end

local function refreshBoss(player, bossId)
	local config = BOSS_CONFIGS[bossId]
	if player:GetAttribute("DataLoaded") == true and player:GetAttribute(config.UnlockAttribute) == true then
		spawnBoss(player, bossId)
	else
		removeCooldownMarker(player, bossId)
		removeBoss(player, bossId)
	end
end

local function setupPlayer(player)
	for bossId, config in pairs(BOSS_CONFIGS) do
		player:GetAttributeChangedSignal(config.UnlockAttribute):Connect(function()
			refreshBoss(player, bossId)
		end)
	end
	player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
		for bossId in pairs(BOSS_CONFIGS) do refreshBoss(player, bossId) end
	end)
	for bossId in pairs(BOSS_CONFIGS) do refreshBoss(player, bossId) end
end

local respawnBossesCommand = ReplicatedStorage:FindFirstChild("RespawnBosses")
if not respawnBossesCommand then
	respawnBossesCommand = Instance.new("BindableEvent")
	respawnBossesCommand.Name = "RespawnBosses"
	respawnBossesCommand.Parent = ReplicatedStorage
end

respawnBossesCommand.Event:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		for bossId, config in pairs(BOSS_CONFIGS) do
			local key = stateKey(player, bossId)
			respawnTokens[key] = (respawnTokens[key] or 0) + 1
			player:SetAttribute(respawnAttribute(bossId), 0)
			player:SetAttribute(healthAttribute(bossId), config.MaxHealth)
			removeCooldownMarker(player, bossId)
			removeBoss(player, bossId)
			spawnBoss(player, bossId)
		end
	end
	print("BOSSES RESPAWNED")
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setupPlayer, player) end

Players.PlayerRemoving:Connect(function(player)
	for bossId in pairs(BOSS_CONFIGS) do
		local key = stateKey(player, bossId)
		respawnTokens[key] = nil
		removeCooldownMarker(player, bossId)
		removeBoss(player, bossId)
	end
end)

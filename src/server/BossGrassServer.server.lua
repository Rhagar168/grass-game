local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local BOSS_MAX_HEALTH = 250
local BOSS_ID = "AncientGrass"
local LOCATION_ID = "Forest"
local GRASS_CORE_REWARD = 1
local RESPAWN_SECONDS = 3 * 60 * 60
local RESPAWN_ATTRIBUTE = "AncientGrassRespawnAt"

local bossesFolder = workspace:WaitForChild("Bosses")
local ancientFolder = bossesFolder:WaitForChild("AncientGrass")
local sourceBoss = ancientFolder:WaitForChild("Boss")

-- Keep the Studio-built boss as a server-only template. Players only see
-- their own runtime clone.
local template = sourceBoss:Clone()
template.Name = "AncientGrassTemplate"
template.Parent = ServerStorage
sourceBoss:Destroy()

local activeFolder = bossesFolder:FindFirstChild("Active")
if not activeFolder then
	activeFolder = Instance.new("Folder")
	activeFolder.Name = "Active"
	activeFolder.Parent = bossesFolder
end

local activeByPlayer = {}
local respawnTokens = {}
local cooldownMarkers = {}
local spawnBoss

local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function removeCooldownMarker(player)
	local marker = cooldownMarkers[player]
	cooldownMarkers[player] = nil
	if marker and marker.Parent then
		marker:Destroy()
	end
end

local function showCooldownMarker(player, position)
	removeCooldownMarker(player)

	local marker = Instance.new("Model")
	marker.Name = "AncientGrassCooldown_" .. player.UserId
	marker:SetAttribute("OwnerUserId", player.UserId)
	marker.Parent = activeFolder

	local anchor = Instance.new("Part")
	anchor.Name = "CooldownAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
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
	gui.Size = UDim2.fromOffset(280, 72)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 45
	gui.Parent = marker

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Font = Enum.Font.GothamBlack
	title.Text = "ANCIENT GRASS RESPAWNS IN"
	title.TextColor3 = Color3.fromRGB(235, 245, 235)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.3
	title.Parent = gui

	local timer = Instance.new("TextLabel")
	timer.BackgroundTransparency = 1
	timer.Position = UDim2.fromOffset(0, 32)
	timer.Size = UDim2.new(1, 0, 0, 34)
	timer.Font = Enum.Font.GothamBlack
	timer.TextColor3 = Color3.fromRGB(75, 220, 105)
	timer.TextScaled = true
	timer.TextStrokeTransparency = 0.25
	timer.Parent = gui

	cooldownMarkers[player] = marker

	task.spawn(function()
		while marker.Parent and player.Parent do
			local left = (player:GetAttribute(RESPAWN_ATTRIBUTE) or 0) - os.time()
			if left <= 0 then
				break
			end
			timer.Text = formatTime(left)
			task.wait(1)
		end
	end)
end

local function scheduleRespawn(player)
	respawnTokens[player] = (respawnTokens[player] or 0) + 1
	local token = respawnTokens[player]
	local respawnAt = player:GetAttribute(RESPAWN_ATTRIBUTE) or 0
	local delaySeconds = math.max(0, respawnAt - os.time())

	if delaySeconds <= 0 then
		return
	end

	task.delay(delaySeconds, function()
		if not player.Parent or respawnTokens[player] ~= token then
			return
		end
		if player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("ForestUnlocked") ~= true then
			return
		end
		if (player:GetAttribute(RESPAWN_ATTRIBUTE) or 0) > os.time() then
			scheduleRespawn(player)
			return
		end
		player:SetAttribute(RESPAWN_ATTRIBUTE, 0)
		removeCooldownMarker(player)
		spawnBoss(player)
	end)
end

local function addHealthBar(model, hitbox)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BossHealthBar"
	gui.Adornee = hitbox
	gui.Size = UDim2.fromOffset(260, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Parent = model

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 25)
	title.Font = Enum.Font.GothamBlack
	title.Text = "ANCIENT GRASS"
	title.TextColor3 = Color3.fromRGB(235, 245, 235)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.35
	title.Parent = gui

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Position = UDim2.fromOffset(0, 31)
	back.Size = UDim2.new(1, 0, 0, 20)
	back.BackgroundColor3 = Color3.fromRGB(20, 27, 23)
	back.BorderSizePixel = 0
	back.Parent = gui

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 6)
	backCorner.Parent = back

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(58, 74, 79)
	stroke.Thickness = 2
	stroke.Parent = back

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(48, 180, 82)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = fill

	local hp = Instance.new("TextLabel")
	hp.Name = "HP"
	hp.BackgroundTransparency = 1
	hp.Size = UDim2.fromScale(1, 1)
	hp.Font = Enum.Font.GothamBlack
	hp.TextColor3 = Color3.new(1, 1, 1)
	hp.TextScaled = true
	hp.TextStrokeTransparency = 0.25
	hp.ZIndex = 2
	hp.Parent = back

	-- Static HP bar: only the number changes while cutting.
	fill.Size = UDim2.fromScale(1, 1)

	local function update()
		local health = math.max(0, hitbox:GetAttribute("Health") or 0)
		local maxHealth = math.max(1, hitbox:GetAttribute("MaxHealth") or BOSS_MAX_HEALTH)
		hp.Text = string.format("%s / %s HP", math.floor(health + 0.5), math.floor(maxHealth + 0.5))
	end

	hitbox:GetAttributeChangedSignal("Health"):Connect(update)
	update()
end

local function bounceBoss(model, amount, duration)
	if not model or not model.Parent then return end
	if model:GetAttribute("BounceRunning") then return end
	model:SetAttribute("BounceRunning", true)

	local startPivot = model:GetPivot()
	local value = Instance.new("CFrameValue")
	value.Value = startPivot

	local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(value.Value)
		end
	end)

	local up = TweenService:Create(
		value,
		TweenInfo.new(duration * 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Value = startPivot * CFrame.new(0, amount, 0)}
	)
	local down = TweenService:Create(
		value,
		TweenInfo.new(duration * 0.58, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{Value = startPivot}
	)

	up:Play()
	up.Completed:Wait()
	if model.Parent then
		down:Play()
		down.Completed:Wait()
	end

	connection:Disconnect()
	value:Destroy()
	if model.Parent then
		model:PivotTo(startPivot)
		model:SetAttribute("BounceRunning", false)
	end
end

local function removeBoss(player)
	local model = activeByPlayer[player]
	activeByPlayer[player] = nil
	if model and model.Parent then
		model:Destroy()
	end
end

spawnBoss = function(player)
	if activeByPlayer[player] and activeByPlayer[player].Parent then
		return
	end
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end
	if player:GetAttribute("ForestUnlocked") ~= true then
		return
	end
	local respawnAt = player:GetAttribute(RESPAWN_ATTRIBUTE) or 0
	if respawnAt > os.time() then
		if not cooldownMarkers[player] then
			local templateModel = template
			local parts = {}
			for _, obj in ipairs(templateModel:GetDescendants()) do
				if obj:IsA("BasePart") then table.insert(parts, obj) end
			end
			if templateModel:IsA("BasePart") then table.insert(parts, templateModel) end
			if #parts > 0 then
				local minV, maxV
				for _, part in ipairs(parts) do
					local p = part.Position
					minV = minV and Vector3.new(math.min(minV.X,p.X),math.min(minV.Y,p.Y),math.min(minV.Z,p.Z)) or p
					maxV = maxV and Vector3.new(math.max(maxV.X,p.X),math.max(maxV.Y,p.Y),math.max(maxV.Z,p.Z)) or p
				end
				showCooldownMarker(player, (minV + maxV) / 2)
			end
		end
		scheduleRespawn(player)
		return
	elseif respawnAt ~= 0 then
		player:SetAttribute(RESPAWN_ATTRIBUTE, 0)
	end

	local cloned = template:Clone()
	local model

	if cloned:IsA("Model") then
		model = cloned
	else
		model = Instance.new("Model")
		for _, child in ipairs(cloned:GetChildren()) do
			child.Parent = model
		end
		cloned:Destroy()
	end

	model.Name = BOSS_ID .. "_" .. player.UserId
	model:SetAttribute("BossGrass", true)
	model:SetAttribute("BossId", BOSS_ID)
	model:SetAttribute("LocationId", LOCATION_ID)
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
	local bottomY = boxCFrame.Position.Y - boxSize.Y / 2

	local hitbox = Instance.new("Part")
	hitbox.Name = "BossHitbox"
	hitbox.Size = Vector3.new(
		math.max(4, boxSize.X),
		math.max(4, boxSize.Y),
		math.max(4, boxSize.Z)
	)
	hitbox.CFrame = CFrame.new(
		boxCFrame.Position.X,
		bottomY + math.min(2.5, hitbox.Size.Y / 2),
		boxCFrame.Position.Z
	)
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = false
	hitbox:SetAttribute("BossGrass", true)
	hitbox:SetAttribute("BossId", BOSS_ID)
	hitbox:SetAttribute("LocationId", LOCATION_ID)
	hitbox:SetAttribute("OwnerUserId", player.UserId)
	hitbox:SetAttribute("Health", BOSS_MAX_HEALTH)
	hitbox:SetAttribute("MaxHealth", BOSS_MAX_HEALTH)
	hitbox:SetAttribute("XPReward", 0)
	hitbox:SetAttribute("RewardMultiplier", 1)
	hitbox.Parent = model

	CollectionService:AddTag(hitbox, "Cuttable")
	addHealthBar(model, hitbox)
	activeByPlayer[player] = model

	local dead = false
	local previousHealth = BOSS_MAX_HEALTH
	hitbox:GetAttributeChangedSignal("Health"):Connect(function()
		if dead then
			return
		end
		local health = hitbox:GetAttribute("Health") or 0

		if health < previousHealth and health > 0 then
			task.spawn(bounceBoss, model, 0.35, 0.18)
		end
		previousHealth = health

		if health <= 0 then
			dead = true

			local currentCores = player:GetAttribute("GrassCores") or 0
			player:SetAttribute("GrassCores", currentCores + GRASS_CORE_REWARD)

			local respawnAt = os.time() + RESPAWN_SECONDS
			player:SetAttribute(RESPAWN_ATTRIBUTE, respawnAt)
			local markerPosition = model:GetBoundingBox().Position
			showCooldownMarker(player, markerPosition)
			scheduleRespawn(player)
			print("ANCIENT BOSS DEFEATED:", player.Name, "| +1 GC | respawn:", respawnAt)

			task.spawn(bounceBoss, model, 1.1, 0.42)

			task.delay(0.48, function()
				if activeByPlayer[player] == model then
					activeByPlayer[player] = nil
				end
				if model.Parent then
					model:Destroy()
				end
			end)
		end
	end)
end

local function setupPlayer(player)
	local function refresh()
		if player:GetAttribute("DataLoaded") == true
			and player:GetAttribute("ForestUnlocked") == true then
			spawnBoss(player)
		else
			removeBoss(player)
		end
	end

	player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)
	player:GetAttributeChangedSignal("ForestUnlocked"):Connect(refresh)
	refresh()
end

-- Studio/admin test command:
-- In the SERVER Command Bar run:
-- game.ReplicatedStorage.RespawnBosses:Fire()
local respawnBossesCommand = game:GetService("ReplicatedStorage"):FindFirstChild("RespawnBosses")
if not respawnBossesCommand then
	respawnBossesCommand = Instance.new("BindableEvent")
	respawnBossesCommand.Name = "RespawnBosses"
	respawnBossesCommand.Parent = game:GetService("ReplicatedStorage")
end

respawnBossesCommand.Event:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		respawnTokens[player] = (respawnTokens[player] or 0) + 1
		player:SetAttribute(RESPAWN_ATTRIBUTE, 0)
		removeCooldownMarker(player)
		removeBoss(player)
		spawnBoss(player)
	end
	print("BOSSES RESPAWNED")
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	respawnTokens[player] = nil
	removeCooldownMarker(player)
	removeBoss(player)
end)

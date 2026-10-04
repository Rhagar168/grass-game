local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local BOSS_MAX_HEALTH = 250
local BOSS_ID = "AncientGrass"
local LOCATION_ID = "Forest"
local GRASS_CORE_REWARD = 1
local RESPAWN_SECONDS = 12 * 60 * 60
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

	local function update()
		local health = math.max(0, hitbox:GetAttribute("Health") or 0)
		local maxHealth = math.max(1, hitbox:GetAttribute("MaxHealth") or BOSS_MAX_HEALTH)
		fill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
		hp.Text = string.format("%s / %s HP", math.floor(health + 0.5), math.floor(maxHealth + 0.5))
	end

	hitbox:GetAttributeChangedSignal("Health"):Connect(update)
	update()
end

local function removeBoss(player)
	local model = activeByPlayer[player]
	activeByPlayer[player] = nil
	if model and model.Parent then
		model:Destroy()
	end
end

function spawnBoss(player)
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
	hitbox:GetAttributeChangedSignal("Health"):Connect(function()
		if dead then
			return
		end
		local health = hitbox:GetAttribute("Health") or 0
		if health <= 0 then
			dead = true

			local currentCores = player:GetAttribute("GrassCores") or 0
			player:SetAttribute("GrassCores", currentCores + GRASS_CORE_REWARD)

			local respawnAt = os.time() + RESPAWN_SECONDS
			player:SetAttribute(RESPAWN_ATTRIBUTE, respawnAt)
			scheduleRespawn(player)

			task.delay(0.12, function()
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

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	respawnTokens[player] = nil
	removeBoss(player)
end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gateways = workspace:WaitForChild("Gateways")

local GATEWAYS = {
	{
		modelName = "ForestGT",
		previousBiome = "Plains",
		nextBiome = "Forest",
		totalGrass = 500,
		unlockAttribute = "ForestUnlocked",
	},
	{
		modelName = "SavannaGT",
		previousBiome = "Forest",
		nextBiome = "Savanna",
		totalGrass = 1000,
		unlockAttribute = "SavannaUnlocked",
	},
	{
		modelName = "JungleGT",
		previousBiome = "Savanna",
		nextBiome = "Jungle",
		totalGrass = 1000,
		unlockAttribute = "JungleUnlocked",
	},
}

local function findGatePart(container)
	if container:IsA("BasePart") and container:FindFirstChild("SurfaceGui") then
		return container
	end

	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:FindFirstChild("SurfaceGui") then
			return descendant
		end
	end

	return nil
end

local function setGateOpen(container, gateway, surfaceGui, instant)
	surfaceGui.Enabled = false

	-- The actual blocking panel has the SurfaceGui. Decorative frame/pillars stay visible.
	gateway.CanCollide = false
	gateway.CanTouch = false
	gateway.CanQuery = false

	if instant then
		gateway.Transparency = 1
	end
end

local function setupGateway(config)
	local container = gateways:WaitForChild(config.modelName)
	local gateway = findGatePart(container)

	if not gateway then
		warn(config.modelName .. " has no gate part with SurfaceGui")
		return
	end

	local surfaceGui = gateway:WaitForChild("SurfaceGui")
	local progressBarBG = surfaceGui:WaitForChild("ProgressBarBG")
	local progressFill = progressBarBG:WaitForChild("ProgressFill")
	local progressText = progressBarBG:WaitForChild("ProgressText")
	local lockedText = surfaceGui:WaitForChild("LockedText")
	local progressTitle = surfaceGui:WaitForChild("ProgressTitle")
	local unlockText = surfaceGui:WaitForChild("UnlockText")

	local opening = false
	local initialized = false

	local function openGateway(animate)
		if opening or gateway.Transparency >= 1 then
			return
		end

		opening = true
		setGateOpen(container, gateway, surfaceGui, not animate)

		if animate then
			local lightUp = TweenService:Create(
				gateway,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Color = Color3.new(1, 1, 1)}
			)
			lightUp:Play()
			lightUp.Completed:Wait()

			local fadeOut = TweenService:Create(
				gateway,
				TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Transparency = 1}
			)
			fadeOut:Play()
			fadeOut.Completed:Wait()
		end

		opening = false
	end

	local function updateProgress()
		local remaining = player:GetAttribute(config.previousBiome .. "GrassRemaining")
		if typeof(remaining) ~= "number" then
			return
		end

		if player:GetAttribute(config.unlockAttribute) == true then
			-- Saved unlocks must always force the gate open on join.
			-- Never depend on which attribute replicated first.
			openGateway(false)
			return
		end

		local progress = math.clamp((config.totalGrass - remaining) / config.totalGrass, 0, 1)
		local percent = math.floor(progress * 100 + 0.5)

		TweenService:Create(
			progressFill,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.fromScale(progress, 1)}
		):Play()

		progressText.Text = percent .. "%"
		lockedText.Text = "LOCKED"
		unlockText.Text = "Complete the " .. config.previousBiome .. " location to unlock"
		progressTitle.Text = string.upper(config.previousBiome) .. " PROGRESS"
	end

	player:GetAttributeChangedSignal(config.previousBiome .. "GrassRemaining"):Connect(updateProgress)
	player:GetAttributeChangedSignal(config.unlockAttribute):Connect(function()
		if initialized and player:GetAttribute(config.unlockAttribute) == true then
			openGateway(true)
		end
	end)

	updateProgress()
	initialized = true
end

if player:GetAttribute("DataLoaded") ~= true then
	player:GetAttributeChangedSignal("DataLoaded"):Wait()
end

for _, config in ipairs(GATEWAYS) do
	task.spawn(setupGateway, config)
end

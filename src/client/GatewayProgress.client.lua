local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gateways = workspace:WaitForChild("Gateways")

local GATEWAYS = {
	{modelName = "ForestGT", previousBiome = "Plains", totalGrass = 500, unlockAttribute = "ForestUnlocked"},
	{modelName = "SavannaGT", previousBiome = "Forest", totalGrass = 1000, unlockAttribute = "SavannaUnlocked"},
	{modelName = "JungleGT", previousBiome = "Savanna", totalGrass = 1000, unlockAttribute = "JungleUnlocked"},
	{modelName = "TundraGT", previousBiome = "Jungle", totalGrass = 1000, unlockAttribute = "TundraUnlocked"},
	{modelName = "VolcanoGT", previousBiome = "Tundra", totalGrass = 1000, unlockAttribute = "VolcanoUnlocked"},
	{modelName = "BeachGT", previousBiome = "Volcano", totalGrass = 1000, unlockAttribute = "BeachUnlocked"},
}

local function getGatewayParts(container)
	-- All gateway imports use: Gateways > <Biome>GT > Plane > SurfaceGui
	local panel = container:FindFirstChild("Plane")
	if not panel then
		panel = container:WaitForChild("Plane", 5)
	end

	if not panel or not panel:IsA("BasePart") then
		return nil, nil
	end

	local surfaceGui = panel:FindFirstChild("SurfaceGui")
	if not surfaceGui then
		surfaceGui = panel:WaitForChild("SurfaceGui", 5)
	end

	return panel, surfaceGui
end

local function setupGateway(config)
	local container = gateways:WaitForChild(config.modelName)
	local panel, surfaceGui = getGatewayParts(container)

	if not panel or not panel:IsA("BasePart") or not surfaceGui then
		warn("Gateway setup failed:", config.modelName)
		return
	end

	local progressBarBG = surfaceGui:WaitForChild("ProgressBarBG")
	local progressFill = progressBarBG:FindFirstChild("ProgressFill", true)
	local progressText = progressBarBG:FindFirstChild("ProgressText", true)
	local lockedText = surfaceGui:FindFirstChild("LockedText", true)
	local progressTitle = surfaceGui:FindFirstChild("ProgressTitle", true)
	local unlockText = surfaceGui:FindFirstChild("UnlockText", true)

	local closedColor = panel.Color
	local closedTransparency = panel.Transparency
	local opening = false
	local ready = false

	local function closeGate()
		opening = false
		panel.Color = closedColor
		panel.Transparency = closedTransparency
		panel.CanCollide = true
		panel.CanTouch = true
		panel.CanQuery = true
		surfaceGui.Enabled = true
	end

	local function openGate(animate)
		if opening then
			return
		end

		opening = true
		panel.CanCollide = false
		panel.CanTouch = false
		panel.CanQuery = false
		surfaceGui.Enabled = false

		if animate then
			panel.Transparency = closedTransparency
			panel.Color = closedColor

			local lightUp = TweenService:Create(
				panel,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Color = Color3.new(1, 1, 1)}
			)
			lightUp:Play()
			lightUp.Completed:Wait()

			local fadeOut = TweenService:Create(
				panel,
				TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Transparency = 1}
			)
			fadeOut:Play()
			fadeOut.Completed:Wait()
		else
			panel.Transparency = 1
		end

		opening = false
	end

	local function refresh(animateUnlock)
		local unlocked = player:GetAttribute(config.unlockAttribute) == true
		if unlocked then
			openGate(animateUnlock)
			return
		end

		closeGate()

		local remaining = player:GetAttribute(config.previousBiome .. "GrassRemaining")
		if typeof(remaining) ~= "number" then
			return
		end

		local progress = math.clamp((config.totalGrass - remaining) / config.totalGrass, 0, 1)
		local percent = math.floor(progress * 100 + 0.5)

		progressFill.Size = UDim2.fromScale(progress, 1)
		progressText.Text = percent .. "%"
		lockedText.Text = "LOCKED"
		unlockText.Text = "Complete the " .. config.previousBiome .. " location to unlock"
		progressTitle.Text = string.upper(config.previousBiome) .. " PROGRESS"
	end

	-- DataLoaded is already true before setupGateway runs. Apply the saved state once,
	-- synchronously, before listening for live changes.
	refresh(false)
	ready = true

	player:GetAttributeChangedSignal(config.unlockAttribute):Connect(function()
		refresh(ready and player:GetAttribute(config.unlockAttribute) == true)
	end)

	player:GetAttributeChangedSignal(config.previousBiome .. "GrassRemaining"):Connect(function()
		if player:GetAttribute(config.unlockAttribute) ~= true then
			refresh(false)
		end
	end)
end

while player:GetAttribute("DataLoaded") ~= true do
	player:GetAttributeChangedSignal("DataLoaded"):Wait()
end

for _, config in ipairs(GATEWAYS) do
	setupGateway(config)
end

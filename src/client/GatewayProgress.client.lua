local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gateways = workspace:WaitForChild("Gateways")

local TOTAL_PLAINS_GRASS = 500
local gateway = gateways:WaitForChild("Plane")
local surfaceGui = gateway:WaitForChild("SurfaceGui")

local progressBarBG = surfaceGui:WaitForChild("ProgressBarBG")
local progressFill = progressBarBG:WaitForChild("ProgressFill")
local progressText = progressBarBG:WaitForChild("ProgressText")
local lockedText = surfaceGui:WaitForChild("LockedText")
local progressTitle = surfaceGui:WaitForChild("ProgressTitle")
local unlockText = surfaceGui:WaitForChild("UnlockText")

local closedPosition = gateway.Position
local openedPosition = closedPosition - Vector3.new(0, gateway.Size.Y + 2, 0)
local opening = false

local function setUnlockedVisuals()
	lockedText.Text = "UNLOCKED"
	unlockText.Text = "Forest unlocked!"
	progressTitle.Text = "PLAINS COMPLETE"
	progressText.Text = "100%"
	progressFill.Size = UDim2.fromScale(1, 1)
end

local function openGateway(animate)
	if opening or gateway.Position.Y <= openedPosition.Y + 0.1 then
		return
	end

	opening = true
	setUnlockedVisuals()
	gateway.CanCollide = false

	if animate then
		local tween = TweenService:Create(
			gateway,
			TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{Position = openedPosition}
		)
		tween:Play()
		tween.Completed:Wait()
	else
		gateway.Position = openedPosition
	end

	opening = false
end

local function updateProgress()
	local remaining = player:GetAttribute("PlainsGrassRemaining")
	if remaining == nil then
		return
	end

	if player:GetAttribute("ForestUnlocked") == true then
		openGateway(false)
		return
	end

	local progress = math.clamp((TOTAL_PLAINS_GRASS - remaining) / TOTAL_PLAINS_GRASS, 0, 1)
	local percent = math.floor(progress * 100 + 0.5)

	TweenService:Create(
		progressFill,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.fromScale(progress, 1)}
	):Play()

	progressText.Text = percent .. "%"

	if progress >= 1 then
		player:SetAttribute("ForestUnlocked", true)
		openGateway(true)
	else
		lockedText.Text = "LOCKED"
		unlockText.Text = "Complete the Plains location to unlock"
		progressTitle.Text = "PLAINS PROGRESS"
	end
end

player:GetAttributeChangedSignal("PlainsGrassRemaining"):Connect(updateProgress)
player:GetAttributeChangedSignal("ForestUnlocked"):Connect(function()
	if player:GetAttribute("ForestUnlocked") == true then
		openGateway(true)
	end
end)

if player:GetAttribute("DataLoaded") ~= true then
	player:GetAttributeChangedSignal("DataLoaded"):Wait()
end

updateProgress()

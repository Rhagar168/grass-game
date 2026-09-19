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

local closedColor = gateway.Color
local opening = false

local function setUnlockedVisuals()
	lockedText.Text = "UNLOCKED"
	unlockText.Text = "Forest unlocked!"
	progressTitle.Text = "PLAINS COMPLETE"
	progressText.Text = "100%"
	progressFill.Size = UDim2.fromScale(1, 1)
end

local function openGateway(animate)
	if opening or gateway.Transparency >= 1 then
		return
	end

	opening = true
	setUnlockedVisuals()
	gateway.CanCollide = false

	if animate then
		local lightUp = TweenService:Create(
			gateway,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Color = Color3.new(1, 1, 1)}
		)
		lightUp:Play()
		lightUp.Completed:Wait()

		local fadeOut = TweenService:Create(
			gateway,
			TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Transparency = 1}
		)
		fadeOut:Play()
		fadeOut.Completed:Wait()
	else
		gateway.Color = closedColor
		gateway.Transparency = 1
	end

	surfaceGui.Enabled = false
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

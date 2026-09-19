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

local function updateProgress()
	local remaining = player:GetAttribute("PlainsGrassRemaining")
	if remaining == nil then
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
		lockedText.Text = "UNLOCKED"
		unlockText.Text = "Forest unlocked!"
		progressTitle.Text = "PLAINS COMPLETE"
	else
		lockedText.Text = "LOCKED"
		unlockText.Text = "Complete the Plains location to unlock"
		progressTitle.Text = "PLAINS PROGRESS"
	end
end

player:GetAttributeChangedSignal("PlainsGrassRemaining"):Connect(updateProgress)

if player:GetAttribute("DataLoaded") ~= true then
	player:GetAttributeChangedSignal("DataLoaded"):Wait()
end

updateProgress()

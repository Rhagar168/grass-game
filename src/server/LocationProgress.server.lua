local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local progressEvent = ReplicatedStorage:WaitForChild("LocationProgressUpdate")

local LOCATION_ID = "Plains"
local TOTAL_GRASS = 500

local boards = workspace:WaitForChild("Boards")
local board = boards:WaitForChild("Plains")
local boardPart = board:WaitForChild("Cube")
local surfaceGui = boardPart:WaitForChild("SurfaceGui")
local progressBarBG = surfaceGui:WaitForChild("ProgressBarBG")
local progressFill = progressBarBG:WaitForChild("ProgressFill")
local progressText = progressBarBG:WaitForChild("ProgressText")

progressBarBG.ClipsDescendants = true

local lastPlayer = nil

local function updateProgress(player)
	if not player or not player.Parent then
		return
	end

	lastPlayer = player

	local remaining = player:GetAttribute("PlainsGrassRemaining")
	if typeof(remaining) ~= "number" then
		remaining = TOTAL_GRASS
	end

	remaining = math.clamp(remaining, 0, TOTAL_GRASS)
	local cleaned = TOTAL_GRASS - remaining
	local progress = math.clamp(cleaned / TOTAL_GRASS, 0, 1)
	local percent = math.floor(progress * 100 + 0.5)

	TweenService:Create(
		progressFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(progress, 0, 1, 0)}
	):Play()

	if percent >= 100 then
		progressText.Text = "COMPLETE!"
		board:SetAttribute("CanReset", true)
	else
		progressText.Text = percent .. "%"
		board:SetAttribute("CanReset", false)
	end

	print(
		"Plains progress:", player.Name,
		percent .. "%",
		"Remaining:", remaining,
		"Total:", TOTAL_GRASS
	)
end

local function setupPlayer(player)
	if player:GetAttribute("DataLoaded") ~= true then
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end

	if player.Parent then
		task.wait(0.2)
		updateProgress(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

progressEvent.Event:Connect(function(locationId, player)
	if locationId ~= LOCATION_ID then
		return
	end

	if player then
		updateProgress(player)
	elseif lastPlayer and lastPlayer.Parent then
		-- Compatibility with older callers that only send locationId.
		updateProgress(lastPlayer)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if lastPlayer == player then
		lastPlayer = nil
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		progressText.Text = "0%"
		board:SetAttribute("CanReset", false)
	end
end)

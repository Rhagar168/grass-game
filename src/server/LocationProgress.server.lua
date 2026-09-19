local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local progressEvent = ReplicatedStorage:WaitForChild("LocationProgressUpdate")
local boards = workspace:WaitForChild("Boards")

local LOCATIONS = {
	Plains = {
		totalGrass = 500,
		boardName = "PlainsBoard",
	},
	Forest = {
		totalGrass = 1000,
		boardName = "ForestBoard",
	},
}

local boardData = {}

for locationId, config in pairs(LOCATIONS) do
	local locationFolder = boards:WaitForChild(locationId)
	local board = locationFolder:WaitForChild(config.boardName)
	local boardPart = board:WaitForChild("Cube")
	local surfaceGui = boardPart:WaitForChild("SurfaceGui")
	local progressBarBG = surfaceGui:WaitForChild("ProgressBarBG")

	progressBarBG.ClipsDescendants = true

	boardData[locationId] = {
		folder = locationFolder,
		progressFill = progressBarBG:WaitForChild("ProgressFill"),
		progressText = progressBarBG:WaitForChild("ProgressText"),
	}
end

local function updateProgress(player, locationId)
	local config = LOCATIONS[locationId]
	local data = boardData[locationId]
	if not config or not data or not player or not player.Parent then
		return
	end

	local remaining = player:GetAttribute(locationId .. "GrassRemaining")
	if typeof(remaining) ~= "number" then
		remaining = config.totalGrass
	end

	remaining = math.clamp(remaining, 0, config.totalGrass)
	local progress = math.clamp((config.totalGrass - remaining) / config.totalGrass, 0, 1)
	local percent = math.floor(progress * 100 + 0.5)

	TweenService:Create(
		data.progressFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(progress, 0, 1, 0)}
	):Play()

	if percent >= 100 then
		data.progressText.Text = "COMPLETE!"
		data.folder:SetAttribute("CanReset", true)
	else
		data.progressText.Text = percent .. "%"
		data.folder:SetAttribute("CanReset", false)
	end
end

local function setupPlayer(player)
	if player:GetAttribute("DataLoaded") ~= true then
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end

	if not player.Parent then
		return
	end

	task.wait(0.2)
	for locationId in pairs(LOCATIONS) do
		updateProgress(player, locationId)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

progressEvent.Event:Connect(function(locationId, player)
	if LOCATIONS[locationId] and player then
		updateProgress(player, locationId)
	end
end)

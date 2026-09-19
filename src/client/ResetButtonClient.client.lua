local ReplicatedStorage = game:GetService("ReplicatedStorage")

local resetEvent = ReplicatedStorage:WaitForChild("ResetBiome")
local boards = workspace:WaitForChild("Boards")

local LOCATIONS = {
	Plains = "PlainsBoard",
	Forest = "ForestBoard",
	Savanna = "SavannaBoard",
	Jungle = "JungleBoard",
}

local LOCKED_COLOR = Color3.fromRGB(80, 80, 80)
local UNLOCKED_COLOR = Color3.fromRGB(102, 229, 134)
local LOCKED_TEXT_COLOR = Color3.fromRGB(160, 160, 160)
local UNLOCKED_TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local function setupResetButton(locationId, boardName)
	local board = boards:WaitForChild(locationId)
	local locationBoard = board:WaitForChild(boardName)
	local cube = locationBoard:WaitForChild("Cube")
	local surfaceGui = cube:WaitForChild("SurfaceGui")
	local resetButton = surfaceGui:WaitForChild("TextButton")

	local function updateButton()
		local canReset = board:GetAttribute("CanReset") == true

		if canReset then
			resetButton.BackgroundColor3 = UNLOCKED_COLOR
			resetButton.TextColor3 = UNLOCKED_TEXT_COLOR
			resetButton.AutoButtonColor = true
		else
			resetButton.BackgroundColor3 = LOCKED_COLOR
			resetButton.TextColor3 = LOCKED_TEXT_COLOR
			resetButton.AutoButtonColor = false
		end

		resetButton.Text = "RESET"
	end

	board:GetAttributeChangedSignal("CanReset"):Connect(updateButton)
	updateButton()

	resetButton.MouseButton1Click:Connect(function()
		if board:GetAttribute("CanReset") == true then
			resetEvent:FireServer(locationId)
		end
	end)
end

for locationId, boardName in pairs(LOCATIONS) do
	task.spawn(setupResetButton, locationId, boardName)
end

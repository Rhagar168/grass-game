local ReplicatedStorage = game:GetService("ReplicatedStorage")

local resetEvent =
	ReplicatedStorage:WaitForChild("ResetBusStop")

local boards =
	workspace:WaitForChild("Boards")

local board =
	boards:WaitForChild("BusStop")

local cube =
	board:WaitForChild("Cube")

local surfaceGui =
	cube:WaitForChild("SurfaceGui")

local resetButton =
	surfaceGui:WaitForChild("TextButton")


-- ========================================
-- BARVY
-- ========================================

local LOCKED_COLOR =
	Color3.fromRGB(80, 80, 80)

local UNLOCKED_COLOR =
	Color3.fromRGB(102, 229, 134)

local LOCKED_TEXT_COLOR =
	Color3.fromRGB(160, 160, 160)

local UNLOCKED_TEXT_COLOR =
	Color3.fromRGB(255, 255, 255)


-- ========================================
-- UPDATE RESET BUTTONU
-- ========================================

local function updateButton()

	local canReset =
		board:GetAttribute("CanReset") == true


	if canReset then

		-- hotova lokace
		resetButton.BackgroundColor3 =
			UNLOCKED_COLOR

		resetButton.TextColor3 =
			UNLOCKED_TEXT_COLOR

		resetButton.Text =
			"RESET"

		resetButton.AutoButtonColor =
			true

	else

		-- lokace jeste neni hotova
		resetButton.BackgroundColor3 =
			LOCKED_COLOR

		resetButton.TextColor3 =
			LOCKED_TEXT_COLOR

		resetButton.Text =
			"RESET"

		resetButton.AutoButtonColor =
			false

	end
end


-- ========================================
-- ZMENA CanReset
-- ========================================

board:GetAttributeChangedSignal(
	"CanReset"
):Connect(function()

	updateButton()

end)


-- prvni update
updateButton()


-- ========================================
-- KLIKNUTI
-- ========================================

resetButton.MouseButton1Click:Connect(function()

	local canReset =
		board:GetAttribute("CanReset") == true


	if not canReset then
		return
	end


	resetEvent:FireServer()

end)
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local boards = workspace:WaitForChild("Boards")

local BIOMES = {
	"Plains",
	"Forest",
	"Savanna",
	"Jungle",
	"Tundra",
	"Volcano",
	"Beach",
}

-- ========================================
-- SETUP BOARD
-- ========================================

local function setupBoard(biomeId)

	local biomeFolder =
		boards:WaitForChild(biomeId)

	local board =
		biomeFolder:WaitForChild(
			biomeId .. "Board"
		)

	local cube =
		board:WaitForChild("Cube")

	local surfaceGui =
		cube:WaitForChild("SurfaceGui")

	local resetCountText =
		surfaceGui:WaitForChild(
			"ResetCountText"
		)

	local attributeName =
		biomeId .. "ResetCount"

	-- ========================================
	-- UPDATE
	-- ========================================

	local function update()

		local resetCount =
			player:GetAttribute(
				attributeName
			) or 0

		resetCountText.Text =
			"RESETS: "
			.. tostring(resetCount)
	end

	-- ========================================
	-- LISTEN
	-- ========================================

	player:GetAttributeChangedSignal(
		attributeName
	):Connect(
		update
	)

	update()
end

-- ========================================
-- ALL BIOMES
-- ========================================

for _, biomeId in ipairs(BIOMES) do

	task.spawn(
		function()

			setupBoard(
				biomeId
			)
		end
	)
end

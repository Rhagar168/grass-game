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

	local template = cube:WaitForChild("SurfaceGui")
    -- A world SurfaceGui can be modified by other board scripts.
    -- Render a private copy in PlayerGui for this player only.
    local surfaceGui = template:Clone()
    surfaceGui.Name = "PersonalResetBoard_" .. biomeId
    surfaceGui.Adornee = cube
    surfaceGui.Enabled = true
    surfaceGui.Parent = player:WaitForChild("PlayerGui")
    template.Enabled = false

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

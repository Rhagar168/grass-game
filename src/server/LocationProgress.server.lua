local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")


-- ========================================
-- EVENT
-- ========================================

local progressEvent =
	ReplicatedStorage:WaitForChild(
		"LocationProgressUpdate"
	)


-- ========================================
-- NASTAVENI
-- ========================================

local LOCATION_ID = "BusStop"


-- ========================================
-- TABULE
-- ========================================

local boards =
	workspace:WaitForChild("Boards")

local board =
	boards:WaitForChild("BusStop")

local boardPart =
	board:WaitForChild("Cube")

local surfaceGui =
	boardPart:WaitForChild("SurfaceGui")

local progressBarBG =
	surfaceGui:WaitForChild("ProgressBarBG")

local progressFill =
	progressBarBG:WaitForChild("ProgressFill")

-- podle tveho Exploreru se text jmenuje ProgressBar
local progressText =
	progressBarBG:WaitForChild("ProgressText")


-- aby zelena vypln nelezla ven z baru
progressBarBG.ClipsDescendants = true


-- ========================================
-- DATA
-- ========================================

local totalGrass = 0


-- ========================================
-- POCITANI TRAVY
-- ========================================

local function countGrass()

	local count = 0


	for _, plant in ipairs(
		CollectionService:GetTagged("Cuttable")
		) do

		if not plant:IsA("BasePart") then
			continue
		end


		if not plant:IsDescendantOf(workspace) then
			continue
		end


		if plant:GetAttribute("LocationId")
			~= LOCATION_ID then

			continue

		end


		count += 1

	end


	return count
end


-- ========================================
-- UPDATE PROGRESSU
-- ========================================

local function updateProgress()

	local remainingGrass =
		countGrass()


	if totalGrass <= 0 then

		progressFill.Size =
			UDim2.new(
				0,
				0,
				1,
				0
			)

		progressText.Text = "0%"

		return

	end


	-- kolik rostlin uz zmizelo
	local cleanedGrass =
		totalGrass - remainingGrass


	local progress =
		math.clamp(
			cleanedGrass / totalGrass,
			0,
			1
		)


	local percent =
		math.floor(
			progress * 100 + 0.5
		)


	-- ========================================
	-- ANIMACE ZELENEHO BARU
	-- ========================================

	TweenService:Create(
		progressFill,

		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{
			Size =
				UDim2.new(
					progress,
					0,
					1,
					0
				)
		}

	):Play()


	-- ========================================
	-- PROCENTA
	-- ========================================

	if percent >= 100 then

		progressText.Text = "COMPLETE!"

		board:SetAttribute("CanReset", true)

	else

		progressText.Text = percent .. "%"

		board:SetAttribute("CanReset", false)

	end


	-- ========================================
	-- DEBUG
	-- ========================================

	print(
		"BusStop progress:",
		percent .. "%",
		"Remaining:",
		remainingGrass,
		"Total:",
		totalGrass
	)

end


-- ========================================
-- CEKANI NA GRASSSPAWNER
-- ========================================

local function initialize()

	print("LocationProgress: cekam na travu...")


	-- pockame dokud se neobjevi alespon jedna rostlina
	local timeout = 0


	while countGrass() == 0
		and timeout < 10 do

		task.wait(0.25)

		timeout += 0.25

	end


	-- jeste chvilku pockame,
	-- aby GrassSpawner dokoncil vsechny rostliny
	task.wait(1)


	totalGrass =
		countGrass()


	print(
		"BUS STOP TOTAL GRASS:",
		totalGrass
	)


	updateProgress()

end


task.spawn(initialize)


-- ========================================
-- KDYZ CUTTINGSERVER ZNICI TRAVU
-- ========================================

progressEvent.Event:Connect(function(locationId)

	print(
		"Progress event:",
		locationId
	)


	if locationId ~= LOCATION_ID then
		return
	end


	-- rostlina je uz smazana,
	-- tak muzeme okamzite prepocitat
	updateProgress()

end)

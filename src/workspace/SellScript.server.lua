local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MilestoneConfig =
	require(ReplicatedStorage:WaitForChild("MilestoneConfig"))

local sellZone = script.Parent
local sellPopup = sellZone:WaitForChild("SellPopup")
local sellSound = sellZone:WaitForChild("SellSound")

-- ========================================
-- NASTAVENI
-- ========================================

local PRICE_PER_GRASS = 0.1

-- Cely obsah batohu se proda zhruba za tuto dobu.
local SELL_DURATION = 1.5
local SELL_TICKS = 20
local SELL_INTERVAL = SELL_DURATION / SELL_TICKS

-- Jak casto kontrolujeme hrace.
local CHECK_INTERVAL = 0.1

-- Mala tolerance na okraji SellZone.
local ZONE_PADDING = 1

-- Jak dlouho muze byt hrac kratce detekovan mimo zonu,
-- aniz by se prodej prerusil.
local LEAVE_GRACE_TIME = 0.35

-- ========================================
-- DATA
-- ========================================

local sellingPlayers = {}
local sellCombos = {}

-- ========================================
-- ZAOKROUHLENI
-- ========================================

local function round1(number)
	return math.floor(number * 10 + 0.5) / 10
end

local function round2(number)
	return math.floor(number * 100 + 0.5) / 100
end

local function formatNumber(number)
	local absolute = math.abs(number)

	local suffixes = {
		{1e12, "T"},
		{1e9, "B"},
		{1e6, "M"},
		{1e3, "K"},
	}

	for _, entry in ipairs(suffixes) do
		local threshold = entry[1]
		local suffix = entry[2]

		if absolute >= threshold then
			local value = number / threshold
			local formatted = string.format("%.2f", value)
			formatted = formatted:gsub("%.?0+$", "")
			return formatted .. suffix
		end
	end

	local formatted = string.format("%.2f", number)
	return formatted:gsub("%.?0+$", "")
end

-- ========================================
-- CENA ZA TRAVU
-- ========================================

local function getPricePerGrass(player)

	local flatCoins =
		player:GetAttribute("FlatCoinsBonus") or 0

	local percentCoins =
		player:GetAttribute("PercentCoinsBonus") or 0

	local milestoneCoins =
		MilestoneConfig.GetMultipliers(player).Coins

	return
		(PRICE_PER_GRASS + flatCoins)
		* (1 + percentCoins)
		* milestoneCoins
end

-- ========================================
-- JE HRAC V SELL ZONE?
-- ========================================

local function isInsideSellZone(player)

	local character = player.Character

	if not character then
		return false
	end

	local overlapParams =
		OverlapParams.new()

	overlapParams.FilterType =
		Enum.RaycastFilterType.Include

	overlapParams.FilterDescendantsInstances = {
		character
	}

	local touchingParts =
		workspace:GetPartsInPart(
			sellZone,
			overlapParams
		)

	return #touchingParts > 0
end

-- ========================================
-- MONEY POPUP
-- ========================================

local function showMoneyPopup(amount)

	local popup =
		sellPopup:Clone()

	popup.Name = "MoneyPopup"
	popup.Enabled = true
	popup.Parent = sellZone

	local text =
		popup:WaitForChild("TextLabel")

	text.Text =
		"+" .. formatNumber(amount)

	text.TextColor3 =
		Color3.fromRGB(
			255,
			210,
			50
		)

	text.TextTransparency = 0

	-- ZADNY CERNY OUTLINE
	text.TextStrokeTransparency = 1

	-- Pro jistotu vypneme i pripadny UIStroke,
	-- kdyby byl v TextLabelu vytvoreny ve Studiu.
	local uiStroke =
		text:FindFirstChildOfClass("UIStroke")

	if uiStroke then
		uiStroke.Enabled = false
	end

	local startX =
		math.random(-45, 45) / 10

	local startY =
		math.random(20, 45) / 10

	local startZ =
		math.random(-30, 30) / 10

	popup.StudsOffset =
		Vector3.new(
			startX,
			startY,
			startZ
		)

	local endX =
		startX
		+ math.random(-45, 45) / 10

	local endY =
		startY
		+ math.random(25, 50) / 10

	local endZ =
		startZ
		+ math.random(-30, 30) / 10

	local moveTween =
		TweenService:Create(
			popup,

			TweenInfo.new(
				math.random(130, 180) / 100,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				StudsOffset =
				Vector3.new(
					endX,
					endY,
					endZ
				)
			}
		)

	moveTween:Play()

	task.wait(
		math.random(80, 120) / 100
	)

	local fade =
		TweenService:Create(
			text,

			TweenInfo.new(
				0.7,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				TextTransparency = 1,
				TextStrokeTransparency = 1
			}
		)

	fade:Play()
	fade.Completed:Wait()

	if popup.Parent then
		popup:Destroy()
	end
end

local function showBigMoneyPopup(amount)

	local popup = sellPopup:Clone()

	popup.Name = "BigMoneyPopup"
	popup.Enabled = true
	popup.Parent = sellZone

	local text = popup:WaitForChild("TextLabel")

	text.Text =
		"+" .. formatNumber(amount)

	text.TextColor3 =
		Color3.fromRGB(255, 220, 55)

	text.TextTransparency = 0
	text.TextStrokeTransparency = 1

	-- Vetsi cislo nez u normalniho prodeje
	text.TextScaled = true

	local originalSize = text.Size

	text.Size = UDim2.new(
		originalSize.X.Scale * 1.45,
		originalSize.X.Offset,
		originalSize.Y.Scale * 1.45,
		originalSize.Y.Offset
	)

	local uiStroke =
		text:FindFirstChildOfClass("UIStroke")

	if uiStroke then
		uiStroke.Enabled = false
	end

	popup.StudsOffset =
		Vector3.new(0, 4, 0)

	local moveTween =
		TweenService:Create(
			popup,
			TweenInfo.new(
				1.4,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				StudsOffset =
				Vector3.new(0, 7, 0)
			}
		)

	moveTween:Play()

	task.wait(0.7)

	local fade =
		TweenService:Create(
			text,
			TweenInfo.new(
				0.6,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				TextTransparency = 1
			}
		)

	fade:Play()
	fade.Completed:Wait()

	if popup.Parent then
		popup:Destroy()
	end
end

-- ========================================
-- STOUPAJICI SELL ZVUK
-- ========================================

local function playSellSound(player)

	local combo =
		sellCombos[player] or 0

	combo += 1

	sellCombos[player] =
		combo

	local pitch =
		0.9
		+ (combo - 1) * 0.025

	pitch =
		math.clamp(
			pitch,
			0.9,
			1.35
		)

	local sound =
		sellSound:Clone()

	sound.PlaybackSpeed =
		pitch

	sound.Parent =
		sellZone

	sound:Play()

	Debris:AddItem(
		sound,
		5
	)
end

-- ========================================
-- PRODEJ CASTI TRAVY
-- ========================================

local function sellAmount(player, amount)

	if amount <= 0 then
		return 0
	end

	local grass =
		player:GetAttribute("GrassStored") or 0

	grass = round1(grass)

	if grass <= 0 then
		return 0
	end

	amount =
		math.min(
			amount,
			grass
		)

	amount =
		round1(amount)

	if amount <= 0 then
		return 0
	end

	local coins =
		player:GetAttribute("Coins") or 0

	local pricePerGrass =
		getPricePerGrass(player)

	local earned =
		round2(
			amount * pricePerGrass
		)

	local newGrass =
		round1(
			math.max(
				0,
				grass - amount
			)
		)

	local newCoins =
		round2(
			coins + earned
		)

	player:SetAttribute(
		"GrassStored",
		newGrass
	)

	player:SetAttribute(
		"Coins",
		newCoins
	)

	if earned > 0 then

		task.spawn(
			showMoneyPopup,
			earned
		)

		playSellSound(player)
	end

	return amount
end

local function instantZoneSell(player)

	if sellingPlayers[player] then
		return
	end

	local grass =
		player:GetAttribute("GrassStored") or 0

	grass = round1(grass)

	if grass <= 0 then
		return
	end

	sellingPlayers[player] = true

	local coins =
		player:GetAttribute("Coins") or 0

	local pricePerGrass =
		getPricePerGrass(player)

	local earned =
		round2(
			grass * pricePerGrass
		)

	player:SetAttribute(
		"GrassStored",
		0
	)

	player:SetAttribute(
		"Coins",
		round2(coins + earned)
	)

	if earned > 0 then

		task.spawn(
			showBigMoneyPopup,
			earned
		)

		-- pouze jedno cinknuti
		sellCombos[player] = 0
		playSellSound(player)
	end

	-- kratky debounce, aby loop nespustil dalsi prodej
	task.delay(0.2, function()

		if player.Parent then
			sellingPlayers[player] = nil
			sellCombos[player] = nil
		end
	end)
end

-- ========================================
-- START PRODEJE
-- ========================================

local function startSelling(player)

	if sellingPlayers[player] then
		return
	end

	local startingGrass =
		player:GetAttribute("GrassStored") or 0

	startingGrass =
		round1(startingGrass)

	if startingGrass <= 0 then
		return
	end

	sellingPlayers[player] = true
	sellCombos[player] = 0

	task.spawn(function()

		local soldSoFar = 0
		local outsideSince = nil

		for tick = 1, SELL_TICKS do

			-- ========================================
			-- HRAC EXISTUJE?
			-- ========================================

			if not player.Parent then
				break
			end

			-- ========================================
			-- SELL ZONE KONTROLA
			-- ========================================

			if isInsideSellZone(player) then

				-- Hrac je uvnitr.
				outsideSince = nil

			else

				-- Prvni zaznamenany okamzik mimo zonu.
				if not outsideSince then
					outsideSince = os.clock()
				end

				-- Kratky vypadek ignorujeme.
				if os.clock() - outsideSince
					>= LEAVE_GRACE_TIME then

					break
				end
			end

			-- ========================================
			-- AKTUALNI TRAVA
			-- ========================================

			local currentGrass =
				player:GetAttribute("GrassStored") or 0

			currentGrass =
				round1(currentGrass)

			if currentGrass <= 0 then
				break
			end

			-- ========================================
			-- KOLIK PRODAT V TOMTO TICKU
			-- ========================================

			local targetSold =
				startingGrass
				* tick
				/ SELL_TICKS

			targetSold =
				round1(targetSold)

			local amountThisTick =
				round1(
					targetSold - soldSoFar
				)

			if amountThisTick > 0 then

				local sold =
					sellAmount(
						player,
						amountThisTick
					)

				soldSoFar =
					round1(
						soldSoFar + sold
					)
			end

			task.wait(
				SELL_INTERVAL
			)
		end

		-- ========================================
		-- DOROVNANI POSLEDNIHO ZBYTKU
		-- ========================================

		-- Pokud hrac celou dobu zustal v SellZone,
		-- prodame i pripadny desetinný zbytek.
		if player.Parent
			and isInsideSellZone(player) then

			local remaining =
				player:GetAttribute("GrassStored") or 0

			remaining =
				round1(remaining)

			-- Dorovname jen pokud jsme opravdu dokoncili
			-- tento prodejni cyklus.
			if remaining > 0
				and soldSoFar
				>= startingGrass - 0.2 then

				sellAmount(
					player,
					remaining
				)
			end
		end

		sellingPlayers[player] = nil
		sellCombos[player] = nil
	end)
end

-- ========================================
-- HLAVNI SELL LOOP
-- ========================================

task.spawn(function()

	while true do

		for _, player in ipairs(
			Players:GetPlayers()
			) do

			if isInsideSellZone(player) then

				local grass =
					player:GetAttribute("GrassStored") or 0

				if grass > 0
					and not sellingPlayers[player] then

					local instant =
						player:GetAttribute(
							"Setting_InstantZoneSell"
						)

					if instant == true then

						instantZoneSell(player)

					else

						startSelling(player)
					end
				end
			end
		end

		task.wait(
			CHECK_INTERVAL
		)
	end
end)

-- ========================================
-- UKLID
-- ========================================

Players.PlayerRemoving:Connect(
	function(player)

		sellingPlayers[player] = nil
		sellCombos[player] = nil
	end
)
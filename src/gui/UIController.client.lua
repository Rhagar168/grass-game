local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent

-- ========================================
-- GUI REFERENCES
-- ========================================

local backpackHUD = gui:WaitForChild("BackpackHUD")
local barBackground = backpackHUD:WaitForChild("BarBackground")
local barFill = barBackground:WaitForChild("BarFill")
local amountText = barBackground:WaitForChild("AmountText")

local coinsHUD = gui:WaitForChild("CoinsHUD")
local coinsText = coinsHUD:WaitForChild("CoinsText")

local resetTokensHUD = gui:WaitForChild("ResetTokensHUD")
local resetTokensText = resetTokensHUD:WaitForChild("ResetTokensText")

local grassCoresHUD = gui:WaitForChild("GrassCoresHUD")
local grassCoresText = grassCoresHUD:WaitForChild("GrassCoresText")

local fullMessage = gui:WaitForChild("FullMessage")

-- ========================================
-- XP HUD
-- ========================================

local xpFrame = gui:FindFirstChild("XPFrame")

local levelText = nil
local xpBarBackground = nil
local xpBarFill = nil
local xpText = nil

if xpFrame then

	levelText =
		xpFrame:FindFirstChild("LevelText")

	xpBarBackground =
		xpFrame:FindFirstChild("XPBarBackground")

	if xpBarBackground then

		xpBarFill =
			xpBarBackground:FindFirstChild("XPBarFill")

		if xpBarFill then

			xpText =
				xpBarBackground:FindFirstChild("XPText")
		end
	end
end

-- ========================================
-- EVENTS
-- ========================================

local backpackFullEvent =
	ReplicatedStorage:WaitForChild("BackpackFull")

local grassGainEvent =
	ReplicatedStorage:WaitForChild("GrassGainPopup")

local instantSellPopupEvent =
	ReplicatedStorage:WaitForChild("InstantSellPopup")

local xpGainPopupEvent =
	ReplicatedStorage:WaitForChild("XPGainPopup")

-- ========================================
-- DATA
-- ========================================

local lastCoins = 0
local lastResetTokens = 0
local lastGrassCores = 0

local showingFullMessage = false

local grassPunchRunning = false
local coinPunchRunning = false
local tokenPunchRunning = false
local corePunchRunning = false

local backpackTween = nil
local xpTween = nil

local originalBarYScale = barFill.Size.Y.Scale
local originalBarYOffset = barFill.Size.Y.Offset

local rewardFlyLayer = Instance.new("Frame")
rewardFlyLayer.Name = "BossRewardFlyLayer"
rewardFlyLayer.BackgroundTransparency = 1
rewardFlyLayer.Size = UDim2.fromScale(1, 1)
rewardFlyLayer.ZIndex = 100
rewardFlyLayer.Parent = gui

local function hudCenter(hud)
	local p = hud.AbsolutePosition
	local s = hud.AbsoluteSize
	return Vector2.new(p.X + s.X * 0.5, p.Y + s.Y * 0.5)
end

local function flyReward(symbol, amount, targetHud)
	local camera = workspace.CurrentCamera
	if not camera then return end

	local start = camera.ViewportSize * Vector2.new(0.5, 0.48)
	local target = hudCenter(targetHud)
	local count = math.clamp(math.floor(amount), 1, 5)

	for i = 1, count do
		task.delay((i - 1) * 0.07, function()
			local icon = Instance.new("TextLabel")
			icon.BackgroundTransparency = 1
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromOffset(start.X + math.random(-45, 45), start.Y + math.random(-25, 25))
			icon.Size = UDim2.fromOffset(54, 54)
			icon.Font = Enum.Font.GothamBlack
			icon.Text = symbol
			icon.TextColor3 = Color3.new(1, 1, 1)
			icon.TextStrokeTransparency = 0.15
			icon.TextScaled = true
			icon.ZIndex = 101
			icon.Parent = rewardFlyLayer

			local pop = TweenService:Create(icon, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(icon.Position.X.Offset, icon.Position.Y.Offset - 55),
				Size = UDim2.fromOffset(66, 66),
			})
			pop:Play()
			pop.Completed:Wait()

			local fly = TweenService:Create(icon, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(target.X, target.Y),
				Size = UDim2.fromOffset(28, 28),
				TextTransparency = 0.15,
			})
			fly:Play()
			fly.Completed:Wait()
			icon:Destroy()
		end)
	end
end

bossRewardEvent.OnClientEvent:Connect(function(coreReward, tokenReward)
	grassCoresHUD.Visible = true
	flyReward("GC", coreReward or 1, grassCoresHUD)
	flyReward("RT", tokenReward or 1, resetTokensHUD)
end)


-- ========================================
-- FORMAT NUMBER
-- ========================================

local function formatNumber(value)

	value = tonumber(value) or 0

	local absValue = math.abs(value)

	if absValue >= 1e12 then
		return string.format("%.2fT", value / 1e12)

	elseif absValue >= 1e9 then
		return string.format("%.2fB", value / 1e9)

	elseif absValue >= 1e6 then
		return string.format("%.2fM", value / 1e6)

	elseif absValue >= 1e3 then
		return string.format("%.2fK", value / 1e3)
	end

	if value % 1 == 0 then
		return tostring(math.floor(value))
	end

	return string.format("%.1f", value)
end

-- ========================================
-- BACKPACK COLOR
-- ========================================

local function getBackpackColor(percent)

	percent = math.clamp(
		percent,
		0,
		1
	)

	if percent <= 0.5 then

		local alpha =
			percent / 0.5

		return Color3.fromRGB(
			math.floor(
				70 + (230 - 70) * alpha
			),

			math.floor(
				210 + (200 - 210) * alpha
			),

			math.floor(
				80 + (70 - 80) * alpha
			)
		)
	end

	local alpha =
		(percent - 0.5) / 0.5

	return Color3.fromRGB(
		230,

		math.floor(
			200 + (65 - 200) * alpha
		),

		math.floor(
			70 + (65 - 70) * alpha
		)
	)
end

-- ========================================
-- PUNCH
-- ========================================

local function punchGui(
	guiObject,
	extraX,
	extraY
)

	local originalSize =
		guiObject.Size

	local biggerSize =
		UDim2.new(
			originalSize.X.Scale,
			originalSize.X.Offset + extraX,

			originalSize.Y.Scale,
			originalSize.Y.Offset + extraY
		)

	local grow =
		TweenService:Create(
			guiObject,

			TweenInfo.new(
				0.08,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),

			{
				Size = biggerSize
			}
		)

	local shrink =
		TweenService:Create(
			guiObject,

			TweenInfo.new(
				0.12,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Size = originalSize
			}
		)

	grow:Play()
	grow.Completed:Wait()

	shrink:Play()
	shrink.Completed:Wait()
end

local function punchBackpack()

	if grassPunchRunning then
		return
	end

	grassPunchRunning = true

	punchGui(
		backpackHUD,
		12,
		5
	)

	grassPunchRunning = false
end

local function punchCoins()

	if coinPunchRunning then
		return
	end

	coinPunchRunning = true

	punchGui(
		coinsHUD,
		10,
		4
	)

	coinPunchRunning = false
end

local function punchGrassCores()

	if corePunchRunning then return end
	corePunchRunning = true
	punchGui(grassCoresHUD, 10, 4)
	corePunchRunning = false
end

local function punchResetTokens()

	if tokenPunchRunning then
		return
	end

	tokenPunchRunning = true

	punchGui(
		resetTokensHUD,
		10,
		4
	)

	tokenPunchRunning = false
end

-- ========================================
-- BACKPACK UPDATE
-- ========================================

local function updateBackpack()

	local stored =
		player:GetAttribute("GrassStored") or 0

	local capacity =
		player:GetAttribute("BackpackCapacity") or 20

	if capacity <= 0 then
		capacity = 20
	end

	local percent =
		math.clamp(
			stored / capacity,
			0,
			1
		)

	amountText.Text =
		formatNumber(stored)
		.. " / "
		.. formatNumber(capacity)

	if backpackTween then
		backpackTween:Cancel()
	end

	backpackTween =
		TweenService:Create(
			barFill,

			TweenInfo.new(
				0.22,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Size =
				UDim2.new(
					percent,
					0,

					originalBarYScale,
					originalBarYOffset
				),

				BackgroundColor3 =
				getBackpackColor(percent)
			}
		)

	backpackTween:Play()
end

-- ========================================
-- COINS UPDATE
-- ========================================

local function updateCoins()

	local coins =
		player:GetAttribute("Coins") or 0

	coinsText.Text =
		formatNumber(coins)

	if coins > lastCoins then
		task.spawn(
			punchCoins
		)
	end

	lastCoins = coins
end

-- ========================================
-- RESET TOKENS UPDATE
-- ========================================

local function updateResetTokens()

	local tokens =
		player:GetAttribute("ResetTokens") or 0

	resetTokensHUD.Visible =
		tokens > 0

	resetTokensText.Text =
		formatNumber(tokens)

	if tokens > lastResetTokens then
		task.spawn(
			punchResetTokens
		)
	end

	lastResetTokens = tokens
end

-- ========================================
-- GRASS CORES UPDATE
-- ========================================

local function updateGrassCores()
	local cores = player:GetAttribute("GrassCores") or 0
	grassCoresHUD.Visible = cores >= 1
	grassCoresText.Text = formatNumber(cores)
	if cores > lastGrassCores then
		task.spawn(punchGrassCores)
	end
	lastGrassCores = cores
end

-- ========================================
-- XP UPDATE
-- ========================================

local function updateXP()

	if not xpFrame then
		return
	end

	if not levelText then
		return
	end

	if not xpBarBackground then
		return
	end

	if not xpBarFill then
		return
	end

	if not xpText then
		return
	end

	local xp =
		player:GetAttribute("XP") or 0

	local level =
		player:GetAttribute("Level") or 1

	local xpToNext =
		player:GetAttribute("XPToNext") or 10

	if xpToNext <= 0 then
		xpToNext = 10
	end

	local percent =
		math.clamp(
			xp / xpToNext,
			0,
			1
		)

	levelText.Text =
		"Lv. " .. tostring(level)

	xpText.Text =
		formatNumber(xp)
		.. " / "
		.. formatNumber(xpToNext)
		.. " XP"

	if xpTween then
		xpTween:Cancel()
	end

	xpTween =
		TweenService:Create(
			xpBarFill,

			TweenInfo.new(
				0.35,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Size =
				UDim2.new(
					percent,
					0,
					1,
					0
				)
			}
		)

	xpTween:Play()
end

-- ========================================
-- GRASS GAIN POPUP
-- ========================================

local function showGrassGain(amount)

	local popup =
		Instance.new("TextLabel")

	popup.Name =
		"GrassGainPopup"

	popup.Parent =
		gui

	popup.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	popup.Position =
		UDim2.new(
			math.random(20, 80) / 100,
			0,

			math.random(25, 70) / 100,
			0
		)

	popup.Size =
		UDim2.fromOffset(
			90,
			45
		)

	popup.BackgroundTransparency = 1

	popup.Text =
		"+"
		.. formatNumber(amount)

	popup.Font =
		Enum.Font.GothamBlack

	popup.TextScaled = true

	popup.TextColor3 =
		Color3.fromRGB(
			95,
			220,
			80
		)

	popup.TextStrokeColor3 =
		Color3.fromRGB(
			30,
			75,
			25
		)

	popup.TextStrokeTransparency = 0.1
	popup.TextTransparency = 0
	popup.ZIndex = 20

	local grow =
		TweenService:Create(
			popup,

			TweenInfo.new(
				0.15,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),

			{
				Size =
				UDim2.fromOffset(
					115,
					58
				)
			}
		)

	grow:Play()

	task.wait(0.55)

	local backpackCenter =
		backpackHUD.AbsolutePosition
		+ backpackHUD.AbsoluteSize / 2

	local guiSize =
		gui.AbsoluteSize

	local target =
		UDim2.new(
			backpackCenter.X / guiSize.X,
			0,

			backpackCenter.Y / guiSize.Y,
			0
		)

	local fly =
		TweenService:Create(
			popup,

			TweenInfo.new(
				0.65,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			),

			{
				Position = target,

				Size =
				UDim2.fromOffset(
					45,
					23
				),

				TextTransparency = 0.25,
				TextStrokeTransparency = 1
			}
		)

	fly:Play()
	fly.Completed:Wait()

	task.spawn(
		punchBackpack
	)

	if popup.Parent then
		popup:Destroy()
	end
end

-- ========================================
-- INSTANT SELL POPUP
-- ========================================

local function showInstantSell(
	earnedCoins
)

	local popup =
		Instance.new("TextLabel")

	popup.Name =
		"InstantSellPopup"

	popup.Parent =
		gui

	popup.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	popup.Position =
		UDim2.new(
			math.random(35, 65) / 100,
			0,

			math.random(35, 60) / 100,
			0
		)

	popup.Size =
		UDim2.fromOffset(
			80,
			32
		)

	popup.BackgroundTransparency = 1

	popup.Text =
		"+"
		.. formatNumber(
			earnedCoins
		)

	popup.Font =
		Enum.Font.GothamBlack

	popup.TextScaled = true

	popup.TextColor3 =
		Color3.fromRGB(
			255,
			210,
			50
		)

	popup.TextStrokeColor3 =
		Color3.fromRGB(
			100,
			55,
			5
		)

	popup.TextStrokeTransparency = 0.1
	popup.TextTransparency = 0
	popup.ZIndex = 25

	local grow =
		TweenService:Create(
			popup,

			TweenInfo.new(
				0.16,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),

			{
				Size =
				UDim2.fromOffset(
					100,
					38
				)
			}
		)

	grow:Play()

	task.wait(0.5)

	local coinsCenter =
		coinsHUD.AbsolutePosition
		+ coinsHUD.AbsoluteSize / 2

	local guiSize =
		gui.AbsoluteSize

	local target =
		UDim2.new(
			coinsCenter.X / guiSize.X,
			0,

			coinsCenter.Y / guiSize.Y,
			0
		)

	local fly =
		TweenService:Create(
			popup,

			TweenInfo.new(
				0.55,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			),

			{
				Position = target,

				Size =
				UDim2.fromOffset(
					36,
					14
				),

				TextTransparency = 0.2,
				TextStrokeTransparency = 1
			}
		)

	fly:Play()
	fly.Completed:Wait()

	task.spawn(
		punchCoins
	)

	if popup.Parent then
		popup:Destroy()
	end
end

local function showXPGain(amount)

	local popup =
		Instance.new("TextLabel")

	popup.Name =
		"XPGainPopup"

	popup.Parent =
		gui

	popup.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	popup.Position =
		UDim2.new(
			math.random(35, 65) / 100,
			0,
			math.random(30, 55) / 100,
			0
		)

	popup.Size =
		UDim2.fromOffset(
			55,
			22
		)

	popup.BackgroundTransparency = 1

	popup.Text =
		"+"
		.. formatNumber(amount)
		.. " XP"

	popup.Font =
		Enum.Font.GothamBlack

	popup.TextScaled = true

	popup.TextColor3 =
		Color3.fromRGB(
			120,
			170,
			255
		)

	popup.TextStrokeColor3 =
		Color3.fromRGB(
			35,
			55,
			110
		)

	popup.TextStrokeTransparency = 0.1
	popup.TextTransparency = 0
	popup.ZIndex = 30

	local grow =
		TweenService:Create(
			popup,

			TweenInfo.new(
				0.14,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),

			{
				Size =
				UDim2.fromOffset(
					70,
					27
				)
			}
		)

	grow:Play()

	task.wait(0.45)

	local targetPosition =
		popup.Position
	- UDim2.new(
		0,
		0,
		0.08,
		0
	)

	local fade =
		TweenService:Create(
			popup,

			TweenInfo.new(
				0.45,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Position =
				targetPosition,

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

-- ========================================
-- BACKPACK FULL MESSAGE
-- ========================================

local function showBackpackFull()

	if showingFullMessage then
		return
	end

	showingFullMessage = true

	fullMessage.Visible = true

	fullMessage.Text =
		"Backpack Full Sell Your Grass To Keep Cutting!"

	fullMessage.Font =
		Enum.Font.GothamBlack

	fullMessage.TextColor3 =
		Color3.fromRGB(
			255,
			70,
			70
		)

	fullMessage.TextTransparency = 1
	fullMessage.TextStrokeTransparency = 1

	local fadeIn =
		TweenService:Create(
			fullMessage,

			TweenInfo.new(
				0.15,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				TextTransparency = 0,
				TextStrokeTransparency = 0.35
			}
		)

	fadeIn:Play()

	task.wait(1.5)

	local fadeOut =
		TweenService:Create(
			fullMessage,

			TweenInfo.new(
				0.4,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				TextTransparency = 1,
				TextStrokeTransparency = 1
			}
		)

	fadeOut:Play()
	fadeOut.Completed:Wait()

	fullMessage.Visible = false

	task.wait(0.4)

	showingFullMessage = false
end

-- ========================================
-- ATTRIBUTE EVENTS
-- ========================================

player:GetAttributeChangedSignal(
	"GrassStored"
):Connect(updateBackpack)

player:GetAttributeChangedSignal(
	"BackpackCapacity"
):Connect(updateBackpack)

player:GetAttributeChangedSignal(
	"Coins"
):Connect(updateCoins)

player:GetAttributeChangedSignal(
	"ResetTokens"
):Connect(updateResetTokens)

player:GetAttributeChangedSignal(
	"GrassCores"
):Connect(updateGrassCores)

player:GetAttributeChangedSignal(
	"XP"
):Connect(updateXP)

player:GetAttributeChangedSignal(
	"Level"
):Connect(updateXP)

player:GetAttributeChangedSignal(
	"XPToNext"
):Connect(updateXP)

-- ========================================
-- REMOTE EVENTS
-- ========================================

backpackFullEvent.OnClientEvent:Connect(
	function()

		task.spawn(
			showBackpackFull
		)
	end
)

grassGainEvent.OnClientEvent:Connect(
	function(amount)

		task.spawn(
			showGrassGain,
			amount
		)
	end
)

instantSellPopupEvent.OnClientEvent:Connect(
	function(
		earnedCoins
	)

		task.spawn(
			showInstantSell,
			earnedCoins
		)
	end
)

xpGainPopupEvent.OnClientEvent:Connect(
	function(amount)

		task.spawn(
			showXPGain,
			amount
		)
	end
)

-- ========================================
-- START
-- ========================================

updateBackpack()
updateCoins()
updateResetTokens()
updateGrassCores()
updateXP()
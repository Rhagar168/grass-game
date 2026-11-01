local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundService = game:GetService("SoundService")

-- Soft collection chime, throttled so rapid grass cuts do not become noisy.
local collectChime = Instance.new("Sound")
collectChime.Name = "HUDCollectChime"
collectChime.SoundId = "rbxassetid://107132538017055"
collectChime.Volume = 0.15
collectChime.PlaybackSpeed = 1
collectChime.Parent = SoundService

local lastCollectSound = 0
local function playCollectChime(pitch)
    local now = os.clock()
    if now - lastCollectSound < 0.12 then return end
    lastCollectSound = now
    -- Clone so simultaneous arrivals do not restart and silence each other.
    local chime = collectChime:Clone()
    chime.PlaybackSpeed = pitch or 1.1
    chime.Parent = SoundService
    chime:Play()
    chime.Ended:Once(function() chime:Destroy() end)
    task.delay(3, function()
        if chime.Parent then chime:Destroy() end
    end)
end

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
-- Smooth HUD counters; new updates continue from current displayed value.
local animatedValues = {}
local function animateNumber(key, label, value, suffix)
    value = tonumber(value) or 0
    local state = animatedValues[key]
    if not state then
        state = {number = Instance.new("NumberValue")}
        state.number.Value = value
        animatedValues[key] = state
        state.number.Changed:Connect(function(v)
            label.Text = formatNumber(math.floor(v + 0.5)) .. (state.suffix or "")
        end)
    end
    state.suffix = suffix or ""
    if state.tween then state.tween:Cancel() end
    if state.number.Value == value then
        label.Text = formatNumber(value) .. state.suffix
    else
        state.tween = TweenService:Create(state.number, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = value})
        state.tween:Play()
    end
end

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

	local capacity = player:GetAttribute("Gamepass_InfiniteBackpack") == true
		and math.huge
		or (player:GetAttribute("BackpackCapacity") or 20)

	if capacity <= 0 then
		capacity = 20
	end

	local percent =
		math.clamp(
			capacity == math.huge and 0 or stored / capacity,
			0,
			1
		)

	animateNumber("Backpack", amountText, stored, " / " .. (capacity == math.huge and "INF" or formatNumber(capacity)))

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

	animateNumber("Coins", coinsText, coins)

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

	animateNumber("ResetTokens", resetTokensText, tokens)

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
	grassCoresHUD.Visible = cores >= 1 or player:GetAttribute("HasEverOwnedGrassCore") == true
	animateNumber("GrassCores", grassCoresText, cores)
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

	animateNumber("XP", xpText, xp, " / " .. formatNumber(xpToNext) .. " XP")

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

	-- No chime for grass arriving in the backpack.
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

	playCollectChime(1.05)
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
			170,
			90,
			255
		)

	popup.TextStrokeColor3 =
		Color3.fromRGB(
			65,
			20,
			105
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
-- LEVEL UP CELEBRATION
-- ========================================

local lastLevel = tonumber(player:GetAttribute("Level")) or 1
local levelDataReady = player:GetAttribute("DataLoaded") == true

player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
    levelDataReady = player:GetAttribute("DataLoaded") == true
    lastLevel = tonumber(player:GetAttribute("Level")) or 1
end)
local levelUpSound = Instance.new("Sound")
levelUpSound.Name = "LevelUpSound"
levelUpSound.SoundId = "rbxassetid://99608180022223"
levelUpSound.Volume = 0.12
levelUpSound.PlaybackSpeed = 1.08
levelUpSound.Parent = SoundService

local function showLevelUp(level)
    local sound = levelUpSound:Clone()
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Once(function() sound:Destroy() end)
    task.delay(8, function()
        if sound.Parent then sound:Destroy() end
    end)
    local popup = Instance.new("TextLabel")
    popup.Name = "LevelUpPopup"
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.Position = UDim2.fromScale(0.5, 0.37)
    popup.Size = UDim2.fromOffset(180, 48)
    popup.BackgroundTransparency = 1
    popup.Font = Enum.Font.GothamBlack
    popup.Text = "LEVEL UP!  " .. tostring(level)
    popup.TextScaled = true
    popup.TextColor3 = Color3.fromRGB(255, 216, 75)
    popup.TextStrokeColor3 = Color3.fromRGB(95, 49, 8)
    popup.TextStrokeTransparency = 0.1
    popup.ZIndex = 110
    popup.Parent = gui

    local glow = xpFrame and xpFrame:FindFirstChild("LevelUpGlow")
    if xpFrame and not glow then
        glow = Instance.new("UIStroke")
        glow.Name = "LevelUpGlow"
        glow.Thickness = 3
        glow.Color = Color3.fromRGB(255, 210, 65)
        glow.Transparency = 1
        glow.Parent = xpFrame
    end
    if glow then
        glow.Transparency = 0
        TweenService:Create(glow, TweenInfo.new(0.85), {Transparency = 1}):Play()
    end

    TweenService:Create(popup, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(290, 76)
    }):Play()

    -- Small golden sparkles around the level-up text.
    for i = 1, 8 do
        local spark = Instance.new("TextLabel")
        spark.Name = "LevelUpSpark"
        spark.AnchorPoint = Vector2.new(0.5, 0.5)
        spark.BackgroundTransparency = 1
        spark.Text = "✦"
        spark.Font = Enum.Font.GothamBold
        spark.TextScaled = true
        spark.TextColor3 = Color3.fromRGB(255, 224, 95)
        spark.Size = UDim2.fromOffset(20, 20)
        spark.Position = UDim2.fromScale(0.5, 0.37)
        spark.ZIndex = 109
        spark.Parent = gui
        local angle = (i / 8) * math.pi * 2
        local target = UDim2.new(0.5, math.cos(angle) * 170, 0.37, math.sin(angle) * 90)
        TweenService:Create(spark, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = target,
            TextTransparency = 1
        }):Play()
        task.delay(0.9, function() if spark.Parent then spark:Destroy() end end)
    end

    task.delay(0.9, function()
        if not popup.Parent then return end
        local fade = TweenService:Create(popup, TweenInfo.new(0.4), {
            Position = UDim2.fromScale(0.5, 0.30),
            TextTransparency = 1,
            TextStrokeTransparency = 1
        })
        fade:Play()
        fade.Completed:Once(function() popup:Destroy() end)
    end)
end

local function onLevelChanged()
    local level = tonumber(player:GetAttribute("Level")) or 1
    if levelDataReady and level > lastLevel then
        task.spawn(showLevelUp, level)
    end
    lastLevel = level
    updateXP()
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

player:GetAttributeChangedSignal("Gamepass_InfiniteBackpack"):Connect(updateBackpack)

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
):Connect(onLevelChanged)

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

-- Coming Soon tools: enforce placeholders from the already-running MainUI controller.
-- The Tools menu may be managed by a Studio-only script that rewrites button labels.
task.spawn(function()
    local menu = gui:WaitForChild("ToolsMenu", 30)
    if not menu then return end
    local list = menu:WaitForChild("ToolList", 30)
    if not list then return end
    for _, toolId in ipairs({"GrassCutter", "PowerCutter"}) do
        local button = list:WaitForChild(toolId, 30)
        if button and button:IsA("GuiButton") then
            task.spawn(function()
                while button.Parent do
                    button.Text = "COMING SOON"
                    button.TextColor3 = Color3.fromRGB(145, 145, 145)
                    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                    button.Interactable = false
                    button.AutoButtonColor = false
                    task.wait(0.2)
                end
            end)
        end
    end
end)

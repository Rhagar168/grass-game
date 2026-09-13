local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local upgradeMenu = script.Parent
local tooltipEvent = upgradeMenu:WaitForChild("TooltipEvent")

local tooltip = upgradeMenu:WaitForChild("UpgradeTooltip")
local tooltipScale = tooltip:WaitForChild("TooltipScale")

local title = tooltip:WaitForChild("Title")
local description = tooltip:WaitForChild("Description")
local bonus = tooltip:WaitForChild("Bonus")

local priceContainer = tooltip:WaitForChild("PriceContainer")
local coinHolder = priceContainer:WaitForChild("CoinHolder")
local status = priceContainer:WaitForChild("Status")

local currentOwner = nil
local scaleTween = nil
local hideId = 0

local currentX = 0
local currentY = 0

local BONUS_NORMAL = Color3.fromRGB(255, 75, 75)
local BONUS_BOUGHT = Color3.fromRGB(90, 255, 120)

local STATUS_NORMAL = Color3.fromRGB(255, 255, 255)
local STATUS_BOUGHT = Color3.fromRGB(90, 255, 120)
local STATUS_LOCKED = Color3.fromRGB(160, 160, 160)

-- NASTAVENÍ ANIMACE

local OPEN_SCALE = 1
local CLOSED_SCALE = 0.72

local OPEN_TIME = 0.14
local CLOSE_TIME = 0.10

local function getMousePosition()
	local mouse = UserInputService:GetMouseLocation()

	return mouse.X + 34, mouse.Y + 22
end

local function setContent(data, state)
	title.Text = data.Title or ""
	description.Text = data.Description or ""
	bonus.Text = data.BonusText or ""

	if state == "Bought" then
		bonus.TextColor3 = BONUS_BOUGHT

		status.Text = "PURCHASED"
		status.TextColor3 = STATUS_BOUGHT

		coinHolder.Visible = false

	elseif state == "Locked" then
		bonus.TextColor3 = BONUS_NORMAL

		status.Text = "LOCKED"
		status.TextColor3 = STATUS_LOCKED

		coinHolder.Visible = false

	else
		bonus.TextColor3 = BONUS_NORMAL

		status.Text = tostring(data.Price)
		status.TextColor3 = STATUS_NORMAL

		coinHolder.Visible = true
	end
end

local function stopScaleTween()
	if scaleTween then
		scaleTween:Cancel()
		scaleTween = nil
	end
end

local function show(owner, data, state)
	hideId += 1

	currentOwner = owner

	stopScaleTween()

	setContent(data, state)

	local targetX, targetY = getMousePosition()

	currentX = targetX
	currentY = targetY

	tooltip.Position = UDim2.fromOffset(
		currentX,
		currentY
	)

	tooltip.Visible = true

	-- začátek zmenšený
	tooltipScale.Scale = CLOSED_SCALE

	scaleTween = TweenService:Create(
		tooltipScale,
		TweenInfo.new(
			OPEN_TIME,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Scale = OPEN_SCALE
		}
	)

	scaleTween:Play()
end

local function hide(owner)
	if currentOwner ~= owner then
		return
	end

	currentOwner = nil
	hideId += 1

	local thisHide = hideId

	stopScaleTween()

	scaleTween = TweenService:Create(
		tooltipScale,
		TweenInfo.new(
			CLOSE_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),
		{
			Scale = CLOSED_SCALE
		}
	)

	scaleTween:Play()

	scaleTween.Completed:Connect(function()
		if hideId ~= thisHide then
			return
		end

		if currentOwner ~= nil then
			return
		end

		tooltip.Visible = false
	end)
end

local function update(owner, data, state)
	if currentOwner ~= owner then
		return
	end

	setContent(data, state)
end

tooltipEvent.Event:Connect(function(
	action,
	owner,
	data,
	state
)
	if action == "Show" then
		show(
			owner,
			data,
			state
		)

	elseif action == "Hide" then
		hide(owner)

	elseif action == "Update" then
		update(
			owner,
			data,
			state
		)
	end
end)

-- PLYNULÉ SLEDOVÁNÍ MYŠI

RunService.RenderStepped:Connect(function(dt)
	if currentOwner == nil then
		return
	end

	local targetX, targetY = getMousePosition()

	local smooth =
		1 - math.exp(-20 * dt)

	currentX +=
		(targetX - currentX)
		* smooth

	currentY +=
		(targetY - currentY)
		* smooth

	tooltip.Position = UDim2.fromOffset(
		currentX,
		currentY
	)
end)

tooltip.Visible = false
tooltipScale.Scale = CLOSED_SCALE
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local gui = script.Parent

local bottomMenu = gui:WaitForChild("BottomMenu")
local openButton = bottomMenu:WaitForChild("UpgradesButton")
local xpFrame = gui:FindFirstChild("XPFrame")
local upgradeMenu = gui:WaitForChild("UpgradeMenu")
local menuScale = upgradeMenu:FindFirstChild("MenuScale")
if not menuScale then
	menuScale = Instance.new("UIScale")
	menuScale.Name = "MenuScale"
	menuScale.Scale = 1
	menuScale.Parent = upgradeMenu
end

local openTweenInfo = TweenInfo.new(
	0.25,
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out
)

local topBar = upgradeMenu:WaitForChild("TopBar")
local closeButton = upgradeMenu:FindFirstChild("CloseButton") or topBar:FindFirstChild("CloseButton")
if not closeButton then
	closeButton = upgradeMenu:WaitForChild("CloseButton", 2) or topBar:WaitForChild("CloseButton")
end

local coinsDisplay = topBar:WaitForChild("CoinsDisplay")
local coinsText = coinsDisplay:WaitForChild("CoinsText")

local skillTree = upgradeMenu:WaitForChild("SkillTree")
local treeCanvas = skillTree:WaitForChild("TreeCanvas")

-- Damage1 je teď začátek celého skill tree
local firstNode = treeCanvas:WaitForChild("Damage1")

local firstOpen = true

-- ========================================
-- FORMAT ČÍSEL
-- ========================================

local function formatNumber(value)

	value = tonumber(value) or 0
	local absValue = math.abs(value)

	if absValue >= 1e9 then
		return string.format("%.2fB", value / 1e9)

	elseif absValue >= 1e6 then
		return string.format("%.2fM", value / 1e6)

	elseif absValue >= 1e3 then
		return string.format("%.1fK", value / 1e3)
	end

	if value % 1 == 0 then
		return tostring(math.floor(value))
	end

	return string.format("%.2f", value)
end

-- ========================================
-- COINS
-- ========================================

local function updateCoins()

	local coins =
		player:GetAttribute("Coins") or 0

	coinsText.Text =
		formatNumber(coins)
end

-- ========================================
-- CAMERA ZOOM BLOCK
-- ========================================

local function blockCameraZoom()
	return Enum.ContextActionResult.Sink
end

local function enableCameraZoomBlock()

	ContextActionService:BindActionAtPriority(
		"BlockCameraZoom",
		blockCameraZoom,
		false,
		Enum.ContextActionPriority.High.Value + 100,
		Enum.UserInputType.MouseWheel
	)
end

local function disableCameraZoomBlock()

	ContextActionService:UnbindAction(
		"BlockCameraZoom"
	)
end

-- ========================================
-- CENTER TREE
-- ========================================

local function centerOnFirstNode()

	task.wait()

	local nodeCenter =
		firstNode.AbsolutePosition
		+ firstNode.AbsoluteSize / 2

	local treeCenter =
		skillTree.AbsolutePosition
		+ skillTree.AbsoluteSize / 2

	local offset =
		nodeCenter - treeCenter

	skillTree.CanvasPosition =
		skillTree.CanvasPosition
		+ offset
end

-- ========================================
-- OPEN MENU
-- ========================================

local function openMenu()

	upgradeMenu.Visible = true
	bottomMenu.Visible = false
	if xpFrame then xpFrame.Visible = false end

	player:SetAttribute(
		"UpgradeMenuOpen",
		true
	)

	enableCameraZoomBlock()

	if firstOpen then

		firstOpen = false

		task.wait(0.05)

		centerOnFirstNode()
	end
end

-- ========================================
-- CLOSE MENU
-- ========================================

local function closeMenu()

	upgradeMenu.Visible = false
	bottomMenu.Visible = true
	if xpFrame then xpFrame.Visible = true end

	player:SetAttribute(
		"UpgradeMenuOpen",
		false
	)

	disableCameraZoomBlock()
end

-- ========================================
-- BUTTONS
-- ========================================

openButton.MouseButton1Click:Connect(
	openMenu
)

closeButton.MouseButton1Click:Connect(
	closeMenu
)

-- ========================================
-- COINS CHANGE
-- ========================================

player:GetAttributeChangedSignal(
	"Coins"
):Connect(updateCoins)

-- ========================================
-- START
-- ========================================

updateCoins()

upgradeMenu.Visible = false
bottomMenu.Visible = true
if xpFrame then xpFrame.Visible = true end

player:SetAttribute(
	"UpgradeMenuOpen",
	false
)

disableCameraZoomBlock()
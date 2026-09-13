local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local treeCanvas = script.Parent

local purchaseEvent =
	ReplicatedStorage:WaitForChild("UpgradePurchase")

local UpgradeConfig = require(
	ReplicatedStorage:WaitForChild("UpgradeConfig")
)

local upgradeMenu =
	treeCanvas:FindFirstAncestor("UpgradeMenu")

local tooltipEvent =
	upgradeMenu:WaitForChild("TooltipEvent")

-- ========================================
-- COLORS
-- ========================================

local AVAILABLE_COLOR =
	Color3.fromRGB(175, 175, 175)

local AVAILABLE_PULSE_COLOR =
	Color3.fromRGB(205, 205, 205)

local AVAILABLE_HOVER_COLOR =
	Color3.fromRGB(220, 220, 220)

local LOCKED_COLOR =
	Color3.fromRGB(100, 100, 100)

local LOCKED_HOVER_COLOR =
	Color3.fromRGB(120, 120, 120)

local BOUGHT_COLOR =
	Color3.fromRGB(255, 255, 255)

local LOCKED_TEXT_COLOR =
	Color3.fromRGB(155, 155, 155)

local NORMAL_TEXT_COLOR =
	Color3.fromRGB(255, 255, 255)

-- ========================================
-- SCALE
-- ========================================

local NORMAL_SCALE = 1
local HOVER_SCALE = 1.03

local tweenInfo = TweenInfo.new(
	0.2,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out
)

-- ========================================
-- DATA
-- ========================================

local nodes = {}

-- ========================================
-- FORMAT NUMBER
-- ========================================

local function formatNumber(value)

	value = tonumber(value) or 0
	local absValue = math.abs(value)

	local shortened
	local suffix = ""

	if absValue >= 1e12 then
		shortened = value / 1e12
		suffix = "T"

	elseif absValue >= 1e9 then
		shortened = value / 1e9
		suffix = "B"

	elseif absValue >= 1e6 then
		shortened = value / 1e6
		suffix = "M"

	elseif absValue >= 1e3 then
		shortened = value / 1e3
		suffix = "K"

	else
		if value % 1 == 0 then
			return tostring(math.floor(value))
		end

		return string.format("%.1f", value)
	end

	if shortened % 1 == 0 then
		return tostring(math.floor(shortened)) .. suffix
	end

	return string.format("%.1f", shortened) .. suffix
end

-- ========================================
-- BOUGHT ATTRIBUTE
-- ========================================

local function getBoughtAttribute(upgradeName)

	return upgradeName .. "Bought"
end

-- ========================================
-- NODE STATE
-- ========================================

local function getNodeState(upgradeName)

	local data =
		UpgradeConfig[upgradeName]

	if not data then
		return "Hidden"
	end

	local bought =
		player:GetAttribute(
			getBoughtAttribute(
				upgradeName
			)
		) == true

	if bought then
		return "Bought"
	end

	-- node bez Requires je start node

	if not data.Requires then
		return "Available"
	end

	-- prerequisite koupen

	local requiredBought =
		player:GetAttribute(
			getBoughtAttribute(
				data.Requires
			)
		) == true

	if requiredBought then
		return "Available"
	end

	local requiredData =
		UpgradeConfig[
	data.Requires
	]

	if not requiredData then
		return "Hidden"
	end

	-- ========================================
	-- UKAZ JEDEN NODE DOPREDU
	-- ========================================

	if not requiredData.Requires then
		return "Locked"
	end

	local previousBought =
		player:GetAttribute(
			getBoughtAttribute(
				requiredData.Requires
			)
		) == true

	if previousBought then
		return "Locked"
	end

	return "Hidden"
end

-- ========================================
-- SETUP NODE
-- ========================================

local function setupNode(
	button,
	upgradeName
)

	local data =
		UpgradeConfig[
	upgradeName
	]

	if not data then

		warn(
			"Upgrade node nema config:",
			upgradeName
		)

		button.Visible = false

		return
	end

	-- ========================================
	-- GUI REFERENCES
	-- ========================================

	local icon =
		button:WaitForChild(
			"Icon"
		)

	local nameText =
		button:WaitForChild(
			"NameText"
		)

	local priceText =
		button:WaitForChild(
			"PriceText"
		)

	local coinIcon =
		button:WaitForChild(
			"CoinIcon"
		)

	local hoverScale =
		button:WaitForChild(
			"HoverScale"
		)

	local particleLayer =
		button:WaitForChild(
			"ParticleLayer"
		)

	local purchaseSound =
		button:WaitForChild(
			"PurchaseSound"
		)

	-- ========================================
	-- NODE DATA
	-- ========================================

	local node = {

		Button = button,
		Name = upgradeName,
		Data = data,

		Icon = icon,
		NameText = nameText,
		PriceText = priceText,
		CoinIcon = coinIcon,
		HoverScale = hoverScale,
		ParticleLayer = particleLayer,
		PurchaseSound = purchaseSound,

		State = "Hidden",

		Hovered = false,

		WasBought = false,

		Initialized = false,

		PulseRunning = false,

		PulseId = 0,
	}

	nodes[upgradeName] =
		node

	-- ========================================
	-- TEXT
	-- ========================================

	nameText.Text =
		data.Title
		or upgradeName

	priceText.Text =
		formatNumber(
			data.Price or 0
		)

	hoverScale.Scale = 1

	-- ========================================
	-- ICON COLOR TWEEN
	-- ========================================

	local function tweenIcon(color)

		TweenService:Create(
			icon,

			tweenInfo,

			{
				ImageColor3 = color
			}

		):Play()
	end

	-- ========================================
	-- SCALE TWEEN
	-- ========================================

	local function tweenScale(scale)

		TweenService:Create(
			hoverScale,

			tweenInfo,

			{
				Scale = scale
			}

		):Play()
	end

	-- ========================================
	-- STOP PULSE
	-- ========================================

	local function stopPulse()

		node.PulseId += 1

		node.PulseRunning =
			false
	end

	-- ========================================
	-- START PULSE
	-- ========================================

	local function startPulse()

		if node.PulseRunning then
			return
		end

		node.PulseRunning = true

		node.PulseId += 1

		local pulseId =
			node.PulseId

		task.spawn(function()

			while
				node.State == "Available"
				and node.PulseId == pulseId
			do

				if node.Hovered then

					task.wait(0.1)

					continue
				end

				local upTween =
					TweenService:Create(
						icon,

						TweenInfo.new(
							0.65,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.InOut
						),

						{
							ImageColor3 =
							AVAILABLE_PULSE_COLOR
						}
					)

				upTween:Play()

				upTween.Completed:Wait()

				if
					node.State ~= "Available"
					or node.PulseId ~= pulseId
				then

					break
				end

				local downTween =
					TweenService:Create(
						icon,

						TweenInfo.new(
							0.65,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.InOut
						),

						{
							ImageColor3 =
							AVAILABLE_COLOR
						}
					)

				downTween:Play()

				downTween.Completed:Wait()
			end

			node.PulseRunning = false
		end)
	end

	-- ========================================
	-- PURCHASE EFFECT
	-- ========================================

	local function playPurchaseEffect()

		purchaseSound:Play()

		local growTween =
			TweenService:Create(
				hoverScale,

				TweenInfo.new(
					0.12,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),

				{
					Scale = 1.12
				}
			)

		growTween:Play()

		growTween.Completed:Wait()

		local shrinkTween =
			TweenService:Create(
				hoverScale,

				TweenInfo.new(
					0.08,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.Out
				),

				{
					Scale = 0.97
				}
			)

		shrinkTween:Play()

		shrinkTween.Completed:Wait()

		TweenService:Create(
			hoverScale,

			TweenInfo.new(
				0.15,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),

			{
				Scale =
					node.Hovered
					and HOVER_SCALE
					or NORMAL_SCALE
			}

		):Play()

		-- ========================================
		-- PARTICLES
		-- ========================================

		local iconCenter =
			icon.AbsolutePosition
			+ icon.AbsoluteSize / 2

		local layerPosition =
			particleLayer.AbsolutePosition

		local center =
			iconCenter
		- layerPosition

		for i = 1, 10 do

			local particle =
				Instance.new(
					"Frame"
				)

			particle.AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				)

			particle.Position =
				UDim2.fromOffset(
					center.X,
					center.Y
				)

			local size =
				math.random(
					6,
					10
				)

			particle.Size =
				UDim2.fromOffset(
					size,
					size
				)

			particle.BackgroundColor3 =
				Color3.fromRGB(
					255,
					255,
					255
				)

			particle.BorderSizePixel =
				0

			particle.ZIndex =
				30

			local corner =
				Instance.new(
					"UICorner"
				)

			corner.CornerRadius =
				UDim.new(
					1,
					0
				)

			corner.Parent =
				particle

			particle.Parent =
				particleLayer

			local angle =
				math.rad(
					math.random(
						0,
						359
					)
				)

			local distance =
				math.random(
					45,
					80
				)

			local x =
				math.cos(angle)
				* distance

			local y =
				math.sin(angle)
				* distance

			local particleTween =
				TweenService:Create(
					particle,

					TweenInfo.new(
						0.9,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.Out
					),

					{
						Position =
						UDim2.fromOffset(
							center.X + x,
							center.Y + y
						),

						BackgroundTransparency =
						1,

						Size =
						UDim2.fromOffset(
							4,
							4
						)
					}
				)

			particleTween:Play()

			particleTween.Completed:Connect(
				function()

					if particle then
						particle:Destroy()
					end
				end
			)
		end
	end

	node.StopPulse =
		stopPulse

	node.StartPulse =
		startPulse

	node.TweenIcon =
		tweenIcon

	node.PlayPurchaseEffect =
		playPurchaseEffect

	-- ========================================
	-- HOVER ENTER
	-- ========================================

	button.MouseEnter:Connect(
		function()

			if node.State == "Hidden" then
				return
			end

			node.Hovered = true

			tweenScale(
				HOVER_SCALE
			)

			if node.State == "Locked" then

				tweenIcon(
					LOCKED_HOVER_COLOR
				)

			elseif node.State == "Available" then

				tweenIcon(
					AVAILABLE_HOVER_COLOR
				)

			elseif node.State == "Bought" then

				tweenIcon(
					BOUGHT_COLOR
				)
			end

			tooltipEvent:Fire(
				"Show",
				button,
				data,
				node.State
			)
		end
	)

	-- ========================================
	-- HOVER LEAVE
	-- ========================================

	button.MouseLeave:Connect(
		function()

			node.Hovered = false

			tweenScale(
				NORMAL_SCALE
			)

			if node.State == "Locked" then

				tweenIcon(
					LOCKED_COLOR
				)

			elseif node.State == "Available" then

				tweenIcon(
					AVAILABLE_COLOR
				)

			elseif node.State == "Bought" then

				tweenIcon(
					BOUGHT_COLOR
				)
			end

			tooltipEvent:Fire(
				"Hide",
				button
			)
		end
	)

	-- ========================================
	-- CLICK
	-- ========================================

	button.MouseButton1Click:Connect(
		function()

			if node.State ~= "Available" then
				return
			end

			purchaseEvent:FireServer(
				upgradeName
			)
		end
	)
end

-- ========================================
-- UPDATE NODE
-- ========================================

local function updateNode(node)

	local state =
		getNodeState(
			node.Name
		)

	node.State =
		state

	-- ========================================
	-- HIDDEN
	-- ========================================

	if state == "Hidden" then

		node.Button.Visible = false

		node.StopPulse()

		if node.Hovered then

			node.Hovered = false

			tooltipEvent:Fire(
				"Hide",
				node.Button
			)
		end

		return
	end

	node.Button.Visible = true

	local coins =
		player:GetAttribute(
			"Coins"
		) or 0

	local bought =
		player:GetAttribute(
			getBoughtAttribute(
				node.Name
			)
		) == true

	-- ========================================
	-- LOCKED
	-- ========================================

	if state == "Locked" then

		node.StopPulse()

		node.Icon.ImageColor3 =
			LOCKED_COLOR

		node.NameText.TextColor3 =
			LOCKED_TEXT_COLOR

		node.PriceText.Visible =
			false

		node.CoinIcon.Visible =
			false

		-- ========================================
		-- AVAILABLE
		-- ========================================

	elseif state == "Available" then

		node.Icon.ImageColor3 =
			AVAILABLE_COLOR

		node.NameText.TextColor3 =
			NORMAL_TEXT_COLOR

		node.PriceText.Visible =
			true

		node.CoinIcon.Visible =
			true

		node.PriceText.Text =
			formatNumber(
				node.Data.Price or 0
			)

		if coins >=
			(node.Data.Price or 0)
		then

			node.PriceText.TextColor3 =
				Color3.fromRGB(
					255,
					255,
					255
				)

		else

			node.PriceText.TextColor3 =
				Color3.fromRGB(
					255,
					70,
					70
				)
		end

		node.StartPulse()

		-- ========================================
		-- BOUGHT
		-- ========================================

	elseif state == "Bought" then

		node.StopPulse()

		node.Icon.ImageColor3 =
			BOUGHT_COLOR

		node.NameText.TextColor3 =
			NORMAL_TEXT_COLOR

		node.PriceText.Visible =
			false

		node.CoinIcon.Visible =
			false
	end

	-- ========================================
	-- TOOLTIP UPDATE
	-- ========================================

	if node.Hovered then

		tooltipEvent:Fire(
			"Update",
			node.Button,
			node.Data,
			state
		)
	end

	-- ========================================
	-- PURCHASE EFFECT
	-- ========================================

	if
		node.Initialized
		and bought
		and not node.WasBought
	then

		task.spawn(
			node.PlayPurchaseEffect
		)
	end

	node.WasBought =
		bought

	node.Initialized =
		true
end

-- ========================================
-- UPDATE ALL
-- ========================================

local function updateAll()

	for _, node in pairs(
		nodes
		) do

		updateNode(
			node
		)
	end
end

-- ========================================
-- FIND EXISTING NODES
-- ========================================

for _, child in ipairs(
	treeCanvas:GetChildren()
	) do

	if
		child:IsA("ImageButton")
		and UpgradeConfig[
		child.Name
		]
	then

		setupNode(
			child,
			child.Name
		)
	end
end

-- ========================================
-- DYNAMIC NODES
-- ========================================

treeCanvas.ChildAdded:Connect(
	function(child)

		task.wait()

		if
			child:IsA("ImageButton")
			and UpgradeConfig[
			child.Name
			]
				and not nodes[
			child.Name
			]
		then

			setupNode(
				child,
				child.Name
			)

			updateAll()
		end
	end
)

-- ========================================
-- COINS CHANGED
-- ========================================

player:GetAttributeChangedSignal(
	"Coins"
):Connect(
	updateAll
)

-- ========================================
-- BOUGHT ATTRIBUTES
-- ========================================

for upgradeName in pairs(
	UpgradeConfig
	) do

	player:GetAttributeChangedSignal(
		getBoughtAttribute(
			upgradeName
		)
	):Connect(
		updateAll
	)
end

-- ========================================
-- FIRST UPDATE
-- ========================================

updateAll()
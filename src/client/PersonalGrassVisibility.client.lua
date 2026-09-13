local Players =
	game:GetService("Players")

local CollectionService =
	game:GetService("CollectionService")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local TweenService =
	game:GetService("TweenService")

local damagePopupEvent =
	ReplicatedStorage:WaitForChild("DamagePopup")

local player =
	Players.LocalPlayer

-- ========================================
-- NASTAVI VIDITELNOST JEDNE TRAVY
-- ========================================

local function updateGrassVisibility(grass)

	if not grass:IsA("BasePart") then
		return
	end

	local ownerUserId =
		grass:GetAttribute(
			"OwnerUserId"
		)

	-- pokud nema ownera,
	-- nechame ji normalne viditelnou

	if ownerUserId == nil then
		grass.LocalTransparencyModifier = 0
		return
	end

	-- moje trava

	if ownerUserId == player.UserId then

		grass.LocalTransparencyModifier = 0

	else

		-- cizi trava

		grass.LocalTransparencyModifier = 1
	end
end

-- ========================================
-- EXISTUJICI TRAVA
-- ========================================

for _, grass in ipairs(
	CollectionService:GetTagged("Cuttable")
	) do

	updateGrassVisibility(
		grass
	)
end

-- ========================================
-- NOVE SPAWNUTA TRAVA
-- ========================================

CollectionService:GetInstanceAddedSignal(
	"Cuttable"
):Connect(
	function(grass)

		task.defer(
			function()

				updateGrassVisibility(
					grass
				)
			end
		)
	end
)

-- ========================================
-- KDYBY SE OWNER ZMENIL
-- ========================================

CollectionService:GetInstanceAddedSignal(
	"Cuttable"
):Connect(
	function(grass)

		if not grass:IsA("BasePart") then
			return
		end

		grass:GetAttributeChangedSignal(
			"OwnerUserId"
		):Connect(
			function()

				updateGrassVisibility(
					grass
				)
			end
		)
	end
)

-- ========================================
-- DAMAGE POPUP
-- ========================================

local function showDamageNumber(
	plant,
	damage,
	isCrit
)

	if not plant
		or not plant.Parent then
		return
	end

	-- extra kontrola:
	-- popup ukazujeme jen na moji travu

	if plant:GetAttribute("OwnerUserId")
		~= player.UserId then

		return
	end

	local holder =
		Instance.new("Part")

	holder.Name =
		"DamagePopupHolder"

	holder.Size =
		Vector3.new(
			0.1,
			0.1,
			0.1
		)

	holder.Position =
		plant.Position
		+ Vector3.new(
			math.random(-4, 4) / 10,
			plant.Size.Y / 2 + 0.5,
			math.random(-4, 4) / 10
		)

	holder.Anchored = true
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false
	holder.Transparency = 1

	holder.Parent = workspace

	local billboard =
		Instance.new("BillboardGui")

	billboard.Size =
		UDim2.fromOffset(
			isCrit and 105 or 75,
			isCrit and 52 or 38
		)

	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 60

	billboard.Parent =
		holder

	local text =
		Instance.new("TextLabel")

	text.Size =
		UDim2.fromScale(1, 1)

	text.BackgroundTransparency = 1

	if isCrit then

		text.Text =
			"CRIT! -"
			.. string.format(
				"%.1f",
				damage
			)

		text.TextColor3 =
			Color3.fromRGB(
				200,
				95,
				255
			)

		text.TextStrokeColor3 =
			Color3.fromRGB(
				70,
				20,
				110
			)

	else

		text.Text =
			"-"
			.. string.format(
				"%.1f",
				damage
			)

		text.TextColor3 =
			Color3.fromRGB(
				255,
				90,
				55
			)

		text.TextStrokeColor3 =
			Color3.fromRGB(
				90,
				20,
				10
			)
	end

	text.Font =
		Enum.Font.GothamBlack

	text.TextScaled = true
	text.TextStrokeTransparency = 0.1

	text.Parent =
		billboard

	-- vyskok

	local jumpTween =
		TweenService:Create(
			holder,

			TweenInfo.new(
				0.18,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),

			{
				Position =
				holder.Position
				+ Vector3.new(
					0,
					isCrit and 2 or 1.5,
					0
				)
			}
		)

	jumpTween:Play()
	jumpTween.Completed:Wait()

	-- zmizeni

	local fade =
		TweenService:Create(
			text,

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

	fade:Play()
	fade.Completed:Wait()

	if holder.Parent then
		holder:Destroy()
	end
end

damagePopupEvent.OnClientEvent:Connect(
	function(
		plant,
		damage,
		isCrit
	)

		task.spawn(
			showDamageNumber,
			plant,
			damage,
			isCrit
		)
	end
)
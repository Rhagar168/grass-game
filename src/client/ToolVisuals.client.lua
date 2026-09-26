local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local toolModels = ReplicatedStorage:WaitForChild("ToolModels")

local VISUAL_NAME = "EquippedToolVisual"

-- Per-tool offsets can be tuned later without changing the equip system.
local TOOL_OFFSETS = {
	Pliers = CFrame.new(0, -1.6, -1.5) * CFrame.Angles(math.rad(-15), math.rad(90), math.rad(-90)),
}

local PLIERS_OPEN_ANGLE = math.rad(35)
local PLIERS_CLOSE_TIME = 0.10
local PLIERS_OPEN_TIME = 0.14

local activePliersModel
local pliersBusy = false

local function clearVisual(character)
	local old = character:FindFirstChild(VISUAL_NAME)
	if old then
		old:Destroy()
	end
end

local function prepareModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
end

local function getHand(character)
	return character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm")
end

local originalTextureTransparency = setmetatable({}, { __mode = "k" })

local function setLegacyShearsVisible(character, visible)
	local legacyTool = character:FindFirstChild("BasicShears")
	if not legacyTool then
		return
	end

	for _, descendant in ipairs(legacyTool:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = visible and 0 or 1
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			if originalTextureTransparency[descendant] == nil then
				originalTextureTransparency[descendant] = descendant.Transparency
			end
			descendant.Transparency = visible
				and originalTextureTransparency[descendant]
				or 1
		end
	end
end

local function animatePliers()
	local model = activePliersModel
	if pliersBusy or not model or not model.Parent then
		return
	end

	local middle = model:FindFirstChild("Middle")
	local leftMotor = middle and middle:FindFirstChild("LeftMotor")
	local rightMotor = middle and middle:FindFirstChild("RightMotor")
	if not leftMotor or not rightMotor then
		return
	end

	pliersBusy = true

	local closeInfo = TweenInfo.new(PLIERS_CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local openInfo = TweenInfo.new(PLIERS_OPEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local leftClose = TweenService:Create(leftMotor, closeInfo, {
		Transform = CFrame.Angles(-PLIERS_OPEN_ANGLE, 0, 0),
	})
	local rightClose = TweenService:Create(rightMotor, closeInfo, {
		Transform = CFrame.Angles(PLIERS_OPEN_ANGLE, 0, 0),
	})

	leftClose:Play()
	rightClose:Play()
	leftClose.Completed:Wait()

	local leftOpen = TweenService:Create(leftMotor, openInfo, { Transform = CFrame.new() })
	local rightOpen = TweenService:Create(rightMotor, openInfo, { Transform = CFrame.new() })

	leftOpen:Play()
	rightOpen:Play()
	leftOpen.Completed:Wait()

	pliersBusy = false
end

local function equipVisual()
	local character = player.Character
	if not character then
		return
	end

	clearVisual(character)
	activePliersModel = nil
	pliersBusy = false

	-- BasicShears stays functional. Its original model remains visible
	-- for BasicScissors (and any tool without a replacement 3D model).
	local toolId = player:GetAttribute("EquippedTool")
	if typeof(toolId) ~= "string" then
		setLegacyShearsVisible(character, true)
		return
	end

	local template = toolModels:FindFirstChild(toolId)
	if not template or not template:IsA("Model") then
		setLegacyShearsVisible(character, true)
		-- Only tools with a 3D model are shown. This lets us add the five
		-- models one at a time without breaking the existing tool system.
		return
	end

	local hand = getHand(character)
	if not hand or not hand:IsA("BasePart") then
		setLegacyShearsVisible(character, true)
		return
	end

	local model = template:Clone()
	model.Name = VISUAL_NAME

	local root = model.PrimaryPart
		or model:FindFirstChild("Middle")
		or model:FindFirstChildWhichIsA("BasePart")

	if not root or not root:IsA("BasePart") then
		model:Destroy()
		warn("[ToolVisuals] No root BasePart for:", toolId)
		setLegacyShearsVisible(character, true)
		return
	end

	model.PrimaryPart = root
	setLegacyShearsVisible(character, false)
	prepareModel(model)
	model.Parent = character

	if toolId == "Pliers" then
		activePliersModel = model
	end

	-- Put the model at the hand first, then attach its root to the hand.
	-- The offset table above is the only value we need to tune for orientation.
	local offset = TOOL_OFFSETS[toolId] or CFrame.new()
	model:PivotTo(hand.CFrame * offset)

	local grip = Instance.new("Motor6D")
	grip.Name = "ToolGrip"
	grip.Part0 = hand
	grip.Part1 = root
	grip.C0 = offset
	grip.C1 = CFrame.new()
	grip.Parent = hand
end

local function onCharacterAdded(character)
	character:WaitForChild("Humanoid")

	-- StarterPack equips BasicShears shortly after the character spawns.
	-- Refresh visibility when the legacy Tool enters the character.
	character.ChildAdded:Connect(function(child)
		if child.Name == "BasicShears" then
			task.defer(function()
				equipVisual()
			end)
		end
	end)

	task.defer(equipVisual)
end

player:GetAttributeChangedSignal("EquippedTool"):Connect(equipVisual)
player.CharacterAdded:Connect(onCharacterAdded)

-- Animate from the player's actual cut input. The legacy BasicShears is
-- auto-equipped before this script can always observe Tool.Activated.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or player:GetAttribute("EquippedTool") ~= "Pliers" then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonR2 then
		task.spawn(animatePliers)
	end
end)

if player.Character then
	task.defer(equipVisual)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local toolModels = ReplicatedStorage:WaitForChild("ToolModels")

local VISUAL_NAME = "EquippedToolVisual"

-- Per-tool offsets can be tuned later without changing the equip system.
local TOOL_OFFSETS = {
	Pliers = CFrame.new(0, -1.6, -1.5) * CFrame.Angles(math.rad(-15), math.rad(90), math.rad(-90)),
}

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
	local rightMotor = middle and middle:FindFirstChild("ShearMotor")
	local leftMotor = middle and middle:FindFirstChild("LeftShearMotor")
	if not rightMotor or not leftMotor then
		return
	end

	pliersBusy = true

	local rightStartC0 = rightMotor.C0
	local leftStartC0 = leftMotor.C0
	local angle = math.rad(8)

	local closeTime = 0.08
	local openTime = 0.10

	local closeInfo = TweenInfo.new(closeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local openInfo = TweenInfo.new(openTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local rightClose = TweenService:Create(rightMotor, closeInfo, {
		C0 = rightStartC0 * CFrame.Angles(0, 0, angle),
	})
	local leftClose = TweenService:Create(leftMotor, closeInfo, {
		C0 = leftStartC0 * CFrame.Angles(0, 0, -angle),
	})

	rightClose:Play()
	leftClose:Play()
	rightClose.Completed:Wait()

	local rightOpen = TweenService:Create(rightMotor, openInfo, { C0 = rightStartC0 })
	local leftOpen = TweenService:Create(leftMotor, openInfo, { C0 = leftStartC0 })

	rightOpen:Play()
	leftOpen:Play()
	rightOpen.Completed:Wait()

	rightMotor.C0 = rightStartC0
	leftMotor.C0 = leftStartC0
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

local connectedTools = setmetatable({}, { __mode = "k" })

local function connectCutAnimation(tool)
	if not tool:IsA("Tool") or tool.Name ~= "BasicShears" or connectedTools[tool] then
		return
	end

	connectedTools[tool] = true

	local holding = false

	tool.Activated:Connect(function()
		if holding then
			return
		end

		holding = true

		task.spawn(function()
			while holding and tool.Parent == player.Character do
				if player:GetAttribute("EquippedTool") ~= "Pliers" then
					break
				end

				animatePliers()

				-- Match the real cutting cooldown instead of Tool.Activated,
				-- which only fires once while the mouse button is held.
				local cooldown = player:GetAttribute("CutCooldown") or 1
				local animationTime = 0.18
				task.wait(math.max(0, cooldown - animationTime))
			end

			holding = false
		end)
	end)

	tool.Deactivated:Connect(function()
		holding = false
	end)

	tool.Unequipped:Connect(function()
		holding = false
	end)
end

local backpack = player:WaitForChild("Backpack")
for _, child in ipairs(backpack:GetChildren()) do
	connectCutAnimation(child)
end
backpack.ChildAdded:Connect(connectCutAnimation)

local function watchCharacterTools(character)
	for _, child in ipairs(character:GetChildren()) do
		connectCutAnimation(child)
	end
	character.ChildAdded:Connect(connectCutAnimation)
end

if player.Character then
	watchCharacterTools(player.Character)
end
player.CharacterAdded:Connect(watchCharacterTools)

if player.Character then
	task.defer(equipVisual)
end

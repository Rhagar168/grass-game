local UserInputService = game:GetService("UserInputService")

local skillTree = script.Parent
local treeCanvas = skillTree:WaitForChild("TreeCanvas")
local treeScale = treeCanvas:WaitForChild("TreeScale")

local BASE_WIDTH = 4000
local BASE_HEIGHT = 4000

local MIN_ZOOM = 0.6
local MAX_ZOOM = 1.5
local ZOOM_STEP = 0.1

local dragging = false
local dragStart
local startCanvasPosition

local function updateCanvasSize()
	local scale = treeScale.Scale

	skillTree.CanvasSize = UDim2.fromOffset(
		BASE_WIDTH * scale,
		BASE_HEIGHT * scale
	)
end

local function clampCanvas()
	local maxX = math.max(
		0,
		skillTree.AbsoluteCanvasSize.X
		- skillTree.AbsoluteWindowSize.X
	)

	local maxY = math.max(
		0,
		skillTree.AbsoluteCanvasSize.Y
		- skillTree.AbsoluteWindowSize.Y
	)

	skillTree.CanvasPosition = Vector2.new(
		math.clamp(skillTree.CanvasPosition.X, 0, maxX),
		math.clamp(skillTree.CanvasPosition.Y, 0, maxY)
	)
end

local function zoom(direction)
	local oldScale = treeScale.Scale

	local newScale = math.clamp(
		oldScale + direction * ZOOM_STEP,
		MIN_ZOOM,
		MAX_ZOOM
	)

	if newScale == oldScale then
		return
	end

	local mousePosition =
		UserInputService:GetMouseLocation()

	local relativeMouse =
		mousePosition - skillTree.AbsolutePosition

	local contentPoint =
		(skillTree.CanvasPosition + relativeMouse)
		/ oldScale

	treeScale.Scale = newScale

	updateCanvasSize()

	skillTree.CanvasPosition =
		contentPoint * newScale - relativeMouse

	clampCanvas()
end

skillTree.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startCanvasPosition = skillTree.CanvasPosition
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		and dragging then

		local delta = input.Position - dragStart

		skillTree.CanvasPosition = Vector2.new(
			startCanvasPosition.X - delta.X,
			startCanvasPosition.Y - delta.Y
		)

		clampCanvas()
	end

	if input.UserInputType == Enum.UserInputType.MouseWheel then
		if not skillTree.Visible then
			return
		end

		if input.Position.Z > 0 then
			zoom(1)
		else
			zoom(-1)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

updateCanvasSize()
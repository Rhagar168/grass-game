local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local MilestoneConfig = require(ReplicatedStorage:WaitForChild("MilestoneConfig"))

local boards = workspace:WaitForChild("Boards")
local plainsFolder = boards:WaitForChild("Plains")
local board = plainsFolder:WaitForChild("PlainsMilestones")
local surfaceGui = board:FindFirstChildWhichIsA("SurfaceGui", true)

if not surfaceGui then
	warn("PlainsMilestones: SurfaceGui not found")
	return
end

local displayPart = board:FindFirstChild("Cube")
if not displayPart or not displayPart:IsA("BasePart") then
	warn("PlainsMilestones: Cube display part not found")
	return
end

surfaceGui.Adornee = displayPart
surfaceGui.Face = Enum.NormalId.Front
surfaceGui.Enabled = true

for _, child in ipairs(surfaceGui:GetChildren()) do
	if child.Name == "MilestoneUI" then
		child:Destroy()
	end
end

local root = Instance.new("Frame")
root.Name = "MilestoneUI"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = surfaceGui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -24, 0, 58)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "PLAINS MILESTONES"
title.TextColor3 = Color3.fromRGB(240, 244, 250)
title.TextScaled = true
title.Parent = root

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -24, 0, 28)
subtitle.Position = UDim2.fromOffset(12, 62)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.TextColor3 = Color3.fromRGB(160, 170, 185)
subtitle.TextScaled = true
subtitle.Parent = root

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "MilestoneScroll"
scroll.Size = UDim2.new(1, -28, 1, -108)
scroll.Position = UDim2.fromOffset(14, 98)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 135, 155)
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.Parent = root

local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 3)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local cards = {}
local milestones = MilestoneConfig.Biomes.Plains

for index, milestone in ipairs(milestones) do
	local card = Instance.new("Frame")
	card.Name = "Reset" .. index
	card.LayoutOrder = index
	card.Size = UDim2.new(1, -11, 0, 92)
	card.BorderSizePixel = 0
	card.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Thickness = 2
	stroke.Parent = card

	local resetLabel = Instance.new("TextLabel")
	resetLabel.Size = UDim2.new(0.3, 0, 0, 28)
	resetLabel.Position = UDim2.fromOffset(14, 10)
	resetLabel.BackgroundTransparency = 1
	resetLabel.Font = Enum.Font.GothamBlack
	resetLabel.Text = "RESET " .. index
	resetLabel.TextColor3 = Color3.fromRGB(235, 240, 248)
	resetLabel.TextScaled = true
	resetLabel.TextXAlignment = Enum.TextXAlignment.Left
	resetLabel.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.62, -18, 0, 26)
	nameLabel.Position = UDim2.new(0.32, 0, 0, 11)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = milestone.Title
	nameLabel.TextColor3 = Color3.fromRGB(185, 195, 210)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local bonus = Instance.new("TextLabel")
	bonus.Size = UDim2.new(1, -70, 0, 34)
	bonus.Position = UDim2.fromOffset(14, 47)
	bonus.BackgroundTransparency = 1
	bonus.Font = Enum.Font.GothamBlack
	bonus.Text = milestone.BonusText
	bonus.TextColor3 = Color3.fromRGB(130, 220, 105)
	bonus.TextScaled = true
	bonus.TextXAlignment = Enum.TextXAlignment.Left
	bonus.Parent = card

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.fromOffset(46, 46)
	status.AnchorPoint = Vector2.new(1, 0.5)
	status.Position = UDim2.new(1, -12, 0.5, 0)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamBlack
	status.TextScaled = true
	status.Parent = card

	cards[index] = card
end

local function update()
	local resetCount = math.clamp(player:GetAttribute("PlainsResetCount") or 0, 0, #milestones)
	subtitle.Text = string.format("%d / %d RESETS", resetCount, #milestones)

	for index, card in ipairs(cards) do
		local status = card.Status
		local stroke = card.Stroke

		if index <= resetCount then
			card.BackgroundColor3 = Color3.fromRGB(42, 70, 48)
			stroke.Color = Color3.fromRGB(105, 205, 95)
			status.Text = "✓"
			status.TextColor3 = Color3.fromRGB(115, 235, 105)
		elseif index == resetCount + 1 then
			card.BackgroundColor3 = Color3.fromRGB(48, 51, 59)
			stroke.Color = Color3.fromRGB(205, 185, 85)
			status.Text = "!"
			status.TextColor3 = Color3.fromRGB(235, 215, 100)
		else
			card.BackgroundColor3 = Color3.fromRGB(32, 35, 42)
			stroke.Color = Color3.fromRGB(70, 76, 88)
			status.Text = "🔒"
			status.TextColor3 = Color3.fromRGB(125, 132, 145)
		end
	end
end

player:GetAttributeChangedSignal("PlainsResetCount"):Connect(update)
update()

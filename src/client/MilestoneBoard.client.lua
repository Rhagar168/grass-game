local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local MilestoneConfig = require(ReplicatedStorage:WaitForChild("MilestoneConfig"))

local board = workspace:WaitForChild("Boards"):WaitForChild("Plains"):WaitForChild("PlainsMilestones")
local displayPart = board:WaitForChild("Cube", 5)
if not displayPart then
	warn("PlainsMilestones: Cube not found")
	return
end

local surfaceGui = displayPart:WaitForChild("SurfaceGui", 5)
if not surfaceGui or not surfaceGui:IsA("SurfaceGui") then
	warn("PlainsMilestones: Cube > SurfaceGui not found")
	return
end

local milestoneUI = surfaceGui:WaitForChild("MilestoneUI", 5)
if not milestoneUI then
	warn("PlainsMilestones: MilestoneUI not found")
	return
end

local title = milestoneUI:FindFirstChild("Title")
local scroll = milestoneUI:WaitForChild("MilestoneScroll", 5)

if not scroll then
	warn("PlainsMilestones: MilestoneScroll not found")
	return
end

if title and title:IsA("TextLabel") then
	title.Text = "PLAINS MILESTONES"
end

local milestones = MilestoneConfig.Biomes.Plains
local cards = {}

for index, milestone in ipairs(milestones) do
	local card = scroll:WaitForChild("Reset" .. index, 5)

	if card and card:IsA("Frame") then
		card.LayoutOrder = index

		-- Keep every card label visually consistent.
		local status = card:FindFirstChild("Status")
		if resetLabel and resetLabel:IsA("TextLabel") then
			resetLabel.TextScaled = false
			resetLabel.TextSize = 30
		end
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.TextScaled = false
			nameLabel.TextSize = 22
		end
		if bonusLabel and bonusLabel:IsA("TextLabel") then
			bonusLabel.TextScaled = false
			bonusLabel.TextSize = 18
		end
		if status and status:IsA("TextLabel") then
			status.TextScaled = false
			status.TextSize = 19
			status.AnchorPoint = Vector2.new(1, 0.5)
			status.Position = UDim2.new(1, -4, 0.5, 0)
			status.Size = UDim2.fromOffset(72, 40)
		end

		local resetLabel = card:FindFirstChild("ResetLabel")
		local nameLabel = card:FindFirstChild("NameLabel")
		local bonusLabel = card:FindFirstChild("BonusLabel")

		if resetLabel and resetLabel:IsA("TextLabel") then
			resetLabel.Text = tostring(index)
		end

		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = milestone.Title
		end

		if bonusLabel and bonusLabel:IsA("TextLabel") then
			bonusLabel.Text = milestone.BonusText
		end

		cards[index] = card
	else
		warn("PlainsMilestones: Reset" .. index .. " not found")
	end
end

local function update()
	local resetCount = math.clamp(player:GetAttribute("PlainsResetCount") or 0, 0, #milestones)

	for index, card in pairs(cards) do
		local status = card:FindFirstChild("Status")
		local stroke = card:FindFirstChildWhichIsA("UIStroke")
		local bonusLabel = card:FindFirstChild("BonusLabel")

		if index <= resetCount then
			card.BackgroundColor3 = Color3.fromRGB(42, 70, 48)
			if stroke then stroke.Color = Color3.fromRGB(105, 205, 95) end
			if status and status:IsA("TextLabel") then
				status.Text = "✓"
				status.TextColor3 = Color3.fromRGB(115, 235, 105)
			end
			if bonusLabel and bonusLabel:IsA("TextLabel") then
				bonusLabel.TextColor3 = Color3.fromRGB(130, 220, 105)
			end
		elseif index == resetCount + 1 then
			card.BackgroundColor3 = Color3.fromRGB(48, 51, 59)
			if stroke then stroke.Color = Color3.fromRGB(205, 185, 85) end
			if status and status:IsA("TextLabel") then
				status.Text = "!"
				status.TextColor3 = Color3.fromRGB(235, 215, 100)
			end
			if bonusLabel and bonusLabel:IsA("TextLabel") then
				bonusLabel.TextColor3 = Color3.fromRGB(235, 215, 100)
			end
		else
			card.BackgroundColor3 = Color3.fromRGB(32, 35, 42)
			if stroke then stroke.Color = Color3.fromRGB(70, 76, 88) end
			if status and status:IsA("TextLabel") then
				status.Text = "LOCK"
				status.TextColor3 = Color3.fromRGB(125, 132, 145)
			end
			if bonusLabel and bonusLabel:IsA("TextLabel") then
				bonusLabel.TextColor3 = Color3.fromRGB(125, 132, 145)
			end
		end
	end
end

player:GetAttributeChangedSignal("PlainsResetCount"):Connect(update)
update()

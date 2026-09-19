local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local MilestoneConfig = require(ReplicatedStorage:WaitForChild("MilestoneConfig"))

local boardsFolder = workspace:WaitForChild("Boards")

local BIOME_COLORS = {
	Plains = Color3.fromRGB(105, 205, 95),
	Forest = Color3.fromRGB(70, 155, 85),
	Savanna = Color3.fromRGB(220, 180, 70),
	Jungle = Color3.fromRGB(55, 175, 80),
}

local function setupBoard(biomeId, milestones)
	local biomeFolder = boardsFolder:FindFirstChild(biomeId)
	if not biomeFolder then
		warn("Milestones: " .. biomeId .. " board folder not found")
		return
	end

	local board = biomeFolder:FindFirstChild(biomeId .. "Milestones")
	if not board and biomeId ~= "Plains" then
		-- Other biome boards may not exist yet. Skip them without affecting Plains.
		return
	end
	if not board then
		warn("Milestones: " .. biomeId .. "Milestones not found")
		return
	end

	-- The imported milestone models do not all keep the display part named "Cube".
	-- Find the persistent SurfaceGui anywhere inside the milestone model instead.
	local surfaceGui = board:FindFirstChild("SurfaceGui", true)
	if not surfaceGui or not surfaceGui:IsA("SurfaceGui") then
		warn("Milestones: " .. biomeId .. " SurfaceGui not found")
		return
	end

	local milestoneUI = surfaceGui:FindFirstChild("MilestoneUI")
	if not milestoneUI then
		warn("Milestones: " .. biomeId .. " MilestoneUI not found")
		return
	end

	local title = milestoneUI:FindFirstChild("Title")
	local scroll = milestoneUI:FindFirstChild("MilestoneScroll")
	if not scroll then
		warn("Milestones: " .. biomeId .. " MilestoneScroll not found")
		return
	end

	if title and title:IsA("TextLabel") then
		title.Text = string.upper(biomeId) .. " MILESTONES"
	end

	local cards = {}

	for index, milestone in ipairs(milestones) do
		local card = scroll:FindFirstChild("Reset" .. index)

		if card and card:IsA("Frame") then
			card.LayoutOrder = index

			local resetLabel = card:FindFirstChild("ResetLabel")
			local nameLabel = card:FindFirstChild("NameLabel")
			local bonusLabel = card:FindFirstChild("BonusLabel")
			local status = card:FindFirstChild("Status")

			if resetLabel and resetLabel:IsA("TextLabel") then
				resetLabel.Text = tostring(index)
				resetLabel.TextScaled = false
				resetLabel.TextSize = 30
			end

			if nameLabel and nameLabel:IsA("TextLabel") then
				nameLabel.Text = milestone.Title
				nameLabel.TextScaled = false
				nameLabel.TextSize = 22
			end

			if bonusLabel and bonusLabel:IsA("TextLabel") then
				bonusLabel.Text = milestone.BonusText
				bonusLabel.TextScaled = false
				bonusLabel.TextSize = 15
			end

			if status and status:IsA("TextLabel") then
				status.TextScaled = false
				status.TextSize = 19
				status.AnchorPoint = Vector2.new(1, 0.5)
				status.Position = UDim2.new(1, 8, 0.5, 0)
				status.Size = UDim2.fromOffset(48, 40)
			end

			cards[index] = card
		else
			warn("Milestones: " .. biomeId .. " Reset" .. index .. " not found")
		end
	end

	local accent = BIOME_COLORS[biomeId] or Color3.fromRGB(105, 205, 95)

	local function update()
		local resetCount = math.clamp(player:GetAttribute(biomeId .. "ResetCount") or 0, 0, #milestones)

		for index, card in pairs(cards) do
			local status = card:FindFirstChild("Status")
			local stroke = card:FindFirstChildWhichIsA("UIStroke")
			local bonusLabel = card:FindFirstChild("BonusLabel")

			if index <= resetCount then
				card.BackgroundColor3 = Color3.fromRGB(42, 70, 48)
				if stroke then stroke.Color = accent end
				if status and status:IsA("TextLabel") then
					status.Text = "✓"
					status.TextColor3 = accent
				end
				if bonusLabel and bonusLabel:IsA("TextLabel") then
					bonusLabel.TextColor3 = accent
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

	player:GetAttributeChangedSignal(biomeId .. "ResetCount"):Connect(update)
	update()
end

for biomeId, milestones in pairs(MilestoneConfig.Biomes) do
	setupBoard(biomeId, milestones)
end

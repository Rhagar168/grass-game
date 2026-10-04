local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local menu = script.Parent:WaitForChild("CoreLabMenu")
local CoreLabConfig = require(ReplicatedStorage:WaitForChild("CoreLabConfig"))
local event = ReplicatedStorage:WaitForChild("CoreLabAction", 10)
if not event then
	warn("[CoreLab] CoreLabAction missing")
	return
end

local list = menu:WaitForChild("ResearchList"):WaitForChild("Scroll")
local detail = menu:WaitForChild("ResearchDetail")
local info = detail:WaitForChild("ResearchInfo")
local button = detail:WaitForChild("ResearchButton")
local progress = detail:WaitForChild("ResearchProgress")
local fill = progress:WaitForChild("Fill")

local normalCardColor = Color3.fromRGB(38, 45, 54)
local selectedCardColor = Color3.fromRGB(28, 70, 45)

local cancelButton = detail:FindFirstChild("CancelResearchButton")
if not cancelButton then
	cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelResearchButton"
	cancelButton.AnchorPoint = Vector2.new(1, 0)
	cancelButton.Position = UDim2.new(1, -25, 0, 24)
	cancelButton.Size = UDim2.fromOffset(155, 30)
	cancelButton.BackgroundColor3 = Color3.fromRGB(125, 42, 42)
	cancelButton.BorderSizePixel = 0
	cancelButton.Font = Enum.Font.Michroma
	cancelButton.Text = "CANCEL RESEARCH"
	cancelButton.TextSize = 10
	cancelButton.TextColor3 = Color3.fromRGB(255, 220, 220)
	cancelButton.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = cancelButton
	cancelButton.Parent = detail
end

local function setResearchingBadge(card, visible)
	local badge = card:FindFirstChild("ResearchingBadge")
	if visible and not badge then
		badge = Instance.new("TextLabel")
		badge.Name = "ResearchingBadge"
		badge.AnchorPoint = Vector2.new(1, 0.5)
		badge.Position = UDim2.new(1, -10, 0.5, 0)
		badge.Size = UDim2.fromOffset(125, 30)
		badge.BackgroundTransparency = 1
		badge.BorderSizePixel = 0
		badge.Font = Enum.Font.Michroma
		badge.Text = "RESEARCHING"
		badge.TextSize = 11
		badge.TextColor3 = Color3.fromRGB(65, 235, 110)
		badge.Parent = card
	elseif badge then
		badge.Visible = visible
	end
end
local selectedId = "Power"
local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%02d:%02d", m, s)
end

local function effectText(id, level)
	if id == "Extraction" then return string.format("+%d BOSS GC", level) end
	local research = CoreLabConfig.Researches[id]
	local pct = math.floor(research.EffectPerLevel * level * 100 + 0.5)
	if id == "Power" then return string.format("+%d%% DAMAGE", pct)
	elseif id == "Harvest" then return string.format("+%d%% GRASS", pct)
	elseif id == "Capacity" then return string.format("+%d%% CAPACITY", pct)
	elseif id == "Wisdom" then return string.format("+%d%% XP", pct)
	elseif id == "Critical" then return string.format("+%d%% CRIT DAMAGE", pct)
	elseif id == "BossHunter" then return string.format("+%d%% BOSS DAMAGE", pct)
	elseif id == "Accelerator" then return string.format("-%d%% BOSS COOLDOWN", pct) end
	return ""
end

local function updateSelection()
	local activeResearch = player:GetAttribute("CoreLabActiveResearch") or ""
	for id in pairs(CoreLabConfig.Researches) do
		local card = list:FindFirstChild(id)
		if card and card:IsA("GuiButton") then
			setResearchingBadge(card, id == activeResearch)
			card.BackgroundColor3 = id == selectedId and selectedCardColor or normalCardColor
			local cardStroke = card:FindFirstChild("CoreLabSelectionStroke")
			if id == selectedId then
				if not cardStroke then
					cardStroke = Instance.new("UIStroke")
					cardStroke.Name = "CoreLabSelectionStroke"
					cardStroke.Color = Color3.fromRGB(55, 220, 105)
					cardStroke.Thickness = 2
					cardStroke.Parent = card
				end
			elseif cardStroke then
				cardStroke:Destroy()
			end
		end
	end
end

local function refresh()
	local research = CoreLabConfig.Researches[selectedId]
	if not research then return end
	local level = math.max(0, math.floor(player:GetAttribute(research.Attribute) or 0))
	local active = player:GetAttribute("CoreLabActiveResearch") or ""
	local finishAt = player:GetAttribute("CoreLabResearchFinishAt") or 0
	local remaining = finishAt - os.time()
	local maxLevel = research.MaxLevel or CoreLabConfig.MaxLevel
	updateSelection()
	cancelButton.Visible = active ~= "" and active == selectedId

	menu.GrassCores.Amount.Text = tostring(player:GetAttribute("GrassCores") or 0) .. " GC"
	detail.ResearchName.Text = string.upper(research.DisplayName)
	detail.Level.Text = string.format("LEVEL %d / %d", level, maxLevel)
	detail.CurrentEffect.Value.Text = effectText(selectedId, level)

	if level >= maxLevel then
		detail.NextEffect.Value.Text = "MAX LEVEL"
		info.Cost.Text = "-"
		info.Time.Text = "-"
		button.Text = "MAX LEVEL"
		button.Active = false
		detail.Timer.Text = ""
		fill.Size = UDim2.fromScale(1, 1)
		return
	end

	local _, nextLevel, cost, duration = CoreLabConfig.GetNextLevelInfo(player, selectedId)
	detail.NextEffect.Value.Text = effectText(selectedId, nextLevel)
	info.Cost.Text = tostring(cost) .. " GC"
	info.Time.Text = formatTime(duration)
	button.Active = true

	fill.Size = UDim2.fromScale(0, 1)

	if active ~= "" then
		if active == selectedId then
			local _, _, _, duration = CoreLabConfig.GetNextLevelInfo(player, selectedId)
			if duration and duration > 0 then
				local elapsed = duration - math.max(0, remaining)
				fill.Size = UDim2.fromScale(math.clamp(elapsed / duration, 0, 1), 1)
			end
			if remaining <= 0 then
				button.Text = "CLAIM RESEARCH"
				detail.Timer.Text = "RESEARCH COMPLETE"
			else
				button.Text = "RESEARCHING..."
				detail.Timer.Text = formatTime(remaining) .. " REMAINING"
			end
		else
			button.Text = "RESEARCH IN PROGRESS"
			detail.Timer.Text = string.upper(CoreLabConfig.Researches[active] and CoreLabConfig.Researches[active].DisplayName or active)
		end
	else
		button.Text = "START RESEARCH"
		detail.Timer.Text = ""
	end
end

for id in pairs(CoreLabConfig.Researches) do
	local card = list:FindFirstChild(id)
	if card and card:IsA("GuiButton") then
		card.Activated:Connect(function()
			selectedId = id
			updateSelection()
			refresh()
		end)
	end
end

cancelButton.Activated:Connect(function()
	if (player:GetAttribute("CoreLabActiveResearch") or "") ~= "" then
		event:FireServer("Cancel")
	end
end)

button.Activated:Connect(function()
	local active = player:GetAttribute("CoreLabActiveResearch") or ""
	local finishAt = player:GetAttribute("CoreLabResearchFinishAt") or 0
	if active == selectedId and finishAt <= os.time() then
		event:FireServer("Claim")
	elseif active == "" then
		event:FireServer("Start", selectedId)
	end
end)

menu.CloseButton.Activated:Connect(function()
	menu.Visible = false
end)



for _, attribute in ipairs({"GrassCores","CoreLabActiveResearch","CoreLabResearchFinishAt","CoreLabPowerLevel","CoreLabHarvestLevel","CoreLabCapacityLevel","CoreLabWisdomLevel","CoreLabCriticalLevel","CoreLabBossHunterLevel","CoreLabAcceleratorLevel","CoreLabExtractionLevel"}) do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

event.OnClientEvent:Connect(function() refresh() end)

task.spawn(function()
	while menu.Parent do
		if menu.Visible then refresh() end
		task.wait(0.25)
	end
end)

refresh()

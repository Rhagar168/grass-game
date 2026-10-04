local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local menu = script.Parent
local CoreLabConfig = require(ReplicatedStorage:WaitForChild("CoreLabConfig"))
local event = ReplicatedStorage:WaitForChild("CoreLabAction")

local list = menu:WaitForChild("ResearchList"):WaitForChild("Scroll")
local detail = menu:WaitForChild("ResearchDetail")
local info = detail:WaitForChild("ResearchInfo")
local button = detail:WaitForChild("ResearchButton")
local selectedId = "Power"
local zone = workspace:WaitForChild("CoreLab"):WaitForChild("CoreLabZone")
local insideZone = false

-- Core Lab can only be opened by standing inside the physical lab zone.
menu.Visible = false

local function isInsideZone()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	local localPos = zone.CFrame:PointToObjectSpace(root.Position)
	local radius = math.min(zone.Size.Y, zone.Size.Z) * 0.5
	local radialDistance = math.sqrt(localPos.Y * localPos.Y + localPos.Z * localPos.Z)
	local halfThickness = zone.Size.X * 0.5

	return math.abs(localPos.X) <= halfThickness + 4
		and radialDistance <= radius
end

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

local function refresh()
	local research = CoreLabConfig.Researches[selectedId]
	if not research then return end
	local level = math.max(0, math.floor(player:GetAttribute(research.Attribute) or 0))
	local active = player:GetAttribute("CoreLabActiveResearch") or ""
	local finishAt = player:GetAttribute("CoreLabResearchFinishAt") or 0
	local remaining = finishAt - os.time()

	menu.GrassCores.Amount.Text = tostring(player:GetAttribute("GrassCores") or 0) .. " GC"
	detail.ResearchName.Text = string.upper(research.DisplayName)
	detail.Level.Text = string.format("LEVEL %d / %d", level, CoreLabConfig.MaxLevel)
	detail.CurrentEffect.Value.Text = effectText(selectedId, level)

	if level >= CoreLabConfig.MaxLevel then
		detail.NextEffect.Value.Text = "MAX LEVEL"
		info.Cost.Text = "-"
		info.Time.Text = "-"
		button.Text = "MAX LEVEL"
		button.Active = false
		detail.Timer.Text = ""
		return
	end

	local _, nextLevel, cost, duration = CoreLabConfig.GetNextLevelInfo(player, selectedId)
	detail.NextEffect.Value.Text = effectText(selectedId, nextLevel)
	info.Cost.Text = tostring(cost) .. " GC"
	info.Time.Text = formatTime(duration)
	button.Active = true

	if active ~= "" then
		if active == selectedId then
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
			refresh()
		end)
	end
end

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

task.spawn(function()
	while menu.Parent do
		local nowInside = isInsideZone()
		if nowInside and not insideZone then
			insideZone = true
			menu.Visible = true
			refresh()
		elseif not nowInside and insideZone then
			insideZone = false
			menu.Visible = false
		end
		task.wait(0.1)
	end
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

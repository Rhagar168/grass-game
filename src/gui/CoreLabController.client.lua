local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local menu = script.Parent:WaitForChild("CoreLabMenu")
-- Slightly enlarge the entire lab while keeping it inside the screen.
local camera = workspace.CurrentCamera
local labAnimating = false
local labScale = menu:FindFirstChild("CoreLabReadableScale")
if not labScale then
    labScale = Instance.new("UIScale")
    labScale.Name = "CoreLabReadableScale"
    labScale.Parent = menu
end
local updatingLabScale = false
local function updateLabScale()
    if labAnimating or updatingLabScale then return end
    updatingLabScale = true
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local original = menu.AbsoluteSize
    local currentScale = labScale.Scale
    local unscaled = original / math.max(currentScale, 0.01)
    local widthLimit = viewport.X * 0.94 / math.max(unscaled.X, 1)
    local heightLimit = viewport.Y * 0.90 / math.max(unscaled.Y, 1)
    local target = math.min(1.08, widthLimit, heightLimit)
    if math.abs(labScale.Scale - target) > 0.001 then
        labScale.Scale = target
    end
    updatingLabScale = false
end
local openSound = Instance.new("Sound")
openSound.Name = "CoreLabOpenPop"
openSound.SoundId = "rbxasset://sounds/button.wav"
openSound.Volume = 0.22
openSound.PlaybackSpeed = 1.15
openSound.Parent = SoundService

local openTween
local function animateLabOpen()
    if openTween then openTween:Cancel() end
    updateLabScale()
    local targetScale = labScale.Scale
    labAnimating = true
    labScale.Scale = targetScale * 0.88
    openSound.TimePosition = 0
    openSound:Play()
    openTween = TweenService:Create(labScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = targetScale})
    local tween = openTween
    tween:Play()
    tween.Completed:Once(function()
        if openTween == tween then
            labAnimating = false
            updateLabScale()
        end
    end)
end
menu:GetPropertyChangedSignal("Visible"):Connect(function()
    if menu.Visible then
        animateLabOpen()
    elseif openTween then
        openTween:Cancel()
        labAnimating = false
    end
end)
if menu.Visible then task.defer(animateLabOpen) end

task.defer(updateLabScale)
-- Do not observe menu.AbsoluteSize here: changing UIScale changes AbsoluteSize
-- synchronously and creates an event recursion loop. Viewport changes are enough.
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateLabScale)
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLabScale) end

-- Force a visibly larger title even when the Studio label has TextScaled enabled.
local function emphasizeCoreLabTitle()
    for _, item in ipairs(menu:GetDescendants()) do
        if item:IsA("TextLabel") and (item.Text == "CORE LAB" or item.Name == "Title" and item.Text:find("CORE LAB", 1, true)) then
            item.TextScaled = false
            item.TextSize = 52
            item.TextColor3 = Color3.fromRGB(55, 255, 135)
            item.TextStrokeColor3 = Color3.fromRGB(5, 35, 20)
            item.TextStrokeTransparency = 0.4
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.Size = UDim2.new(item.Size.X.Scale, math.max(item.Size.X.Offset, 410), item.Size.Y.Scale, math.max(item.Size.Y.Offset, 70))
            item:SetAttribute("CoreLabOriginalTextSize", 52)
            local constraint = item:FindFirstChildOfClass("UITextSizeConstraint")
            if constraint then constraint.MaxTextSize = 60 end
        end
    end
end
emphasizeCoreLabTitle()

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

-- Disable competing hover effects on the research list and action button.
-- Keep selection/purchase colors managed by refresh() and updateSelection().
local function disableHoverEffects(target)
    target.AutoButtonColor = false
    for _, child in ipairs(target:GetChildren()) do
        if child:IsA("UIScale") then
            child:Destroy()
        end
    end
end
disableHoverEffects(button)
for _, card in ipairs(list:GetChildren()) do
    if card:IsA("GuiButton") then
        disableHoverEffects(card)
    end
end

-- Stable hover feedback: a thin outline, never resizing or changing refresh-owned colors.
local function addHoverOutline(target)
    local outline = Instance.new("UIStroke")
    outline.Name = "CoreLabHoverOutline"
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline.Color = Color3.fromRGB(130, 245, 170)
    outline.Thickness = 1.5
    outline.Transparency = 1
    outline.Parent = target
    local activeTween
    local function transition(hovering)
        if activeTween then activeTween:Cancel() end
        activeTween = TweenService:Create(outline, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Transparency = hovering and 0.2 or 1
        })
        activeTween:Play()
    end
    target.MouseEnter:Connect(function() transition(true) end)
    target.MouseLeave:Connect(function() transition(false) end)
end
addHoverOutline(button)
for _, card in ipairs(list:GetChildren()) do
    if card:IsA("GuiButton") then addHoverOutline(card) end
end

-- Hide GC balance in the top bar; costs remain visible in research details.
local topBarCores = menu:FindFirstChild("GrassCores")
if topBarCores then topBarCores.Visible = false end

-- Improve readability of the existing Studio-authored Core Lab GUI.
local function enlargeText(root)
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("TextLabel") or item:IsA("TextButton") then
            if item.Name == "Subtitle" or (item:IsA("TextLabel") and item.Text == "RESEARCH PERMANENT CORE TECHNOLOGIES") then
                item.Visible = false
            elseif not item.TextScaled then
                local original = item:GetAttribute("CoreLabOriginalTextSize")
                if not original then
                    original = item.TextSize
                    item:SetAttribute("CoreLabOriginalTextSize", original)
                end
                item.TextSize = math.min(32, math.max(original + 2, math.floor(original * 1.3 + 0.5)))
            end
        end
    end
end
enlargeText(menu)
emphasizeCoreLabTitle()
menu.DescendantAdded:Connect(function(item)
    if item:IsA("TextLabel") or item:IsA("TextButton") then
        task.defer(function()
            if item.Parent then enlargeText(item.Parent) end
        end)
    end
end)

-- Mobile layout: avoid desktop-sized typography and overlapping columns.
local mobileLayoutOriginals = {}
local function rememberMobileLayout(object)
    if not object or not object:IsA("GuiObject") then return end
    if not mobileLayoutOriginals[object] then
        mobileLayoutOriginals[object] = {
            Position = object.Position, Size = object.Size,
            AnchorPoint = object.AnchorPoint,
        }
    end
end

local function updateCoreLabMobile()
    local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local mobile = view.X < 950 or view.Y < 550
    local researchList = menu:FindFirstChild("ResearchList")
    local researchDetail = menu:FindFirstChild("ResearchDetail")
    local title
    for _, child in ipairs(menu:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text == "CORE LAB" then title = child break end
    end
    for _, obj in ipairs({menu, researchList, researchDetail, title}) do rememberMobileLayout(obj) end

    if mobile then
        -- Scale the entire desktop-authored menu to the available landscape viewport.
        -- Two columns stay intact and the right-hand research details remain readable.
        local width = math.min(view.X - 26, 760)
        local height = math.min(view.Y - 24, 440)
        menu.AnchorPoint = Vector2.new(0.5, 0.5)
        menu.Position = UDim2.fromScale(0.5, 0.5)
        menu.Size = UDim2.fromOffset(width, height)
        if researchList then
            researchList.AnchorPoint = Vector2.new(0, 0)
            researchList.Position = UDim2.fromScale(0.035, 0.27)
            researchList.Size = UDim2.new(0.34, 0, 0.68, 0)
        end
        if researchDetail then
            researchDetail.AnchorPoint = Vector2.new(0, 0)
            researchDetail.Position = UDim2.fromScale(0.40, 0.27)
            researchDetail.Size = UDim2.new(0.56, 0, 0.68, 0)
        end
        if title then
            title.TextScaled = false
            title.TextSize = 24
            title.Size = UDim2.new(0.75, 0, 0, 38)
            title.Position = UDim2.fromScale(0.035, 0.07)
        end
        -- Use available screen width, not a large desktop scale.
        labScale.Scale = 1
        if researchList then
            local scroll = researchList:FindFirstChild("Scroll")
            if scroll and scroll:IsA("ScrollingFrame") then
                scroll.ScrollingEnabled = true
                scroll.ScrollBarThickness = 4
            end
        end
        for _, root in ipairs({researchList, researchDetail}) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        if not obj:GetAttribute("CoreLabMobileOriginalSize") then
                            obj:SetAttribute("CoreLabMobileOriginalSize", obj.TextSize)
                        end
                        obj.TextScaled = false
                        obj.TextSize = math.clamp(obj:GetAttribute("CoreLabMobileOriginalSize"), 9, 16)
                        obj.TextWrapped = true
                    end
                end
            end
        end
    else
        for obj, original in pairs(mobileLayoutOriginals) do
            if obj.Parent then
                obj.Position = original.Position
                obj.Size = original.Size
                obj.AnchorPoint = original.AnchorPoint
            end
        end
        if title then title.TextSize = 52 end
        updateLabScale()
    end
end
local function updateMobileWhenVisible()
    if menu.Visible then task.defer(updateCoreLabMobile) end
end
menu:GetPropertyChangedSignal("Visible"):Connect(updateMobileWhenVisible)
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCoreLabMobile) end
task.defer(updateCoreLabMobile)

local normalCardColor = Color3.fromRGB(38, 45, 54)
local selectedCardColor = Color3.fromRGB(28, 70, 45)
local activeButtonColor = Color3.fromRGB(46, 185, 83)
local disabledButtonColor = Color3.fromRGB(32, 78, 48)

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
		badge.Position = UDim2.new(1, -10, 1, -13)
		badge.Size = UDim2.fromOffset(125, 18)
		badge.BackgroundTransparency = 1
		badge.BorderSizePixel = 0
		badge.Font = Enum.Font.Michroma
		badge.Text = "RESEARCHING"
		badge.TextSize = 12
		badge.TextColor3 = Color3.fromRGB(65, 235, 110)
		badge.Parent = card
	elseif badge then
		badge.Visible = visible
	end
end
local function updateCardLevel(card, research)
    local label = card:FindFirstChild("CoreLabLevelLabel")
    if not label then
        label = Instance.new("TextLabel")
        label.Name = "CoreLabLevelLabel"
        label.AnchorPoint = Vector2.new(1, 0)
        label.Position = UDim2.new(1, -12, 0, 9)
        label.Size = UDim2.fromOffset(65, 20)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Michroma
        label.TextSize = 15
        label.TextXAlignment = Enum.TextXAlignment.Right
        label.TextColor3 = Color3.fromRGB(100, 225, 140)
        label.ZIndex = card.ZIndex + 2
        label.Parent = card
    end
    local level = math.max(0, math.floor(player:GetAttribute(research.Attribute) or 0))
    label.Text = string.format("%d/%d", level, research.MaxLevel or CoreLabConfig.MaxLevel)
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
	for id, research in pairs(CoreLabConfig.Researches) do
		local card = list:FindFirstChild(id)
		if card and card:IsA("GuiButton") then
            updateCardLevel(card, research)
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

	-- GC balance is intentionally hidden from the top bar.
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
	button.BackgroundColor3 = activeButtonColor

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
				button.BackgroundColor3 = activeButtonColor
				detail.Timer.Text = "RESEARCH COMPLETE"
			else
				button.Text = "RESEARCHING..."
				button.BackgroundColor3 = activeButtonColor
				detail.Timer.Text = formatTime(remaining) .. " REMAINING"
			end
		else
			button.Text = "RESEARCH IN PROGRESS"
			button.BackgroundColor3 = disabledButtonColor
			button.Active = false
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

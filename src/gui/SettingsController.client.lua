local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local menu = script.Parent
local mainUI = menu.Parent
local content = menu:WaitForChild("Content")
local settingsButton = mainUI:WaitForChild("RightMenu"):WaitForChild("SettingsButton")
local closeButton = menu:WaitForChild("CloseButton")
local updateSettingEvent = ReplicatedStorage:WaitForChild("UpdateSetting")

local SETTINGS = {
	GrassPopups = true, DamagePopups = true, CriticalPopups = true, InstantBreakPopups = true,
	InstantSell = true, InstantZoneSell = false, InstantSellPopups = true,
	XPPopups = true, Music = true, SoundEffects = true,
}

local ON_COLOR = Color3.fromRGB(48,180,82)
local ON_STROKE = Color3.fromRGB(88,220,116)
local OFF_COLOR = Color3.fromRGB(65,72,80)
local OFF_STROKE = Color3.fromRGB(85,92,100)
local WHITE = Color3.fromRGB(255,255,255)

for settingName, defaultValue in pairs(SETTINGS) do
	local attributeName = "Setting_" .. settingName
	if player:GetAttribute(attributeName) == nil then
		player:SetAttribute(attributeName, defaultValue)
	end
end

local scale = menu:FindFirstChild("OpenScale") or Instance.new("UIScale")
scale.Name = "OpenScale"
scale.Scale = 1
scale.Parent = menu
local opening = false

local function updateToggle(button, enabled)
	button.Text = enabled and "ON" or "OFF"
	button.TextColor3 = WHITE
	button.TextTransparency = 0
	button.TextStrokeTransparency = 1
	local stroke = button:FindFirstChildOfClass("UIStroke")
	button.BackgroundColor3 = enabled and ON_COLOR or OFF_COLOR
	if stroke then stroke.Color = enabled and ON_STROKE or OFF_STROKE end
end

local function setupSetting(rowName, settingName)
	local row = content:FindFirstChild(rowName)
	if not row then warn("[Settings] Missing row:", rowName) return end
	local toggle = row:FindFirstChild("Toggle")
	if not toggle then warn("[Settings] Missing Toggle:", rowName) return end
	local attributeName = "Setting_" .. settingName
	local function refresh()
		local enabled = player:GetAttribute(attributeName)
		if enabled == nil then enabled = SETTINGS[settingName] ~= false end
		toggle:SetAttribute("Enabled", enabled)
		updateToggle(toggle, enabled)
	end
	toggle.MouseButton1Click:Connect(function()
		local current = player:GetAttribute(attributeName)
		if current == nil then current = SETTINGS[settingName] ~= false end
		updateSettingEvent:FireServer(settingName, not current)
	end)
	player:GetAttributeChangedSignal(attributeName):Connect(refresh)
	refresh()
end

local function styleSection(label, text, order)
	label.Text = text
	label.LayoutOrder = order
	label.Font = Enum.Font.Michroma
	label.TextColor3 = Color3.fromRGB(75,220,105)
	label.TextScaled = true
	label.BackgroundTransparency = 1
end

local popupSection = content:FindFirstChild("POPUPSSection")
if not popupSection then
	popupSection = Instance.new("TextLabel")
	popupSection.Name = "POPUPSSection"
	popupSection.Size = UDim2.new(1,0,0,24)
	popupSection.Parent = content
end
styleSection(popupSection, "POPUPS", 10)
styleSection(content:WaitForChild("GAMEPLAYSection"), "GAMEPLAY", 80)
styleSection(content:WaitForChild("AUDIOSection"), "AUDIO", 110)

local orders = {
	GrassPopups=20, DamagePopups=30, CriticalPopups=40, InstantBreakPopups=50, XPPopups=60, InstantSellPopups=70,
	InstantSell=90, InstantZoneSell=100, Music=120, SFX=130,
}
for name, order in pairs(orders) do
	local row = content:FindFirstChild(name)
	if row then row.LayoutOrder = order end
end

local cutRow = content:FindFirstChild("CutCount")

local function setupCutCount()

	if not cutRow then return end

	local minus = cutRow:FindFirstChild("Minus")
	if minus then minus:Destroy() end

	local plus = cutRow:FindFirstChild("Plus")
	if plus then plus:Destroy() end

	local box = cutRow:FindFirstChild("Value")
	if not box or not box:IsA("TextBox") then return end

	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -18, 0.5, 0)
	box.Size = UDim2.fromOffset(86, 34)

	local function maxCount()
		return math.max(1, math.floor(player:GetAttribute("AvailableCutCount") or 1))
	end

	local function selected()
		return math.clamp(math.floor(player:GetAttribute("Setting_CutCount") or maxCount()), 1, maxCount())
	end

	local function refresh()
		box.Text = tostring(selected())
	end

	local editingText = false

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if editingText then return end

		local digits = box.Text:gsub("%D", "")
		local n = tonumber(digits)

		if not n then
			return
		end

		local capped = math.clamp(math.floor(n), 1, maxCount())
		if tostring(capped) ~= box.Text then
			editingText = true
			box.Text = tostring(capped)
			box.CursorPosition = #box.Text + 1
			editingText = false
		end
	end)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text:match("%d+"))
		if n then
			local capped = math.clamp(math.floor(n), 1, maxCount())
			box.Text = tostring(capped)
			updateSettingEvent:FireServer("CutCount", capped)
		else
			refresh()
		end
	end)

	player:GetAttributeChangedSignal("Setting_CutCount"):Connect(refresh)
	player:GetAttributeChangedSignal("AvailableCutCount"):Connect(refresh)
	refresh()
end

setupSetting("GrassPopups","GrassPopups")
setupSetting("DamagePopups","DamagePopups")
setupSetting("CriticalPopups","CriticalPopups")

-- Create the Instant Break popup row from the existing Critical popup row
-- so the setting is source-controlled and does not require a manual Studio UI edit.
local instantBreakRow = content:FindFirstChild("InstantBreakPopups")
if not instantBreakRow then
	local template = content:FindFirstChild("CriticalPopups")
	if template then
		instantBreakRow = template:Clone()
		instantBreakRow.Name = "InstantBreakPopups"
		instantBreakRow.LayoutOrder = 50

		local label = instantBreakRow:FindFirstChild("Label")
			or instantBreakRow:FindFirstChild("Title")
			or instantBreakRow:FindFirstChildWhichIsA("TextLabel")
		if label then
			label.Text = "Instant Break Popups"
		end

		instantBreakRow.Parent = content
	end
end

setupSetting("InstantBreakPopups","InstantBreakPopups")
setupSetting("InstantSell","InstantSell")
setupSetting("InstantZoneSell","InstantZoneSell")
setupSetting("InstantSellPopups","InstantSellPopups")
setupSetting("XPPopups","XPPopups")
setupCutCount()
-- Compact draggable volume controls beneath the existing audio toggles.
local UserInputService = game:GetService("UserInputService")
local function addVolumeSlider(rowName, settingName, defaultPercent)
    local row = content:FindFirstChild(rowName)
    if not row then return end
    row.Size = UDim2.new(row.Size.X.Scale, row.Size.X.Offset, 0, 98)
    local old = row:FindFirstChild("VolumeControl")
    if old then old:Destroy() end

    local holder = Instance.new("Frame")
    holder.Name = "VolumeControl"
    holder.BackgroundTransparency = 1
    holder.Position = UDim2.new(0, 18, 1, -36)
    holder.Size = UDim2.new(1, -36, 0, 28)
    holder.Parent = row

    local label = Instance.new("TextLabel")
    label.Name = "VolumeLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(92, 22)
    label.Position = UDim2.fromOffset(0, 0)
    label.Text = "VOLUME"
    label.TextColor3 = Color3.fromRGB(185, 195, 193)
    label.Font = Enum.Font.Michroma
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local percent = Instance.new("TextLabel")
    percent.Name = "Percent"
    percent.BackgroundTransparency = 1
    percent.AnchorPoint = Vector2.new(1, 0)
    percent.Position = UDim2.new(1, 0, 0, 0)
    percent.Size = UDim2.fromOffset(48, 22)
    percent.TextColor3 = WHITE
    percent.Font = Enum.Font.Michroma
    percent.TextSize = 11
    percent.Parent = holder

    local track = Instance.new("TextButton")
    track.Name = "Track"
    track.AutoButtonColor = false
    track.Text = ""
    track.BackgroundColor3 = Color3.fromRGB(48, 59, 56)
    track.BorderSizePixel = 0
    track.Position = UDim2.new(0, 93, 0, 9)
    track.Size = UDim2.new(1, -150, 0, 6)
    track.Parent = holder
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BorderSizePixel = 0
    fill.BackgroundColor3 = Color3.fromRGB(48, 180, 82)
    fill.Size = UDim2.fromScale(0.3, 1)
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.fromScale(0.3, 0.5)
    knob.Size = UDim2.fromOffset(24, 24)
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.BackgroundColor3 = WHITE
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local attr = "Setting_" .. settingName
    local dragging = false
    local current = defaultPercent
    local function draw(v)
        current = math.clamp(math.floor(v + 0.5), 0, 100)
        local ratio = current / 100
        fill.Size = UDim2.fromScale(ratio, 1)
        knob.Position = UDim2.fromScale(ratio, 0.5)
        percent.Text = tostring(current) .. "%"
    end
    local function fromPointer(x)
        if track.AbsoluteSize.X <= 0 then return end
        draw((x - track.AbsolutePosition.X) / track.AbsoluteSize.X * 100)
        player:SetAttribute(attr, current) -- immediate local preview
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromPointer(input.Position.X)
        end
    end)
    -- Allow dragging directly from the larger knob, not just the thin track.
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromPointer(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromPointer(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            updateSettingEvent:FireServer(settingName, current)
        end
    end)
    player:GetAttributeChangedSignal(attr):Connect(function()
        if not dragging then draw(player:GetAttribute(attr) or defaultPercent) end
    end)
    draw(player:GetAttribute(attr) or defaultPercent)
end
addVolumeSlider("Music", "MusicVolume", 30)
addVolumeSlider("SFX", "SFXVolume", 100)

-- Audio is controlled exclusively by the sliders.
for _, rowName in ipairs({"Music", "SFX"}) do
    local row = content:FindFirstChild(rowName)
    if row then
        local toggle = row:FindFirstChild("Toggle")
        if toggle then toggle:Destroy() end
        local description = row:FindFirstChild("Description")
        if description and description:IsA("TextLabel") then
            description.Text = "Adjust volume (0% = muted)."
        end
    end
end

local function openMenu()
	if opening then return end
	opening=true; menu.Visible=true; scale.Scale=.88
	local tween=TweenService:Create(scale,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1})
	tween:Play(); tween.Completed:Wait(); opening=false
end
local function closeMenu()
	if not menu.Visible then return end
	local tween=TweenService:Create(scale,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=.92})
	tween:Play(); tween.Completed:Wait(); menu.Visible=false; scale.Scale=1
end
settingsButton.MouseButton1Click:Connect(function() if menu.Visible then closeMenu() else openMenu() end end)
closeButton.MouseButton1Click:Connect(closeMenu)

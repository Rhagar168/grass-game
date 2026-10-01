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
	GrassPopups = true, DamagePopups = true, CriticalPopups = true,
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
styleSection(content:WaitForChild("GAMEPLAYSection"), "GAMEPLAY", 70)
styleSection(content:WaitForChild("AUDIOSection"), "AUDIO", 110)

local orders = {
	GrassPopups=20, DamagePopups=30, CriticalPopups=40, XPPopups=50, InstantSellPopups=60,
	InstantSell=80, InstantZoneSell=90, Music=120, SFX=130,
}
for name, order in pairs(orders) do
	local row = content:FindFirstChild(name)
	if row then row.LayoutOrder = order end
end

local cutRow = content:FindFirstChild("CutCount")
if not cutRow then
	local template = content:FindFirstChild("InstantSell")
	if template then
		cutRow = template:Clone()
		cutRow.Name = "CutCount"
		cutRow.LayoutOrder = 100
		cutRow.Parent = content
		local label = cutRow:FindFirstChildWhichIsA("TextLabel")
		if label then label.Text = "CUT COUNT" end
		local oldToggle = cutRow:FindFirstChild("Toggle")
		if oldToggle then oldToggle:Destroy() end

		local minus = Instance.new("TextButton")
		minus.Name="Minus"; minus.Text="-"; minus.Size=UDim2.fromOffset(34,30); minus.AnchorPoint=Vector2.new(1,0.5); minus.Position=UDim2.new(1,-116,0.5,0)
		minus.Font=Enum.Font.GothamBlack; minus.TextScaled=true; minus.TextColor3=WHITE; minus.BackgroundColor3=OFF_COLOR; minus.Parent=cutRow
		Instance.new("UICorner",minus).CornerRadius=UDim.new(0,7)

		local box = Instance.new("TextBox")
		box.Name="Value"; box.Size=UDim2.fromOffset(66,30); box.AnchorPoint=Vector2.new(1,0.5); box.Position=UDim2.new(1,-44,0.5,0)
		box.Font=Enum.Font.GothamBlack; box.TextScaled=true; box.TextColor3=WHITE; box.BackgroundColor3=Color3.fromRGB(35,42,45); box.ClearTextOnFocus=false; box.Parent=cutRow
		Instance.new("UICorner",box).CornerRadius=UDim.new(0,7)

		local plus = Instance.new("TextButton")
		plus.Name="Plus"; plus.Text="+"; plus.Size=UDim2.fromOffset(34,30); plus.AnchorPoint=Vector2.new(1,0.5); plus.Position=UDim2.new(1,-4,0.5,0)
		plus.Font=Enum.Font.GothamBlack; plus.TextScaled=true; plus.TextColor3=WHITE; plus.BackgroundColor3=ON_COLOR; plus.Parent=cutRow
		Instance.new("UICorner",plus).CornerRadius=UDim.new(0,7)
	end
end

local function setupCutCount()
	if not cutRow then return end
	local minus, plus, box = cutRow:FindFirstChild("Minus"), cutRow:FindFirstChild("Plus"), cutRow:FindFirstChild("Value")
	if not minus or not plus or not box then return end
	local function maxCount() return math.max(1, math.floor(player:GetAttribute("AvailableCutCount") or 1)) end
	local function selected() return math.clamp(math.floor(player:GetAttribute("Setting_CutCount") or maxCount()),1,maxCount()) end
	local function refresh() box.Text = tostring(selected()) end
	local function send(v) updateSettingEvent:FireServer("CutCount", math.clamp(math.floor(v),1,maxCount())) end
	minus.MouseButton1Click:Connect(function() send(selected()-1) end)
	plus.MouseButton1Click:Connect(function() send(selected()+1) end)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text:match("%d+"))
		if n then send(n) else refresh() end
	end)
	player:GetAttributeChangedSignal("Setting_CutCount"):Connect(refresh)
	player:GetAttributeChangedSignal("AvailableCutCount"):Connect(refresh)
	refresh()
end

setupSetting("GrassPopups","GrassPopups")
setupSetting("DamagePopups","DamagePopups")
setupSetting("CriticalPopups","CriticalPopups")
setupSetting("InstantSell","InstantSell")
setupSetting("InstantZoneSell","InstantZoneSell")
setupSetting("InstantSellPopups","InstantSellPopups")
setupSetting("XPPopups","XPPopups")
setupSetting("Music","Music")
setupSetting("SFX","SoundEffects")
setupCutCount()

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

-- Paste this entire script into Roblox Studio > View > Command Bar (Edit mode).
local starterGui = game:GetService("StarterGui")
local previous = starterGui:FindFirstChild("PetEggHatchGui")
if previous then previous:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "PetEggHatchGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = starterGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Visible = false
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "MainFrame"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.fromOffset(560, 380)
window.BackgroundColor3 = Color3.fromRGB(15, 26, 22)
window.Visible = false
window.Parent = gui

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

round(window, 16)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Parent = window

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(20, 14)
title.Size = UDim2.new(1, -85, 0, 40)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Gotham
title.TextSize = 30
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(54, 218, 112)
title.Parent = window

local close = Instance.new("TextButton")
close.Name = "CloseButton"
close.Position = UDim2.new(1, -8, 0, -8)
close.Size = UDim2.fromOffset(58, 58)
close.BackgroundColor3 = Color3.fromRGB(207, 47, 58)
close.Text = "×"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.Gotham
close.TextSize = 38
close.Parent = window
round(close, 5)

local function makeButton(label, x)
	local button = Instance.new("TextButton")
	button.Position = UDim2.new(x, 0, 0, 286)
	button.Size = UDim2.new(0.42, 0, 0, 55)
	button.BackgroundColor3 = Color3.fromRGB(39, 177, 82)
	button.Text = label
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 22
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = window
	round(button, 12)
	return button
end

local hatch1 = makeButton("HATCH x1", 0.055)
hatch1.Name = "Hatch1Button"
local hatch3 = makeButton("HATCH x3", 0.525)
hatch3.Name = "Hatch3Button"

local message = Instance.new("TextLabel")
message.Name = "Message"
message.Position = UDim2.fromOffset(16, 345)
message.Size = UDim2.new(1, -32, 0, 28)
message.BackgroundTransparency = 1
message.TextWrapped = true
message.TextColor3 = Color3.fromRGB(255, 220, 125)
message.Font = Enum.Font.GothamBold
message.TextSize = 16
message.Parent = window

local banner = Instance.new("Frame")
banner.Name = "Banner"
banner.Size = UDim2.new(1, -6, 0, 70)
banner.Position = UDim2.fromOffset(3, 3)
banner.BackgroundColor3 = Color3.fromRGB(15, 26, 22)
banner.BorderSizePixel = 0
banner.Parent = window
round(banner, 12)
title.ZIndex = 2
close.ZIndex = 2

local function makePrice(x)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.new(x, 0, 0, 243)
    label.Size = UDim2.new(0.42, 0, 0, 35)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 23
    label.TextColor3 = Color3.fromRGB(255, 212, 76)
    label.Parent = window
    return label
end

local price1 = makePrice(0.055)
price1.Name = "Price1"
local price3 = makePrice(0.525)
price3.Name = "Price3"

local contentPanel = Instance.new("Frame")
contentPanel.Name = "ContentPanel"
contentPanel.Position = UDim2.fromOffset(17, 82)
contentPanel.Size = UDim2.new(1, -34, 0, 178)
contentPanel.BackgroundColor3 = Color3.fromRGB(28, 34, 40)
contentPanel.BorderSizePixel = 0
contentPanel.ZIndex = 0
contentPanel.Parent = window
round(contentPanel, 12)
local contentStroke = Instance.new("UIStroke")
contentStroke.Color = Color3.fromRGB(55, 73, 72)
contentStroke.Thickness = 1.5
contentStroke.Parent = contentPanel


print("PetEggHatchGui created in StarterGui. Save your place.")

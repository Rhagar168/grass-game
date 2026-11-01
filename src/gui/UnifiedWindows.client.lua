-- Unified responsive menu layout. Keeps existing content and open/close scripts.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = script.Parent
local camera = workspace.CurrentCamera

local BG = Color3.fromRGB(18,27,23)
local PANEL = Color3.fromRGB(28,32,38)
local GREEN = Color3.fromRGB(48,180,82)
local RED = Color3.fromRGB(196,48,62)
local WHITE = Color3.fromRGB(255,255,255)
local MICHROMA = Font.new("rbxasset://fonts/families/Michroma.json")

local groups = {
    -- Tools / Index / Profile / Inventory share the large window size.
    {name="ToolsMenu", large=true},
    {name="IndexMenu", large=true},
    {name="ProfileMenu", large=true},
    {name="InventoryWindow", large=true},
    -- Right-hand shortcuts use the same compact window size.
    {name="SettingsMenu", large=false},
    {name="TeleportMenu", large=false},
    {name="DailyRewardsMenu", large=false},
}
local windows = {}
local function findClose(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("TextButton") and
            (descendant.Name:lower():find("close") or descendant.Name == "Close" or descendant.Text == "×" or descendant.Text == "X") then
            return descendant
        end
    end
end
local function styleClose(button)
    if not button then return end
    button.BackgroundColor3 = RED
    button.BackgroundTransparency = 0
    button.TextColor3 = WHITE
    button.Text = "×"
    button.FontFace = MICHROMA
    button.TextScaled = false
    button.TextSize = 24
    button.AutoButtonColor = true
    local corner = button:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,5)
    corner.Parent = button
    -- Keep the button's existing position and click connection.
end
local function setup(frame, large)
    if not frame or not frame:IsA("GuiObject") then return end
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.fromScale(0.5,0.5)
    frame.Size = UDim2.fromOffset(large and 1280 or 920,large and 700 or 550)
    frame.BackgroundColor3 = BG
    frame.BackgroundTransparency = 0
    local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,12)
    corner.Parent = frame
    local responsive = frame:FindFirstChild("UnifiedResponsiveScale")
    if not responsive then
        responsive = Instance.new("UIScale")
        responsive.Name = "UnifiedResponsiveScale"
        responsive.Parent = frame
    end
    styleClose(findClose(frame))
    table.insert(windows,{frame=frame,large=large,scale=responsive})
end
for _, item in ipairs(groups) do
    setup(gui:FindFirstChild(item.name),item.large)
end

-- Shop is a separate ScreenGui with its own outer shade.
task.spawn(function()
    local shop = player:WaitForChild("PlayerGui"):WaitForChild("GamepassShop",20)
    if not shop then return end
    local shade = shop:FindFirstChild("Frame")
    local panel = shade and shade:FindFirstChild("Panel")
    if panel then setup(panel,false) end
end)

local function resize()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local size = cam.ViewportSize
    for _, entry in ipairs(windows) do
        local w = entry.large and 1280 or 920
        local h = entry.large and 700 or 550
        local margin = size.X < 800 and 18 or 45
        local topBottom = size.Y < 650 and 28 or 85
        local factor = math.min((size.X-margin*2)/w,(size.Y-topBottom)/h,1.1)
        entry.scale.Scale = math.max(0.25,factor)
    end
end
local viewportConnection
local function connectCamera()
    if viewportConnection then viewportConnection:Disconnect() end
    local cam = workspace.CurrentCamera
    if cam then
        viewportConnection = cam:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    end
    resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera)
connectCamera()

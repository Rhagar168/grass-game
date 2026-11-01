-- One owner for window scaling; no nested competing UIScales.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = script.Parent
local windows = {
    ToolsMenu = "large", IndexMenu = "large",
    ProfileMenu = "large", InventoryWindow = "large",
    SettingsMenu = "small", TeleportMenu = "small",
    DailyRewardsMenu = "small",
}
local RED = Color3.fromRGB(196,48,62)
local BG = Color3.fromRGB(18,27,23)
local entries = {}
local function install(frame, kind)
    if not frame or not frame:IsA("GuiObject") then return end
    -- Disable the old Tools-only viewport controller. It fights with the shared one.
    local old = frame:FindFirstChild("ResponsiveController")
    if old and old:IsA("LocalScript") then old.Enabled = false end
    -- Existing Studio-authored UIScales must not multiply the shared scale.
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("UIScale") and child.Name ~= "UnifiedResponsiveScale" then
            child.Scale = 1
            child.Enabled = false
        end
    end
    local scale = frame:FindFirstChild("UnifiedResponsiveScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Name = "UnifiedResponsiveScale"
        scale.Parent = frame
    end
    scale.Scale = 1
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.fromScale(0.5,0.5)
    frame.BackgroundColor3 = BG
    local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,12)
    corner.Parent = frame
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("TextButton") and child.Name:lower():find("close") then
            child.BackgroundColor3 = RED
            child.TextColor3 = Color3.new(1,1,1)
        end
    end
    table.insert(entries,{frame=frame,scale=scale,kind=kind})
end
for name, kind in pairs(windows) do install(gui:FindFirstChild(name),kind) end
task.spawn(function()
    local shop = player:WaitForChild("PlayerGui"):WaitForChild("GamepassShop",15)
    local outer = shop and shop:FindFirstChild("Frame")
    local panel = outer and outer:FindFirstChild("Panel")
    if panel then install(panel,"small") end
end)
local function update()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local viewport = cam.ViewportSize
    local marginX = viewport.X < 900 and 12 or 40
    local marginY = viewport.Y < 550 and 12 or 55
    for _, entry in ipairs(entries) do
        local frame = entry.frame
        if frame.Parent then
            -- AbsoluteSize includes UIScale; divide by its previous scale to
            -- recover the authored canvas size. Do not resize inner elements.
            local previous = math.max(entry.scale.Scale,0.001)
            local width = frame.AbsoluteSize.X / previous
            local height = frame.AbsoluteSize.Y / previous
            if width > 0 and height > 0 then
                local fit = math.min((viewport.X - 2*marginX)/width,
                    (viewport.Y - 2*marginY)/height,1)
                entry.scale.Scale = math.clamp(fit,0.08,1)
            end
        end
    end
end
local cameraConnection
local function connectCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    local cam = workspace.CurrentCamera
    if cam then
        cameraConnection = cam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
    end
    task.defer(update)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera)
connectCamera()

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

-- Responsive content arrangement: retain the desktop-authored positions for restoration.
local saved = setmetatable({}, {__mode="k"})
local function move(object, pos, size)
    if not object or not object:IsA("GuiObject") then return end
    if not saved[object] then
        saved[object] = {position=object.Position,size=object.Size,anchor=object.AnchorPoint}
    end
    object.AnchorPoint = Vector2.new(0,0)
    object.Position = pos
    object.Size = size
end
local function restore(object)
    local old = object and saved[object]
    if old then
        object.Position = old.position
        object.Size = old.size
        object.AnchorPoint = old.anchor
    end
end
local function toolsLayout(frame, compact)
    local list = frame:FindFirstChild("ToolList")
    local details = frame:FindFirstChild("ToolDetails")
    local top = frame:FindFirstChild("TopBar")
    if not list or not details then return end
    local stats = details:FindFirstChild("Stats")
    local upgrades = details:FindFirstChild("Upgrades")
    local equip = details:FindFirstChild("EquipButton")
    local icon = details:FindFirstChild("ToolIcon")
    local name = details:FindFirstChild("ToolName")
    local status = details:FindFirstChild("ToolStatus")
    local objects = {list,details,top,stats,upgrades,equip,icon,name,status}
    if not compact then
        for _,obj in ipairs(objects) do restore(obj) end
        return
    end
    -- Keep all panels within the original canvas so their existing button
    -- handlers, list items, stats and upgrade logic remain untouched.
    move(top, UDim2.fromScale(0.02,0.01), UDim2.fromScale(0.96,0.15))
    move(list, UDim2.fromScale(0.025,0.18), UDim2.fromScale(0.31,0.79))
    move(details, UDim2.fromScale(0.35,0.18), UDim2.fromScale(0.625,0.79))
    move(icon, UDim2.fromScale(0.02,0.01), UDim2.fromScale(0.20,0.22))
    move(name, UDim2.fromScale(0.24,0.01), UDim2.fromScale(0.74,0.13))
    move(status, UDim2.fromScale(0.24,0.14), UDim2.fromScale(0.74,0.10))
    move(stats, UDim2.fromScale(0.02,0.26), UDim2.fromScale(0.96,0.22))
    move(upgrades, UDim2.fromScale(0.02,0.50), UDim2.fromScale(0.96,0.37))
    move(equip, UDim2.fromScale(0.20,0.89), UDim2.fromScale(0.60,0.10))
    if list:IsA("ScrollingFrame") then
        list.ScrollingEnabled = true
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end
    if upgrades and upgrades:IsA("ScrollingFrame") then
        upgrades.ScrollingEnabled = true
        upgrades.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end
end

local function install(frame, kind)
    if not frame or not frame:IsA("GuiObject") then return end
    -- Disable the old Tools-only viewport controller. It fights with the shared one.
    local old = frame:FindFirstChild("ResponsiveController")
    if old and old:IsA("LocalScript") then old.Enabled = false end
    -- Existing Studio-authored UIScales must not multiply the shared scale.
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("UIScale") and child.Name ~= "UnifiedResponsiveScale" then
            child.Scale = 1
            -- UIScale has no Enabled property; neutralize its multiplier instead.
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
    local compact = viewport.X < 900 or viewport.Y < 500
    local marginX = compact and 12 or 40
    local marginY = compact and 12 or 55
    for _, entry in ipairs(entries) do
        local frame = entry.frame
        if frame.Parent then
            if frame.Name == "ToolsMenu" then toolsLayout(frame,false) end
            -- AbsoluteSize includes UIScale; divide by its previous scale to
            -- recover the authored canvas size. Do not resize inner elements.
            local previous = math.max(entry.scale.Scale,0.001)
            local width = frame.AbsoluteSize.X / previous
            local height = frame.AbsoluteSize.Y / previous
            if width > 0 and height > 0 then
                local fit = math.min((viewport.X - 2*marginX)/width,
                    (viewport.Y - 2*marginY)/height,1)
                entry.scale.Scale = math.clamp(fit * (compact and 0.78 or 1),0.08,1)
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

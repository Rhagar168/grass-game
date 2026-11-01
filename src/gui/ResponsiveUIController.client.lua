-- Central responsive controller. Managed by Rojo; do not install a second copy.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = script.Parent
local names = {
    ToolsMenu = true, IndexMenu = true, ProfileMenu = true,
    InventoryWindow = true, SettingsMenu = true,
    TeleportMenu = true, DailyRewardsMenu = true,
}
local hudNames = {
    "CoinsHUD", "ResetTokensHUD", "GrassCoresHUD", "BackpackHUD",
    "XPFrame", "BottomMenu", "RightMenu", "DailyQuestsMenu",
}
local entries = {}
local hud = {}
local cameraConnection
local function prepare(frame)
    if not frame or not frame:IsA("GuiObject") then return end
    local legacy = frame:FindFirstChild("ResponsiveController")
    if legacy and legacy:IsA("LocalScript") then legacy.Enabled = false end
    local scale = frame:FindFirstChild("ResponsiveScale")
        or frame:FindFirstChild("UnifiedResponsiveScale")
        or Instance.new("UIScale")
    scale.Name = "ResponsiveScale"
    scale.Parent = frame
    for _, item in ipairs(frame:GetChildren()) do
        if item:IsA("UIScale") and item ~= scale then
            item.Scale = 1
        end
    end
    -- Keep original Position and AnchorPoint: opening animations depend on them.
    table.insert(entries, {frame=frame, scale=scale})
end
for name in pairs(names) do
    prepare(gui:FindFirstChild(name))
end
for _, name in ipairs(hudNames) do
    local obj = gui:FindFirstChild(name)
    if obj and obj:IsA("GuiObject") then
        local scale = obj:FindFirstChild("HUDResponsiveScale") or Instance.new("UIScale")
        scale.Name = "HUDResponsiveScale"
        scale.Parent = obj
        hud[name] = {
            object=obj, scale=scale,
            position=obj.Position, anchor=obj.AnchorPoint,
        }
    end
end
local function update()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local v = camera.ViewportSize
    if v.X <= 0 or v.Y <= 0 then return end
    local compact = v.X < 950 or v.Y < 550
    local margin = compact and 14 or 48
    for _, entry in ipairs(entries) do
        local frame = entry.frame
        if frame.Parent then
            -- Calculate unscaled canvas from UDim2, not AbsoluteSize:
            -- avoids feedback from an existing UIScale.
            local width = frame.Size.X.Scale * v.X + frame.Size.X.Offset
            local height = frame.Size.Y.Scale * v.Y + frame.Size.Y.Offset
            if width > 0 and height > 0 then
                local fit = math.min((v.X-2*margin)/width,(v.Y-2*margin)/height,1)
                entry.scale.Scale = math.clamp(fit*(compact and 0.78 or 1),0.08,1)
            end
        end
    end
    for name, data in pairs(hud) do
        data.scale.Scale = compact and (v.Y < 400 and 0.5 or 0.7) or 1
        data.object.Position = data.position
        data.object.AnchorPoint = data.anchor
    end
    if compact then
        local bottom = hud.BottomMenu
        if bottom then
            bottom.object.AnchorPoint = Vector2.new(0.5,1)
            bottom.object.Position = UDim2.fromScale(0.5,0.98)
        end
        local xp = hud.XPFrame
        if xp then
            xp.object.AnchorPoint = Vector2.new(0.5,1)
            xp.object.Position = UDim2.fromScale(0.5,0.80)
        end
        local backpack = hud.BackpackHUD
        if backpack then
            backpack.object.AnchorPoint = Vector2.new(0.5,0)
            backpack.object.Position = UDim2.fromScale(0.5,0.07)
        end
    end
end
local function connectCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    if camera then
        cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
    end
    task.defer(update)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera)
connectCamera()
print("[ResponsiveUI] Rojo controller active")

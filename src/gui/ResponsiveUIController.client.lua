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
local smallMenus = {TeleportMenu=true, DailyRewardsMenu=true, SettingsMenu=true}
local mobileOriginals = {}
local function prepare(frame)
    if not frame or not frame:IsA("GuiObject") then return end
    local legacy = frame:FindFirstChild("ResponsiveController")
    if legacy and legacy:IsA("LocalScript") then legacy.Enabled = false end
    -- Legacy menu controllers animate MenuScale. Never rename or delete it.
    local menuScale = frame:FindFirstChild("MenuScale")
    if not menuScale then
        menuScale = Instance.new("UIScale")
        menuScale.Name = "MenuScale"
        menuScale.Scale = 1
        menuScale.Parent = frame
    end
    local scale = frame:FindFirstChild("ResponsiveScale")
    if not scale then
        scale = frame:FindFirstChild("UnifiedResponsiveScale")
        if scale then
            scale.Name = "ResponsiveScale"
        else
            scale = Instance.new("UIScale")
            scale.Name = "ResponsiveScale"
            scale.Parent = frame
        end
    end
    -- Neutralize only obsolete extra scales; leave MenuScale animations alone.
    for _, item in ipairs(frame:GetChildren()) do
        if item:IsA("UIScale") and item ~= scale and item ~= menuScale then
            item.Scale = 1
        end
    end
    -- Do not clip buttons/cards that extend past the original panel bounds.
    frame.ClipsDescendants = false
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") and not child:IsA("ScrollingFrame") then
            child.ClipsDescendants = false
        end
    end
    -- Keep original Position and AnchorPoint: opening animations depend on them.
    local emergencyClose = frame:FindFirstChild("MobileCloseButton")
    if not emergencyClose then
        emergencyClose = Instance.new("TextButton")
        emergencyClose.Name = "MobileCloseButton"
        emergencyClose.AnchorPoint = Vector2.new(1, 0)
        emergencyClose.Position = UDim2.new(1, -5, 0, 5)
        emergencyClose.Size = UDim2.fromOffset(36, 32)
        emergencyClose.BackgroundColor3 = Color3.fromRGB(192, 48, 62)
        emergencyClose.TextColor3 = Color3.new(1, 1, 1)
        emergencyClose.Text = "X"
        emergencyClose.TextScaled = true
        emergencyClose.Font = Enum.Font.GothamBold
        emergencyClose.ZIndex = 100
        emergencyClose.Visible = false
        emergencyClose.Parent = frame
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = emergencyClose
        emergencyClose.Activated:Connect(function()
            frame.Visible = false
            if frame.Name == "ToolsMenu" then
                player:SetAttribute("ToolsMenuOpen", false)
            elseif frame.Name == "IndexMenu" then
                player:SetAttribute("IndexMenuOpen", false)
            elseif frame.Name == "InventoryWindow" then
                player:SetAttribute("InventoryMenuOpen", false)
            end
            local bottom = gui:FindFirstChild("BottomMenu")
            if bottom then bottom.Visible = true end
            local xp = gui:FindFirstChild("XPFrame")
            if xp then xp.Visible = true end
            local right = gui:FindFirstChild("RightMenu")
            if right then right.Visible = true end
        end)
    end
    table.insert(entries, {frame=frame, scale=scale, close=emergencyClose,
        originalPosition=frame.Position, originalAnchor=frame.AnchorPoint, originalSize=frame.Size})
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
-- Keep authored sizes for restoration on desktop.
local gamepassIcons = {}
local rightMenu = gui:FindFirstChild("RightMenu")
if rightMenu then
    for _, item in ipairs(rightMenu:GetDescendants()) do
        if item:IsA("GuiButton") or item:IsA("ImageLabel") then
            -- Right-side shop/gamepass icons, excluding nested decorations.
            if item.Parent == rightMenu or item.Name:lower():find("gamepass") then
                local scale = item:FindFirstChild("MobileIconScale") or Instance.new("UIScale")
                scale.Name = "MobileIconScale"
                scale.Parent = item
                table.insert(gamepassIcons, scale)
            end
        end
    end
end
local currencyNames = {"CoinsHUD", "ResetTokensHUD", "GrassCoresHUD"}
local currencyPositions = {}
for _, name in ipairs(currencyNames) do
    local item = gui:FindFirstChild(name)
    if item and item:IsA("GuiObject") then
        currencyPositions[name] = item.Position
    end
end
-- Shop lives in a separate ScreenGui, so it needs its own mobile close button.
local shopPanel
local shopOriginal
local shopClose
task.spawn(function()
    local shop = player:WaitForChild("PlayerGui"):WaitForChild("GamepassShop", 20)
    local outer = shop and shop:FindFirstChild("Frame")
    local panel = outer and outer:FindFirstChild("Panel")
    if not panel or not panel:IsA("GuiObject") then return end
    shopPanel = panel
    shopOriginal = {size=panel.Size, position=panel.Position, anchor=panel.AnchorPoint}
    shopClose = panel:FindFirstChild("MobileCloseButton")
    if not shopClose then
        shopClose = Instance.new("TextButton")
        shopClose.Name = "MobileCloseButton"
        shopClose.AnchorPoint = Vector2.new(1,0)
        shopClose.Position = UDim2.new(1,-8,0,8)
        shopClose.Size = UDim2.fromOffset(42,42)
        shopClose.Text = "X"
        shopClose.TextScaled = true
        shopClose.Font = Enum.Font.GothamBold
        shopClose.BackgroundColor3 = Color3.fromRGB(192,48,62)
        shopClose.TextColor3 = Color3.new(1,1,1)
        shopClose.ZIndex = 100
        shopClose.Parent = panel
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0,7)
        corner.Parent = shopClose
        shopClose.Activated:Connect(function()
            -- Hide only the shop window; keep ScreenGui enabled so shop icons remain.
            if outer and outer:IsA("GuiObject") then
                outer.Visible = false
            else
                panel.Visible = false
            end
        end)
    end
    local scroll = panel:FindFirstChildWhichIsA("ScrollingFrame", true)
    if scroll then
        scroll.ScrollingEnabled = true
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollBarThickness = 5
    end
    if workspace.CurrentCamera then
        -- Viewport resize callback will handle layout; initialize immediately.
        local v = workspace.CurrentCamera.ViewportSize
        local compact = v.X < 950 or v.Y < 550
        shopClose.Visible = compact
        if compact then
            panel.AnchorPoint = Vector2.new(0.5,0.5)
            panel.Position = UDim2.fromScale(0.5,0.5)
            panel.Size = UDim2.new(1,-20,1,-20)
        end
    end
end)
local function enableScrolling()
    local tools = gui:FindFirstChild("ToolsMenu")
    local details = tools and tools:FindFirstChild("ToolDetails")
    local upgrades = details and details:FindFirstChild("Upgrades")
    if upgrades and upgrades:IsA("ScrollingFrame") then
        upgrades.ScrollingEnabled = true
        upgrades.AutomaticCanvasSize = Enum.AutomaticSize.Y
        upgrades.ScrollBarThickness = 5
    end
    local inventory = gui:FindFirstChild("InventoryWindow")
    local pets = inventory and inventory:FindFirstChild("PetsContent")
    if pets then
        for _, name in ipairs({"EquippedPets","PetList"}) do
            local list = pets:FindFirstChild(name)
            if list and list:IsA("ScrollingFrame") then
                list.ScrollingEnabled = true
                list.AutomaticCanvasSize = Enum.AutomaticSize.Y
                list.ScrollBarThickness = 5
            end
        end
    end
end
enableScrolling()
local function update()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local v = camera.ViewportSize
    if v.X <= 0 or v.Y <= 0 then return end
    local compact = v.X < 950 or v.Y < 550
    local tiny = v.Y < 400
    local margin = compact and 14 or 48
    for _, entry in ipairs(entries) do
        local frame = entry.frame
        if frame.Parent then
            entry.close.Visible = compact
            if compact then
                -- Fullscreen mobile canvas. Existing child Scale coordinates
                -- now have a usable viewport instead of a tiny parent.
                frame.AnchorPoint = Vector2.new(0.5, 0.5)
                frame.Position = UDim2.fromScale(0.5, 0.5)
                frame.Size = UDim2.new(1, -20, 1, -20)
                entry.scale.Scale = 1
                entry.close.Size = UDim2.fromOffset(42, 42)
                entry.close.Position = UDim2.new(1, -8, 0, 8)
            else
                frame.Size = entry.originalSize
                frame.AnchorPoint = entry.originalAnchor
                frame.Position = entry.originalPosition
                entry.scale.Scale = 1
            end
        end
    end
    for _, iconScale in ipairs(gamepassIcons) do
        if iconScale.Parent then
            iconScale.Scale = compact and (tiny and 0.60 or 0.72) or 1
        end
    end
    for name, data in pairs(hud) do
        data.scale.Scale = compact and (tiny and 0.38 or 0.62) or 1
        data.object.Position = data.position
        data.object.AnchorPoint = data.anchor
    end
    if compact then
        local bottom = hud.BottomMenu
        if bottom then
            bottom.object.AnchorPoint = Vector2.new(0.5,1)
            bottom.object.Position = UDim2.fromScale(0.5,0.99)
        end
        local xp = hud.XPFrame
        if xp then
            xp.object.AnchorPoint = Vector2.new(0.5,1)
            xp.object.Position = UDim2.fromScale(0.5,0.84)
        end
        local backpack = hud.BackpackHUD
        if backpack then
            backpack.object.AnchorPoint = Vector2.new(0.5,0)
            backpack.object.Position = UDim2.fromScale(0.5,0.07)
        end
    end
    -- Tight currency stack at the left edge on narrow screens.
    if compact then
        local visibleIndex = 0
        for _, name in ipairs(currencyNames) do
            local item = gui:FindFirstChild(name)
            if item and item:IsA("GuiObject") and item.Visible then
                item.AnchorPoint = Vector2.new(0, 0)
                item.Position = UDim2.new(0, 12, 0.30, visibleIndex * (tiny and 31 or 43))
                visibleIndex += 1
            end
        end
    else
        for name, position in pairs(currencyPositions) do
            local item = gui:FindFirstChild(name)
            if item then item.Position = position end
        end
    end
    if shopPanel and shopOriginal and shopClose then
        shopClose.Visible = compact
        if compact then
            shopPanel.AnchorPoint = Vector2.new(0.5,0.5)
            shopPanel.Position = UDim2.fromScale(0.5,0.5)
            shopPanel.Size = UDim2.new(1,-20,1,-20)
        else
            shopPanel.AnchorPoint = shopOriginal.anchor
            shopPanel.Position = shopOriginal.position
            shopPanel.Size = shopOriginal.size
        end
    end
    -- Mobile inventory content must stay inside its panel.
    local inventory = gui:FindFirstChild("InventoryWindow")
    if inventory then
        local pets = inventory:FindFirstChild("PetsContent")
        if pets and pets:IsA("GuiObject") then
            pets.ClipsDescendants = compact
        end
        for _, name in ipairs({"EquippedPets", "PetList"}) do
            local list = pets and pets:FindFirstChild(name)
            if list and list:IsA("ScrollingFrame") then
                list.ScrollingEnabled = true
                list.AutomaticCanvasSize = Enum.AutomaticSize.Y
            end
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

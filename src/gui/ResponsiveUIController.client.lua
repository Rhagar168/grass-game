-- Central responsive controller. Managed by Rojo; do not install a second copy.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
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
    -- Independent entrance tween: preserves each menu controller's own
    -- MenuScale animation while restoring a visible pop-in effect.
    local entrance = frame:FindFirstChild("OpenAnimationScale")
    if not entrance then
        entrance = Instance.new("UIScale")
        entrance.Name = "OpenAnimationScale"
        entrance.Scale = 1
        entrance.Parent = frame
    end
    -- Some menu controllers keep their Frame visible and toggle a parent
    -- container instead. Track effective visibility, not only frame.Visible.
    local entranceTween
    local wasShown = false
    local function effectivelyVisible()
        local node = frame
        while node and node ~= gui do
            if node:IsA("GuiObject") and not node.Visible then return false end
            if node:IsA("ScreenGui") and not node.Enabled then return false end
            node = node.Parent
        end
        return gui.Enabled
    end
    task.spawn(function()
        while frame.Parent do
            local shown = effectivelyVisible()
            if shown and not wasShown then
                if entranceTween then entranceTween:Cancel() end
                entrance.Scale = 0.76
                entranceTween = TweenService:Create(
                    entrance,
                    TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Scale = 1}
                )
                entranceTween:Play()
            elseif not shown and wasShown then
                if entranceTween then entranceTween:Cancel() end
                entrance.Scale = 1
            end
            wasShown = shown
            task.wait(0.035)
        end
    end)
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
    -- Use the shop's ORIGINAL CloseButton, which already has the
    -- game's open/close logic. Never create a second close handler.
    local obsolete = panel:FindFirstChild("MobileCloseButton")
    if obsolete then obsolete:Destroy() end
    shopClose = outer:FindFirstChild("CloseButton")
    if not shopClose or not shopClose:IsA("GuiButton") then
        warn("[ResponsiveUI] GamepassShop.Frame.CloseButton missing")
        return
    end
    local originalClose = {
        position = shopClose.Position,
        size = shopClose.Size,
        anchor = shopClose.AnchorPoint,
        zindex = shopClose.ZIndex,
    }
    shopClose:SetAttribute("ResponsiveOriginalZIndex", originalClose.zindex)
    shopClose:SetAttribute("ResponsiveOriginalPositionXScale", originalClose.position.X.Scale)
    shopClose:SetAttribute("ResponsiveOriginalPositionXOffset", originalClose.position.X.Offset)
    shopClose:SetAttribute("ResponsiveOriginalPositionYScale", originalClose.position.Y.Scale)
    shopClose:SetAttribute("ResponsiveOriginalPositionYOffset", originalClose.position.Y.Offset)
    shopClose:SetAttribute("ResponsiveOriginalSizeXScale", originalClose.size.X.Scale)
    shopClose:SetAttribute("ResponsiveOriginalSizeXOffset", originalClose.size.X.Offset)
    shopClose:SetAttribute("ResponsiveOriginalSizeYScale", originalClose.size.Y.Scale)
    shopClose:SetAttribute("ResponsiveOriginalSizeYOffset", originalClose.size.Y.Offset)
    shopClose:SetAttribute("ResponsiveOriginalAnchorX", originalClose.anchor.X)
    shopClose:SetAttribute("ResponsiveOriginalAnchorY", originalClose.anchor.Y)
    -- ShopCloseFixButton was installed in Studio. Use it on mobile only.
    local obsoleteMobile = panel:FindFirstChild("MobileCloseButton")
    if obsoleteMobile then obsoleteMobile:Destroy() end
    local mobileClose = panel:FindFirstChild("ShopCloseFixButton")
    if mobileClose and mobileClose:IsA("GuiButton") then mobileClose.Visible = false end
    local scroll = panel:FindFirstChildWhichIsA("ScrollingFrame", true)
    if scroll then
        scroll.ScrollingEnabled = true
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollBarThickness = 5
    end

end)
-- Outer sections own scrolling. Nested scrollbars must stay disabled.
local function configureSection(section, compact)
    if not section or not section:IsA("ScrollingFrame") then return end
    section.ScrollingEnabled = compact
    section.ScrollingDirection = Enum.ScrollingDirection.Y
    section.ScrollBarThickness = compact and 5 or 0
    section.AutomaticCanvasSize = Enum.AutomaticSize.None
    local controller = section:FindFirstChild("SectionCanvasController")
    if controller and controller:IsA("LocalScript") then
        controller.Enabled = compact
    end
    if not compact then
        section.CanvasPosition = Vector2.zero
        section.CanvasSize = UDim2.fromOffset(0,0)
    end
    for _, child in ipairs(section:GetDescendants()) do
        if child:IsA("ScrollingFrame") then
            child.ScrollingEnabled = false
            child.ScrollBarThickness = 0
            child.ClipsDescendants = false
        end
    end
end
local function enableScrolling(compact)
    local tools = gui:FindFirstChild("ToolsMenu")
    configureSection(tools and tools:FindFirstChild("ToolDetails"), compact)
    local inventory = gui:FindFirstChild("InventoryWindow")
    -- Inventory is scrollable on desktop too; cards can span multiple rows.
    configureSection(inventory and inventory:FindFirstChild("PetsContent"), true)
    local pets = inventory and inventory:FindFirstChild("PetsContent")
    local oldCanvas = pets and pets:FindFirstChild("SectionCanvasController")
    if oldCanvas and oldCanvas:IsA("LocalScript") then
        oldCanvas.Enabled = false -- InventoryController owns the canvas height.
    end
end
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
            iconScale.Scale = compact and (tiny and 0.48 or 0.60) or 1
        end
    end
    for name, data in pairs(hud) do
        local mobileScale = tiny and 0.55 or 0.70
        if name == "BottomMenu" then mobileScale = tiny and 0.67 or 0.82 end
        if name == "XPFrame" then mobileScale = tiny and 0.75 or 0.88 end
        if name == "RightMenu" then mobileScale = tiny and 0.48 or 0.60 end
        if name == "CoinsHUD" or name == "ResetTokensHUD" or name == "GrassCoresHUD" then
            mobileScale = tiny and 0.55 or 0.70
        end
        data.scale.Scale = compact and mobileScale or 1
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
            xp.object.Position = UDim2.fromScale(0.5,0.83)
        end
        local backpack = hud.BackpackHUD
        if backpack then
            backpack.object.AnchorPoint = Vector2.new(0.5,0)
            backpack.object.Position = UDim2.fromScale(0.5,0.07)
        end
    end
    -- Owned gamepass icons are in a separate ScreenGui, not RightMenu.
    local ownedScreen = player.PlayerGui:FindFirstChild("OwnedGamepassHUD")
    local ownedIcons = ownedScreen and ownedScreen:FindFirstChild("Icons")
    if ownedIcons and ownedIcons:IsA("GuiObject") then
        local ownedScale = ownedIcons:FindFirstChild("ResponsiveGamepassScale")
        if not ownedScale then
            ownedScale = Instance.new("UIScale")
            ownedScale.Name = "ResponsiveGamepassScale"
            ownedScale.Parent = ownedIcons
        end
        ownedScale.Scale = compact and (tiny and 0.58 or 0.72) or 1
    end
    -- Tight currency stack at the left edge on narrow screens.
    if compact then
        local visibleIndex = 0
        for _, name in ipairs(currencyNames) do
            local item = gui:FindFirstChild(name)
            if item and item:IsA("GuiObject") and item.Visible then
                item.AnchorPoint = Vector2.new(0, 0)
                -- Fixed top offsets keep all three currencies in one neat column.
                item.Position = UDim2.fromOffset(12, (tiny and 104 or 130) + visibleIndex * (tiny and 43 or 54))
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
        local shopFrame = shopPanel.Parent
        local mobileClose = shopPanel:FindFirstChild("ShopCloseFixButton")
        local oldMobile = shopPanel:FindFirstChild("MobileCloseButton")
        if oldMobile then oldMobile:Destroy() end
        if mobileClose and mobileClose:IsA("GuiButton") then
            mobileClose.Visible = compact
            mobileClose.AnchorPoint = Vector2.new(1,0)
            mobileClose.Position = UDim2.new(1,-8,0,8)
            mobileClose.Size = UDim2.fromOffset(42,42)
            mobileClose.ZIndex = 1000
        end
        shopClose.Visible = not compact
        if compact then
            shopPanel.AnchorPoint = Vector2.new(0.5,0.5)
            shopPanel.Position = UDim2.fromScale(0.5,0.5)
            shopPanel.Size = UDim2.new(1,-20,1,-20)
        else
            shopClose.AnchorPoint = Vector2.new(shopClose:GetAttribute("ResponsiveOriginalAnchorX") or 0, shopClose:GetAttribute("ResponsiveOriginalAnchorY") or 0)
            shopClose.Position = UDim2.new(shopClose:GetAttribute("ResponsiveOriginalPositionXScale") or 0,shopClose:GetAttribute("ResponsiveOriginalPositionXOffset") or 0,shopClose:GetAttribute("ResponsiveOriginalPositionYScale") or 0,shopClose:GetAttribute("ResponsiveOriginalPositionYOffset") or 0)
            shopClose.Size = UDim2.new(shopClose:GetAttribute("ResponsiveOriginalSizeXScale") or 0,shopClose:GetAttribute("ResponsiveOriginalSizeXOffset") or 0,shopClose:GetAttribute("ResponsiveOriginalSizeYScale") or 0,shopClose:GetAttribute("ResponsiveOriginalSizeYOffset") or 0)
            shopClose.ZIndex = shopClose:GetAttribute("ResponsiveOriginalZIndex") or 1
            shopPanel.AnchorPoint = shopOriginal.anchor
            shopPanel.Position = shopOriginal.position
            shopPanel.Size = shopOriginal.size
        end
    end
    -- Shop: the whole scrollable catalogue must fit the mobile panel.
    if shopPanel then
        local catalogue = shopPanel:FindFirstChild("Scroll", true)
        if catalogue and catalogue:IsA("ScrollingFrame") then
            catalogue.ScrollingEnabled = true
            catalogue.AutomaticCanvasSize = Enum.AutomaticSize.Y
            catalogue.ScrollBarThickness = 4
        end
        -- Hide duplicate close buttons; Studio's ShopCloseFix owns mobile close.
        local mobileClose = shopPanel:FindFirstChild("ShopCloseFixButton")
        local outer = shopPanel.Parent
        local originalClose = outer and outer:FindFirstChild("CloseButton")
        if originalClose and originalClose:IsA("GuiButton") then
            originalClose.Visible = not compact
        end
        if mobileClose and mobileClose:IsA("GuiButton") then
            mobileClose.Visible = compact
        end
    end
    -- Daily rewards: scale the card strip and allow sideways browsing on phones.
    local rewards = gui:FindFirstChild("DailyRewardsMenu")
    if rewards then
        local rewardsScroll = rewards:FindFirstChildWhichIsA("ScrollingFrame", true)
        if rewardsScroll then
            if compact then
                rewardsScroll.ScrollingEnabled = true
                rewardsScroll.ScrollingDirection = Enum.ScrollingDirection.XY
                rewardsScroll.ScrollBarThickness = 4
                rewardsScroll.ClipsDescendants = true
                rewardsScroll.Size = UDim2.new(1,-24,1,-105)
                rewardsScroll.Position = UDim2.fromOffset(12,88)
            end
        end
        -- Keep only the mobile close button on narrow screens.
        local mobileX = rewards:FindFirstChild("MobileCloseButton")
        local topbar = rewards:FindFirstChild("TopBar")
        local originalX = topbar and topbar:FindFirstChild("CloseButton")
        if compact and mobileX and originalX and originalX:IsA("GuiButton") then
            originalX.Visible = false
        elseif not compact and originalX and originalX:IsA("GuiButton") then
            originalX.Visible = true
        end
    end
    enableScrolling(compact)
    -- Mobile inventory content must stay inside its panel.
    local inventory = gui:FindFirstChild("InventoryWindow")
    if inventory then
        local pets = inventory:FindFirstChild("PetsContent")
        if pets and pets:IsA("GuiObject") then
            pets.ClipsDescendants = compact
        end
        -- Nested lists are content only; the whole PetsContent scrolls.
        for _, name in ipairs({"EquippedPets", "PetList"}) do
            local list = pets and pets:FindFirstChild(name)
            if list and list:IsA("ScrollingFrame") then
                list.ScrollingEnabled = false
                list.ScrollBarThickness = 0
                list.ClipsDescendants = false
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

-- Hide HUD, gamepass icons and daily quests while ANY full menu is open.
-- Keep the menu itself visible; restore previous HUD visibility on close.
local RunService = game:GetService("RunService")
local hiddenWhileMenuOpen = {
    "BottomMenu", "RightMenu", "XPFrame", "DailyQuestsMenu",
    "CoinsHUD", "ResetTokensHUD", "GrassCoresHUD", "BackpackHUD",
}
local trackedVisibility = {}
local overlayActive = false
-- Left-side gamepass icons are in their own ScreenGui, not MainUI.
local function getGamepassHudParts()
    local screen = player.PlayerGui:FindFirstChild("OwnedGamepassHUD")
    if not screen or not screen:IsA("ScreenGui") then return nil, nil end
    return screen:FindFirstChild("Icons"), screen:FindFirstChild("GamepassTooltip")
end
local function isAnyMenuOpen()
    for name in pairs(names) do
        local window = gui:FindFirstChild(name)
        if window and window:IsA("GuiObject") and window.Visible then
            return true
        end
    end
    for _, name in ipairs({"UpgradeMenu", "CoreLabMenu", "DailyQuestsMenu"}) do
        if name ~= "DailyQuestsMenu" then
            local window = gui:FindFirstChild(name)
            if window and window:IsA("GuiObject") and window.Visible then
                return true
            end
        end
    end
    local shop = player.PlayerGui:FindFirstChild("GamepassShop")
    local frame = shop and shop:FindFirstChild("Frame")
    if shop and shop.Enabled and frame and frame:IsA("GuiObject") and frame.Visible then
        return true
    end
    return false
end
local function syncMenuHud()
    local open = isAnyMenuOpen()
    if open and not overlayActive then
        table.clear(trackedVisibility)
        for _, name in ipairs(hiddenWhileMenuOpen) do
            local obj = gui:FindFirstChild(name)
            if obj and obj:IsA("GuiObject") then
                trackedVisibility[obj] = obj.Visible
            end
        end
        local icons, tooltip = getGamepassHudParts()
        for _, obj in ipairs({icons, tooltip}) do
            if obj and obj:IsA("GuiObject") then
                trackedVisibility[obj] = obj.Visible
            end
        end
        overlayActive = true
    end
    if open then
        for _, name in ipairs(hiddenWhileMenuOpen) do
            local obj = gui:FindFirstChild(name)
            if obj and obj:IsA("GuiObject") then obj.Visible = false end
        end
        local icons, tooltip = getGamepassHudParts()
        if icons and icons:IsA("GuiObject") then icons.Visible = false end
        if tooltip and tooltip:IsA("GuiObject") then tooltip.Visible = false end
    elseif overlayActive then
        overlayActive = false
        for obj, visible in pairs(trackedVisibility) do
            if obj.Parent then obj.Visible = visible end
        end
        -- Some menu controllers hide HUD before our first visibility snapshot.
        -- Restore the persistent navigation HUD unconditionally on last close.
        for _, name in ipairs({"BottomMenu", "RightMenu", "XPFrame", "DailyQuestsMenu"}) do
            local obj = gui:FindFirstChild(name)
            if obj and obj:IsA("GuiObject") then obj.Visible = true end
        end
        local icons = getGamepassHudParts()
        if icons and icons:IsA("GuiObject") then icons.Visible = true end
        table.clear(trackedVisibility)
    end
end
local visibilityElapsed = 0
RunService.Heartbeat:Connect(function(dt)
    visibilityElapsed += dt
    if visibilityElapsed < 0.08 then return end
    visibilityElapsed = 0
    syncMenuHud()
end)

print("[ResponsiveUI] Rojo controller active")

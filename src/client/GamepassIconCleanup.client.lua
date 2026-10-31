-- Remove square frames from the existing gamepass shortcut icons.
-- The Shop handles its own icon styling.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local config = require(ReplicatedStorage:WaitForChild("GamepassConfig"))

local ids = {}
for _, pass in pairs(config.Passes) do
    ids[tostring(pass.Id)] = true
end

local function isPassThumbnail(image)
    if not (image:IsA("ImageLabel") or image:IsA("ImageButton")) then return false end
    local asset = image.Image or ""
    local id = asset:match("[?&]id=(%d+)")
    return id ~= nil and ids[id] == true
end

local function addGentleHover(image)
    if image:GetAttribute("GamepassGentleHover") then return end
    image:SetAttribute("GamepassGentleHover", true)

    local target = image
    local trigger = image
    if image.Parent and (image.Parent:IsA("ImageButton") or image.Parent:IsA("TextButton")) then
        trigger = image.Parent
    end

    local scale = target:FindFirstChild("GamepassHoverScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Name = "GamepassHoverScale"
        scale.Scale = 1
        scale.Parent = target
    end
    local tween
    local function animate(value)
        if tween then tween:Cancel() end
        tween = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Scale = value
        })
        tween:Play()
    end
    trigger.MouseEnter:Connect(function() animate(1.06) end)
    trigger.MouseLeave:Connect(function() animate(1) end)
end

local function clean(image)
    if not isPassThumbnail(image) or image:FindFirstAncestor("GamepassShop") then return end
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    addGentleHover(image)
    for _, child in ipairs(image:GetChildren()) do
        if child:IsA("UIStroke") then child:Destroy() end
    end
    -- Shortcut buttons wrap a thumbnail; remove their colored square too.
    local parent = image.Parent
    if parent and (parent:IsA("ImageButton") or parent:IsA("TextButton")) then
        parent.BackgroundTransparency = 1
        parent.BorderSizePixel = 0
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("UIStroke") then child:Destroy() end
        end
    end
end

for _, descendant in ipairs(playerGui:GetDescendants()) do
    clean(descendant)
end
playerGui.DescendantAdded:Connect(function(descendant)
    task.defer(function()
        if descendant.Parent then clean(descendant) end
    end)
end)

-- Compact the six gamepass shortcuts and move the row slightly lower.
-- Work on their shared layout instead of moving thumbnails away from click targets.
local function adjustShortcutRow()
    local groups = {}
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if isPassThumbnail(obj) and not obj:FindFirstAncestor("GamepassShop") then
            local holder = obj.Parent
            if holder and (holder:IsA("ImageButton") or holder:IsA("TextButton")) then
                holder = holder.Parent
            end
            if holder and holder:IsA("GuiObject") then
                groups[holder] = (groups[holder] or 0) + 1
            end
        end
    end
    for holder, count in pairs(groups) do
        if count >= 3 and not holder:GetAttribute("GamepassRowAdjusted") then
            holder:SetAttribute("GamepassRowAdjusted", true)
            local layout = holder:FindFirstChildOfClass("UIListLayout")
            if layout then
                layout.Padding = UDim.new(0, 3)
            end
            holder.Position = UDim2.new(
                holder.Position.X.Scale, holder.Position.X.Offset,
                holder.Position.Y.Scale, holder.Position.Y.Offset + 14
            )
        end
    end
end

task.defer(adjustShortcutRow)
playerGui.DescendantAdded:Connect(function()
    task.defer(adjustShortcutRow)
end)

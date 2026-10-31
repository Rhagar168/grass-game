-- Remove square frames from the existing gamepass shortcut icons.
-- The Shop handles its own icon styling.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local function clean(image)
    if not isPassThumbnail(image) or image:FindFirstAncestor("GamepassShop") then return end
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
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

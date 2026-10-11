-- EggHatchAnimation.client.lua
-- Visual-only hatch animation. Fire ReplicatedStorage.PetHatched to this client
-- with a pet ID after the server has awarded the pet.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PetConfig = require(RS:WaitForChild("PetConfig"))
local player = Players.LocalPlayer
local models = RS:WaitForChild("PetModels")
local hatchEvent = RS:WaitForChild("PetHatched")
local colors = {
    Common = Color3.fromRGB(200, 215, 220),
    Rare = Color3.fromRGB(65, 170, 255),
    Epic = Color3.fromRGB(188, 90, 255),
    Legendary = Color3.fromRGB(255, 190, 45),
    Mythic = Color3.fromRGB(255, 80, 165),
}
local gui = Instance.new("ScreenGui")
gui.Name = "EggHatchAnimation"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.BackgroundColor3 = Color3.fromRGB(6, 10, 20)
overlay.BackgroundTransparency = 1
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Parent = gui

local viewport = Instance.new("ViewportFrame")
viewport.AnchorPoint = Vector2.new(0.5, 0.5)
viewport.Position = UDim2.fromScale(0.5, 0.47)
viewport.Size = UDim2.fromScale(0.48, 0.65)
viewport.BackgroundTransparency = 1
viewport.Parent = overlay
local camera = Instance.new("Camera")
camera.Parent = viewport
viewport.CurrentCamera = camera
local world = Instance.new("WorldModel")
world.Parent = viewport

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.79)
title.Size = UDim2.fromScale(0.7, 0.07)
title.BackgroundTransparency = 1
title.Text = ""
title.TextColor3 = Color3.new(1, 1, 1)
title.TextStrokeTransparency = 0.15
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = overlay

local rarity = title:Clone()
rarity.Position = UDim2.fromScale(0.5, 0.855)
rarity.Size = UDim2.fromScale(0.55, 0.055)
rarity.Parent = overlay

local flash = Instance.new("Frame")
flash.BackgroundColor3 = Color3.fromRGB(255, 204, 98)
flash.BackgroundTransparency = 1
flash.Size = UDim2.fromScale(1, 1)
flash.ZIndex = 10
flash.Parent = overlay

local busy = false
local function tween(obj, duration, properties)
    local tw = TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tw:Play()
    return tw
end

-- Locate the actual Savanna egg already placed in Workspace/Eggs.
-- Prefer models / mesh parts whose name mentions Savanna or Egg.
local function eggModel()
    local folder = workspace:FindFirstChild("Eggs")
    if not folder then
        warn("[EggHatch] Workspace/Eggs missing")
        return nil
    end

    local candidates = {}
    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:IsA("Model") or descendant:IsA("MeshPart") then
            local name = descendant.Name:lower()
            local score = 0
            if name:find("savanna") then score += 20 end
            if name:find("egg") then score += 10 end
            if descendant:IsA("Model") then score += 5 end
            if score > 0 then
                table.insert(candidates, {object = descendant, score = score})
            end
        end
    end
    table.sort(candidates, function(x, y) return x.score > y.score end)
    local source = candidates[1] and candidates[1].object
    if not source then
        warn("[EggHatch] No egg model found in Workspace/Eggs")
        return nil
    end

    local clone = source:Clone()
    if clone:IsA("BasePart") then
        local wrapper = Instance.new("Model")
        clone.Parent = wrapper
        clone = wrapper
    end
    for _, item in ipairs(clone:GetDescendants()) do
        if item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanQuery = false
            item.CanTouch = false
        elseif item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ProximityPrompt") or item:IsA("BillboardGui") or item:IsA("SurfaceGui") then
            item:Destroy()
        end
    end
    return clone
end

local function normalize(model, targetSize)
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
        elseif obj:IsA("BillboardGui") then
            obj:Destroy()
        end
    end
    local bounds, size = model:GetBoundingBox()
    local largest = math.max(size.X, size.Y, size.Z)
    if largest > 0.001 then
        model:ScaleTo(model:GetScale() * (targetSize / largest))
    end
    -- Center imported Blender geometry even when its pivot is offset.
    bounds = model:GetBoundingBox()
    local pivotToBounds = model:GetPivot():ToObjectSpace(bounds)
    model:PivotTo(pivotToBounds:Inverse())
end

local function hatch(id)
    if busy then return end
    local config = PetConfig.GetPet(id)
    if not config then return end
    busy = true
    world:ClearAllChildren()
    overlay.Visible = true
    overlay.BackgroundTransparency = 1
    title.Text = ""
    rarity.Text = ""
    flash.BackgroundTransparency = 1
    camera.CFrame = CFrame.lookAt(Vector3.new(0, 1.1, 9), Vector3.new(0, 0, 0))
    tween(overlay, 0.2, {BackgroundTransparency = 0.25})

    local egg = eggModel()
    if egg then
        egg.Parent = world
        normalize(egg, 3.5)
    end
    local start = os.clock()
    while os.clock() - start < 1.7 do
        local t = os.clock() - start
        local intensity = math.clamp(t / 1.7, 0, 1)
        local shake = math.sin(t * (12 + intensity * 24)) * intensity * 0.22
        if egg then
            egg:PivotTo(CFrame.new(0, math.abs(math.sin(t * 6)) * 0.12, 0) * CFrame.Angles(0, 0, shake))
        end
        RunService.RenderStepped:Wait()
    end
    flash.BackgroundTransparency = 0.82
    if egg then egg:Destroy() end
    local template = models:FindFirstChild(id)
    if template and template:IsA("Model") then
        local pet = template:Clone()
        pet.Parent = world
        normalize(pet, 3.4)
        local t0 = os.clock()
        while os.clock() - t0 < 0.55 do
            local t = math.clamp((os.clock() - t0) / 0.55, 0, 1)
            local scale = 0.3 + 0.7 * (1 - (1-t)^3)
            pet:ScaleTo(scale)
            -- Blender pet faces point toward local -Z; camera looks from +Z.
            pet:PivotTo(CFrame.Angles(0, math.pi + math.rad(12) * math.sin(t * math.pi), 0))
            RunService.RenderStepped:Wait()
        end
    end
    title.Text = config.DisplayName
    rarity.Text = config.Rarity
    rarity.TextColor3 = colors[config.Rarity] or Color3.new(1, 1, 1)
    tween(flash, 0.25, {BackgroundTransparency = 1})
    task.wait(1.8)
    tween(overlay, 0.35, {BackgroundTransparency = 1})
    task.wait(0.36)
    overlay.Visible = false
    busy = false
end

hatchEvent.OnClientEvent:Connect(hatch)
-- Studio preview: press H to test a Savanna Cub without granting a pet.
if RunService:IsStudio() then
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.H then
            task.spawn(hatch, "SavannaCub")
        end
    end)
end

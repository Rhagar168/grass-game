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
flash.BackgroundColor3 = Color3.new(1, 1, 1)
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

local function eggModel()
    local model = Instance.new("Model")
    model.Name = "Egg"
    local shell = Instance.new("Part")
    shell.Name = "Shell"
    shell.Shape = Enum.PartType.Ball
    shell.Size = Vector3.new(2.7, 3.5, 2.7)
    shell.Color = Color3.fromRGB(255, 203, 86)
    shell.Material = Enum.Material.SmoothPlastic
    shell.Anchored = true
    shell.Parent = model
    local band = Instance.new("Part")
    band.Name = "Band"
    band.Shape = Enum.PartType.Ball
    band.Size = Vector3.new(2.77, 1.1, 2.77)
    band.Color = Color3.fromRGB(255, 152, 61)
    band.Anchored = true
    band.Parent = model
    return model
end

local function normalize(model)
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanCollide = false
        elseif obj:IsA("BillboardGui") then
            obj:Destroy()
        end
    end
    local cf, size = model:GetBoundingBox()
    local maxSize = math.max(size.X, size.Y, size.Z)
    if maxSize > 0 then
        model:ScaleTo(model:GetScale() * (3.4 / maxSize))
    end
    cf = model:GetBoundingBox()
    model:PivotTo(model:GetPivot() * cf:Inverse())
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
    egg.Parent = world
    local start = os.clock()
    while os.clock() - start < 1.7 do
        local t = os.clock() - start
        local intensity = math.clamp(t / 1.7, 0, 1)
        local shake = math.sin(t * (12 + intensity * 24)) * intensity * 0.22
        egg:PivotTo(CFrame.new(0, math.abs(math.sin(t * 6)) * 0.12, 0) * CFrame.Angles(0, 0, shake))
        RunService.RenderStepped:Wait()
    end
    flash.BackgroundTransparency = 0.05
    egg:Destroy()
    local template = models:FindFirstChild(id)
    if template and template:IsA("Model") then
        local pet = template:Clone()
        pet.Parent = world
        normalize(pet)
        local t0 = os.clock()
        while os.clock() - t0 < 0.55 do
            local t = math.clamp((os.clock() - t0) / 0.55, 0, 1)
            local scale = 0.3 + 0.7 * (1 - (1-t)^3)
            pet:ScaleTo(scale)
            pet:PivotTo(CFrame.Angles(0, math.rad(12) * math.sin(t * math.pi), 0))
            RunService.RenderStepped:Wait()
        end
    end
    title.Text = config.DisplayName
    rarity.Text = config.Rarity
    rarity.TextColor3 = colors[config.Rarity] or Color3.new(1, 1, 1)
    tween(flash, 0.45, {BackgroundTransparency = 1})
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

-- Consistent subtle hover and press feedback for GUI buttons.
-- Do not interfere with buttons that already have their own UIScale animations.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local attached = setmetatable({}, {__mode = "k"})
local HOVER = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS = TweenInfo.new(0.075, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function attach(button)
    if not button:IsA("GuiButton") or attached[button] then return end
    attached[button] = true

    -- Existing animated buttons keep their own controller.
    if button:FindFirstChildOfClass("UIScale") then return end
    local scale = Instance.new("UIScale")
    scale.Name = "GlobalButtonHoverScale"
    scale.Scale = 1
    scale.Parent = button

    local hovered, pressed = false, false
    local tween
    local function animate(target, info)
        if tween then tween:Cancel() end
        tween = TweenService:Create(scale, info, {Scale = target})
        tween:Play()
    end

    button.MouseEnter:Connect(function()
        hovered = true
        if not pressed and button.Active then animate(1.05, HOVER) end
    end)
    button.MouseLeave:Connect(function()
        hovered = false
        if not pressed then animate(1, HOVER) end
    end)
    button.MouseButton1Down:Connect(function()
        if not button.Active then return end
        pressed = true
        animate(0.95, PRESS)
    end)
    button.MouseButton1Up:Connect(function()
        if not pressed then return end
        pressed = false
        animate(hovered and 1.05 or 1, RELEASE)
    end)
    button.Activated:Connect(function()
        if pressed then
            pressed = false
            animate(hovered and 1.05 or 1, RELEASE)
        end
    end)
    button.Destroying:Connect(function()
        if tween then tween:Cancel() end
        attached[button] = nil
    end)
end

for _, obj in ipairs(playerGui:GetDescendants()) do
    attach(obj)
end
playerGui.DescendantAdded:Connect(attach)

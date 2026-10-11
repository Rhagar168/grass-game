local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConfig = require(ReplicatedStorage:WaitForChild("ToolConfig"))
local MilestoneConfig = require(ReplicatedStorage:WaitForChild("MilestoneConfig"))
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local SEGMENTS = 40
local DASH_LENGTH = 0.55
local DASH_WIDTH = 0.085
local RING_HEIGHT = 0.07
local CUT_FORWARD = 2.5
local BASE_CUT_RADIUS = 4.5

local folder = Instance.new("Folder")
folder.Name = "ClientCutRadiusRing"
folder.Parent = workspace

local dashes = {}
for i = 1, SEGMENTS do
    local dash = Instance.new("Part")
    dash.Name = "RadiusDash"
    dash.Anchored = true
    dash.CanCollide = false
    dash.CanTouch = false
    dash.CanQuery = false
    dash.CastShadow = false
    dash.Material = Enum.Material.Neon
    dash.Color = Color3.fromRGB(255, 255, 255)
    dash.Transparency = 0.2
    dash.Size = Vector3.new(DASH_WIDTH, 0.035, DASH_LENGTH)
    dash.Parent = folder
    dashes[i] = dash
end

RunService.RenderStepped:Connect(function()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local visible = root and humanoid and humanoid.Health > 0
    if not visible then
        for _, dash in ipairs(dashes) do dash.Transparency = 1 end
        return
    end

    local toolId = player:GetAttribute("EquippedTool") or "BasicScissors"
    local tool = ToolConfig.GetTool(toolId) or ToolConfig.GetTool("BasicScissors")
    local toolRadius = tool and tool.BaseRadius or BASE_CUT_RADIUS
    if tool and tool.Upgrades and tool.Upgrades.Radius then
        local upgrade = tool.Upgrades.Radius
        local level = player:GetAttribute("Tool_" .. toolId .. "_RadiusLevel") or 0
        toolRadius += level * upgrade.AmountPerLevel
    end
    local skillBonus = (player:GetAttribute("CutRadius") or BASE_CUT_RADIUS) - BASE_CUT_RADIUS
    local radius = math.max(0.5, (toolRadius + skillBonus) * MilestoneConfig.GetMultipliers(player).Radius)
    local center = root.Position + root.CFrame.LookVector * CUT_FORWARD
    local groundY = root.Position.Y - humanoid.HipHeight - root.Size.Y * 0.5 + RING_HEIGHT
    local length = math.min(DASH_LENGTH, 2 * math.pi * radius / SEGMENTS * 0.52)
    for i, dash in ipairs(dashes) do
        local angle = (i - 1) * 2 * math.pi / SEGMENTS
        local x = center.X + math.cos(angle) * radius
        local z = center.Z + math.sin(angle) * radius
        dash.Size = Vector3.new(DASH_WIDTH, 0.035, length)
        dash.CFrame = CFrame.new(x, groundY, z) * CFrame.Angles(0, -angle, 0)
        dash.Transparency = 0.2
    end
end)

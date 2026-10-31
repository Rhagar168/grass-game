-- Local-only boss combat visuals. No boss health, hitboxes or health-bar positions are changed.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local active = workspace:WaitForChild("Bosses"):WaitForChild("Active")

local COLORS = {
    AncientGrass = Color3.fromRGB(112, 255, 145),
    OvergrownGrass = Color3.fromRGB(80, 225, 100),
    MoltenGrass = Color3.fromRGB(255, 115, 55),
}

local function makeBurst(position, color, big)
    local anchor = Instance.new("Part")
    anchor.Name = "BossCombatBurst"
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.CFrame = CFrame.new(position)
    anchor.Parent = workspace
    Debris:AddItem(anchor, big and 3 or 1.2)

    local attachment = Instance.new("Attachment")
    attachment.Parent = anchor

    local particles = Instance.new("ParticleEmitter")
    particles.Name = "BossSparks"
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Rate = 0
    particles.Lifetime = NumberRange.new(big and 0.65 or 0.25, big and 1.25 or 0.5)
    particles.Speed = NumberRange.new(big and 13 or 5, big and 24 or 11)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Drag = 3
    particles.LightEmission = 0.7
    particles.Color = ColorSequence.new(color, Color3.fromRGB(255, 242, 180))
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, big and 1.15 or 0.55),
        NumberSequenceKeypoint.new(1, 0),
    })
    particles.Transparency = NumberSequence.new(0.1, 1)
    particles.Parent = attachment
    particles:Emit(big and 65 or 12)

    if big then
        local light = Instance.new("PointLight")
        light.Color = color
        light.Brightness = 4
        light.Range = 22
        light.Parent = anchor
        TweenService:Create(light, TweenInfo.new(0.75), {Brightness = 0}):Play()

        local ring = Instance.new("Part")
        ring.Name = "DefeatShockwave"
        ring.Shape = Enum.PartType.Ball
        ring.Anchored = true
        ring.CanCollide = false
        ring.CanTouch = false
        ring.CanQuery = false
        ring.Material = Enum.Material.Neon
        ring.Color = color
        ring.Transparency = 0.65
        ring.Size = Vector3.new(2, 2, 2)
        ring.CFrame = CFrame.new(position)
        ring.Parent = workspace
        TweenService:Create(ring, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(18, 18, 18),
            Transparency = 1,
        }):Play()
        Debris:AddItem(ring, 0.75)
    end
end

local function attachBoss(model)
    if not model:IsA("Model") or model:GetAttribute("BossGrass") ~= true then return end
    if model:GetAttribute("OwnerUserId") ~= player.UserId then return end
    if model:GetAttribute("CombatEffectsAttached") then return end
    -- This marker is client-only and prevents duplicate listeners.
    model:SetAttribute("CombatEffectsAttached", true)

    local bossId = model:GetAttribute("BossId")
    local color = COLORS[bossId] or Color3.fromRGB(255, 220, 100)
    local hitbox = model:FindFirstChild("BossHitbox") or model:WaitForChild("BossHitbox", 10)
    if not hitbox or not model.Parent then return end

    local lastHit = model:GetAttribute("HitAnimationId") or 0
    local lastHealth = hitbox:GetAttribute("Health") or 0
    local lastFlash = 0
    local defeated = false

    local function flash()
        local now = os.clock()
        if now - lastFlash < 0.12 then return end
        lastFlash = now
        local highlight = Instance.new("Highlight")
        highlight.Name = "BossHitFlash"
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.FillTransparency = 0.28
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0.3
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = model
        TweenService:Create(highlight, TweenInfo.new(0.22), {
            FillTransparency = 1,
            OutlineTransparency = 1,
        }):Play()
        Debris:AddItem(highlight, 0.3)
        local box = model:GetBoundingBox()
        makeBurst(box.Position, color, false)
    end

    model:GetAttributeChangedSignal("HitAnimationId"):Connect(function()
        local nextHit = model:GetAttribute("HitAnimationId") or 0
        if nextHit > lastHit and not defeated then flash() end
        lastHit = nextHit
    end)

    hitbox:GetAttributeChangedSignal("Health"):Connect(function()
        local hp = hitbox:GetAttribute("Health") or 0
        if hp <= 0 and lastHealth > 0 and not defeated then
            defeated = true
            local box = model:GetBoundingBox()
            makeBurst(box.Position, color, true)
        end
        lastHealth = hp
    end)
end

local function onAdded(child)
    if child:IsA("Model") then
        task.spawn(attachBoss, child)
    end
end

active.ChildAdded:Connect(onAdded)
for _, child in ipairs(active:GetChildren()) do onAdded(child) end

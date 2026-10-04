local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("MainUI")
local event = ReplicatedStorage:WaitForChild("BossRewardAnimation")

local coresHUD = gui:WaitForChild("GrassCoresHUD")
local tokensHUD = gui:WaitForChild("ResetTokensHUD")

local layer = Instance.new("Frame")
layer.Name = "BossRewardFX"
layer.BackgroundTransparency = 1
layer.Size = UDim2.fromScale(1, 1)
layer.Position = UDim2.fromScale(0, 0)
layer.ClipsDescendants = false
layer.ZIndex = 200
layer.Parent = gui

local function centerOf(object)
	local p, s = object.AbsolutePosition, object.AbsoluteSize
	local root = gui.AbsolutePosition
	return Vector2.new(p.X - root.X + s.X / 2, p.Y - root.Y + s.Y / 2)
end

local function makeOrb(text, color, startPos)
	local orb = Instance.new("TextLabel")
	orb.AnchorPoint = Vector2.new(0.5, 0.5)
	orb.Position = UDim2.fromOffset(startPos.X, startPos.Y)
	orb.Size = UDim2.fromOffset(48, 48)
	orb.BackgroundTransparency = 1
	orb.BorderSizePixel = 0
	orb.Font = Enum.Font.GothamBlack
	orb.Text = text
	orb.TextColor3 = Color3.new(1, 1, 1)
	orb.TextScaled = true
	orb.TextStrokeTransparency = 0.35
	orb.ZIndex = 201
	orb.Parent = layer

	return orb
end

local function flyOne(text, color, targetHUD, delayTime, spread)
	task.delay(delayTime, function()
		if not targetHUD.Parent then return end
		local viewport = workspace.CurrentCamera.ViewportSize
		local root = gui.AbsolutePosition
		local start = Vector2.new(viewport.X / 2 - root.X, viewport.Y / 2 - root.Y)
		local orb = makeOrb(text, color, start)

		local scatter = Vector2.new(math.random(-spread, spread), math.random(-75, -35))
		local popPos = start + scatter
		local pop = TweenService:Create(orb, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(popPos.X, popPos.Y),
			Size = UDim2.fromOffset(58, 58),
		})
		pop:Play()
		pop.Completed:Wait()

		local target = centerOf(targetHUD)
		local fly = TweenService:Create(orb, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(target.X, target.Y),
			Size = UDim2.fromOffset(18, 18),
			TextTransparency = 0.2,
		})
		fly:Play()
		fly.Completed:Wait()
		orb:Destroy()
	end)
end

event.OnClientEvent:Connect(function(coreReward, tokenReward)
	coreReward = math.max(1, tonumber(coreReward) or 1)
	tokenReward = math.max(1, tonumber(tokenReward) or 1)

	-- GC is deliberately green and always flies to the GC bar.
	for i = 1, math.min(coreReward, 5) do
		flyOne("GC", Color3.fromRGB(48, 180, 82), coresHUD, (i - 1) * 0.08, 55)
	end

	-- RT uses the grey token look and always flies to the RT bar.
	for i = 1, math.min(tokenReward, 5) do
		flyOne("RT", Color3.fromRGB(105, 115, 120), tokensHUD, 0.08 + (i - 1) * 0.07, 80)
	end
end)

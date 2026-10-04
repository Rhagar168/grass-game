local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local bosses = workspace:WaitForChild("Bosses")
local active = bosses:WaitForChild("Active")

local function applyVisibility(model)
	if not model:IsA("Model") then return end
	local ownerUserId = model:GetAttribute("OwnerUserId")
	if typeof(ownerUserId) ~= "number" then return end
	local visible = ownerUserId == player.UserId

	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name == "BossHitbox" then
				obj.LocalTransparencyModifier = 1
			else
				obj.LocalTransparencyModifier = visible and 0 or 1
			end
		elseif obj:IsA("BillboardGui") then
			obj.Enabled = visible
		end
	end
end

local function animateVisualParts(model, finalHit)
	local hitbox = model:FindFirstChild("BossHitbox")
	if not hitbox then return end

	local parts = {}
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") and obj ~= hitbox then
			table.insert(parts, {part = obj, start = obj.CFrame})
		end
	end
	if #parts == 0 then return end

	local amount = finalHit and 1.0 or 0.28
	local duration = finalHit and 0.34 or 0.15
	local alpha = Instance.new("NumberValue")
	local connections = {}

	local function setOffset(y)
		for _, info in ipairs(parts) do
			if info.part.Parent then
				info.part.CFrame = info.start * CFrame.new(0, y, 0)
			end
		end
	end

	table.insert(connections, alpha.Changed:Connect(setOffset))
	local up = TweenService:Create(alpha, TweenInfo.new(duration * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = amount})
	local down = TweenService:Create(alpha, TweenInfo.new(duration * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Value = 0})
	up:Play()
	up.Completed:Wait()
	down:Play()
	down.Completed:Wait()

	for _, connection in ipairs(connections) do connection:Disconnect() end
	for _, info in ipairs(parts) do
		if info.part.Parent then info.part.CFrame = info.start end
	end
	alpha:Destroy()
end

local function animateDefeat(model)
	local hitbox = model:FindFirstChild("BossHitbox")
	if not hitbox then return end

	local parts = {}
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") and obj ~= hitbox then
			table.insert(parts, {
				part = obj,
				startCFrame = obj.CFrame,
				startTransparency = obj.Transparency,
				startColor = obj.Color,
			})
		end
	end
	if #parts == 0 then return end

	-- Similar feel to the gateway: first flash bright, then rise and fade away.
	local flash = Instance.new("NumberValue")
	local flashConnection = flash.Changed:Connect(function(value)
		for _, info in ipairs(parts) do
			if info.part.Parent then
				info.part.Color = info.startColor:Lerp(Color3.new(1, 1, 1), value)
			end
		end
	end)
	local flashTween = TweenService:Create(
		flash,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Value = 0.8}
	)
	flashTween:Play()
	flashTween.Completed:Wait()

	local vanish = Instance.new("NumberValue")
	local vanishConnection = vanish.Changed:Connect(function(value)
		for _, info in ipairs(parts) do
			if info.part.Parent then
				info.part.CFrame = info.startCFrame * CFrame.new(0, value * 1.8, 0)
				info.part.Transparency = info.startTransparency + (1 - info.startTransparency) * value
			end
		end
	end)
	local vanishTween = TweenService:Create(
		vanish,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Value = 1}
	)
	vanishTween:Play()
	vanishTween.Completed:Wait()

	flashConnection:Disconnect()
	vanishConnection:Disconnect()
	flash:Destroy()
	vanish:Destroy()
end

local function watch(model)
	applyVisibility(model)
	model.DescendantAdded:Connect(function()
		task.defer(applyVisibility, model)
	end)

	if model:GetAttribute("OwnerUserId") == player.UserId then
		local lastAnimation = model:GetAttribute("HitAnimationId") or 0
		model:GetAttributeChangedSignal("HitAnimationId"):Connect(function()
			local id = model:GetAttribute("HitAnimationId") or 0
			if id == lastAnimation then return end
			lastAnimation = id
			local hitbox = model:FindFirstChild("BossHitbox")
			local finalHit = hitbox and (hitbox:GetAttribute("Health") or 0) <= 0
			if finalHit then
				task.spawn(animateDefeat, model)
			else
				task.spawn(animateVisualParts, model, false)
			end
		end)
	end
end

for _, model in ipairs(active:GetChildren()) do watch(model) end
active.ChildAdded:Connect(watch)

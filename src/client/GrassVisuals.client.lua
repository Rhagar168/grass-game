local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local damagePopupEvent = ReplicatedStorage:WaitForChild("DamagePopup")
local instantBreakPopupEvent = ReplicatedStorage:WaitForChild("InstantBreakPopup")

local function updateGrassVisibility(grass)
	if not grass:IsA("BasePart") then return end
	local ownerUserId = grass:GetAttribute("OwnerUserId")
	grass.LocalTransparencyModifier = (ownerUserId == nil or ownerUserId == player.UserId) and 0 or 1
end

local function watchGrass(grass)
	if not grass:IsA("BasePart") then return end
	updateGrassVisibility(grass)
	grass:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		updateGrassVisibility(grass)
	end)
end

for _, grass in ipairs(CollectionService:GetTagged("Cuttable")) do
	watchGrass(grass)
end
CollectionService:GetInstanceAddedSignal("Cuttable"):Connect(function(grass)
	task.defer(watchGrass, grass)
end)

local function makeWorldPopup(plant, message, textColor, strokeColor, width, height, jumpHeight)
	if not plant or not plant.Parent then return end
	if plant:GetAttribute("OwnerUserId") ~= player.UserId then return end

	local holder = Instance.new("Part")
	holder.Name = "DamagePopupHolder"
	holder.Size = Vector3.new(0.1, 0.1, 0.1)
	holder.Position = plant.Position + Vector3.new(math.random(-4,4)/10, plant.Size.Y/2 + 0.5, math.random(-4,4)/10)
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(width, height)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 60
	billboard.Parent = holder

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = textColor
	label.TextStrokeColor3 = strokeColor
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextStrokeTransparency = 0.1
	label.Parent = billboard

	local jump = TweenService:Create(holder, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = holder.Position + Vector3.new(0, jumpHeight, 0)
	})
	jump:Play()
	jump.Completed:Wait()
	task.wait(0.35)

	local fade = TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})
	fade:Play()
	fade.Completed:Wait()
	if holder.Parent then holder:Destroy() end
end

damagePopupEvent.OnClientEvent:Connect(function(plant, damage, isCrit)
	if player:GetAttribute("Setting_DamagePopups") == false then return end
	if isCrit and player:GetAttribute("Setting_CriticalPopups") == false then return end

	if isCrit then
		task.spawn(makeWorldPopup, plant, "CRIT! -" .. string.format("%.1f", damage),
			Color3.fromRGB(155, 35, 40), Color3.fromRGB(55, 8, 12), 105, 52, 2)
	else
		task.spawn(makeWorldPopup, plant, "-" .. string.format("%.1f", damage),
			Color3.fromRGB(255, 90, 55), Color3.fromRGB(90, 20, 10), 75, 38, 1.5)
	end
end)

instantBreakPopupEvent.OnClientEvent:Connect(function(plant)
	task.spawn(makeWorldPopup, plant, "INSTANT BREAK!",
		Color3.fromRGB(105, 215, 255), Color3.fromRGB(20, 75, 110), 145, 48, 2)
end)

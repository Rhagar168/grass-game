local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local cutEvent = ReplicatedStorage:WaitForChild("CutVegetation")

local CUT_FORWARD = 2.5
local CUT_DOWN = 1.5
local BASE_CUT_RADIUS = 4.5
local BASE_CUT_COUNT = 1

cutEvent.OnServerEvent:Connect(function(player)
	local chance = math.clamp(player:GetAttribute("InstantBreakChance") or 0, 0, 1)
	if chance <= 0 then return end
	if player:GetAttribute("UpgradeMenuOpen") == true then return end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local cutRadius = player:GetAttribute("CutRadius") or BASE_CUT_RADIUS
	local cutCount = math.max(1, math.floor(player:GetAttribute("CutCount") or BASE_CUT_COUNT))
	local cutCenter = root.Position + root.CFrame.LookVector * CUT_FORWARD - Vector3.new(0, CUT_DOWN, 0)
	local candidates = {}

	for _, plant in ipairs(CollectionService:GetTagged("Cuttable")) do
		if not plant:IsA("BasePart") then continue end
		if not plant:IsDescendantOf(workspace) then continue end
		if plant:GetAttribute("OwnerUserId") ~= player.UserId then continue end
		if plant:GetAttribute("Destroying") == true then continue end

		local distance = (plant.Position - cutCenter).Magnitude
		if distance <= cutRadius then
			table.insert(candidates, {plant = plant, distance = distance})
		end
	end

	table.sort(candidates, function(a, b)
		return a.distance < b.distance
	end)

	local amount = math.min(#candidates, cutCount)
	for i = 1, amount do
		local plant = candidates[i].plant
		if plant and plant.Parent and math.random() < chance then
			-- CuttingServer sees zero remaining health on this hit and runs its normal reward/XP/destroy flow.
			plant:SetAttribute("Health", 0)
		end
	end
end)

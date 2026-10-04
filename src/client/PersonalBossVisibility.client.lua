local Players = game:GetService("Players")

local player = Players.LocalPlayer
local bosses = workspace:WaitForChild("Bosses")
local active = bosses:WaitForChild("Active")

local function applyVisibility(model)
	if not model:IsA("Model") then
		return
	end

	local ownerUserId = model:GetAttribute("OwnerUserId")
	if typeof(ownerUserId) ~= "number" then
		return
	end

	local visible = ownerUserId == player.UserId

	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			-- Hitbox must always stay invisible. Other boss parts are visible
			-- only to their owner.
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

local function watch(model)
	applyVisibility(model)
	model.DescendantAdded:Connect(function()
		task.defer(applyVisibility, model)
	end)
end

for _, model in ipairs(active:GetChildren()) do
	watch(model)
end

active.ChildAdded:Connect(watch)

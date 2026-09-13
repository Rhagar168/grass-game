local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vegetationFolder = workspace:WaitForChild("Vegetation")
local progressEvent = ReplicatedStorage:WaitForChild("LocationProgressUpdate")

local LOCATION_ID = "BusStop"
local MAX_GRASS = 500

vegetationFolder.DescendantRemoving:Connect(function(descendant)
	if not descendant:IsA("BasePart") then
		return
	end

	if descendant:GetAttribute("LocationId") ~= LOCATION_ID then
		return
	end

	local ownerUserId = descendant:GetAttribute("OwnerUserId")
	if not ownerUserId then
		return
	end

	local player = Players:GetPlayerByUserId(ownerUserId)
	if not player then
		return
	end

	if player:GetAttribute("BusStopResetting") == true then
		return
	end

	if descendant:GetAttribute("ProgressCounted") == true then
		return
	end

	descendant:SetAttribute("ProgressCounted", true)

	local remaining = player:GetAttribute("BusStopGrassRemaining")
	if typeof(remaining) ~= "number" then
		remaining = MAX_GRASS
	end

	remaining = math.clamp(math.floor(remaining + 0.5) - 1, 0, MAX_GRASS)
	player:SetAttribute("BusStopGrassRemaining", remaining)

	task.defer(function()
		if player.Parent then
			progressEvent:Fire(LOCATION_ID, player)
		end
	end)
end)

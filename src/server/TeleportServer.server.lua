local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("TeleportRequest")
local locations = workspace:WaitForChild("Locations")

local VALID_LOCATIONS = {
	Plains = true,
	Forest = true,
	Savanna = true,
	Jungle = true,
	Tundra = true,
	Volcano = true,
	Beach = true,
}

local function isUnlocked(player, biome)
	if biome == "Plains" then
		return true
	end

	return player:GetAttribute(biome .. "Unlocked") == true
end

remote.OnServerEvent:Connect(function(player, biome)
	if typeof(biome) ~= "string" then
		return
	end

	if not VALID_LOCATIONS[biome] then
		return
	end

	if not isUnlocked(player, biome) then
		return
	end

	local location = locations:FindFirstChild(biome)
	if not location then
		warn("[Teleport] Location missing:", biome)
		return
	end

	local point = location:FindFirstChild("TeleportPoint")
	if not point or not point:IsA("BasePart") then
		warn("[Teleport] TeleportPoint missing:", biome)
		return
	end

	local character = player.Character
	if not character then
		return
	end

	character:PivotTo(
		point.CFrame * CFrame.new(0, 3, 0)
	)
end)

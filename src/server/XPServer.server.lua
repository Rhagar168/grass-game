local Players = game:GetService("Players")

local BASE_XP_TO_LEVEL = 10
local XP_GROWTH = 1.35

local function getXPRequired(level)
	return math.floor(
		BASE_XP_TO_LEVEL
			* (XP_GROWTH ^ (level - 1))
			+ 0.5
	)
end

local function setupPlayer(player)
	if player:GetAttribute("XP") == nil then
		player:SetAttribute("XP", 0)
	end

	if player:GetAttribute("Level") == nil then
		player:SetAttribute("Level", 1)
	end

	local level =
		player:GetAttribute("Level") or 1

	player:SetAttribute(
		"XPToNext",
		getXPRequired(level)
	)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
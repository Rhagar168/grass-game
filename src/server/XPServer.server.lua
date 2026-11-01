local Players = game:GetService("Players")

local BASE_XP_TO_LEVEL = 120
local XP_GROWTH = 1.30

local function getXPRequired(level)
    local required = BASE_XP_TO_LEVEL * (XP_GROWTH ^ (math.min(level, 15) - 1))
    if level > 15 then
        required *= 1.35 ^ (level - 15)
    end
    return math.floor(required + 0.5)
end

local function waitForData(player)
	while player.Parent and player:GetAttribute("DataLoaded") ~= true do
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end
	return player.Parent ~= nil
end

local function setupPlayer(player)
	if not waitForData(player) then return end

	if player:GetAttribute("XP") == nil then
		player:SetAttribute("XP", 0)
	end

	if player:GetAttribute("Level") == nil then
		player:SetAttribute("Level", 1)
	end

	local level = player:GetAttribute("Level") or 1
	player:SetAttribute("XPToNext", getXPRequired(level))

	-- Keep the requirement synchronized after level changes and /resetdata.
	player:GetAttributeChangedSignal("Level"):Connect(function()
		local currentLevel = math.max(1, player:GetAttribute("Level") or 1)
		player:SetAttribute("XPToNext", getXPRequired(currentLevel))
	end)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

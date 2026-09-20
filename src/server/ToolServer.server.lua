local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolConfig = require(ReplicatedStorage:WaitForChild("ToolConfig"))

local equipEvent = ReplicatedStorage:FindFirstChild("ToolEquip")
if not equipEvent then
	equipEvent = Instance.new("RemoteEvent")
	equipEvent.Name = "ToolEquip"
	equipEvent.Parent = ReplicatedStorage
end

local upgradeEvent = ReplicatedStorage:FindFirstChild("ToolUpgradePurchase")
if not upgradeEvent then
	upgradeEvent = Instance.new("RemoteEvent")
	upgradeEvent.Name = "ToolUpgradePurchase"
	upgradeEvent.Parent = ReplicatedStorage
end

local VALID_STATS = {
	Damage = true,
	Cooldown = true,
	Radius = true,
	CutCount = true,
}

local function getUpgradeAttribute(toolId, statName)
	return "Tool_" .. toolId .. "_" .. statName .. "Level"
end

local function getUpgradeLevel(player, toolId, statName)
	local value = player:GetAttribute(getUpgradeAttribute(toolId, statName))
	if typeof(value) ~= "number" then
		return 0
	end
	return math.max(0, math.floor(value))
end

local function isUnlocked(player, toolId)
	local tool = ToolConfig.GetTool(toolId)
	if not tool then
		return false
	end

	local level = player:GetAttribute("Level") or 1
	return level >= tool.UnlockLevel
end

local function setupToolAttributes(player)
	if player:GetAttribute("EquippedTool") == nil then
		player:SetAttribute("EquippedTool", "BasicScissors")
	end

	for _, toolId in ipairs(ToolConfig.Order) do
		local tool = ToolConfig.GetTool(toolId)
		if tool then
			for statName, upgrade in pairs(tool.Upgrades) do
				local attributeName = getUpgradeAttribute(toolId, statName)
				local level = player:GetAttribute(attributeName)

				if typeof(level) ~= "number" then
					level = 0
				end

				player:SetAttribute(
					attributeName,
					math.clamp(math.floor(level), 0, upgrade.MaxLevel)
				)
			end
		end
	end

	local equippedTool = player:GetAttribute("EquippedTool")
	if typeof(equippedTool) ~= "string"
		or not ToolConfig.GetTool(equippedTool)
		or not isUnlocked(player, equippedTool) then
		player:SetAttribute("EquippedTool", "BasicScissors")
	end
end

equipEvent.OnServerEvent:Connect(function(player, toolId)
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end

	if typeof(toolId) ~= "string" then
		return
	end

	if not ToolConfig.GetTool(toolId) then
		return
	end

	if not isUnlocked(player, toolId) then
		return
	end

	player:SetAttribute("EquippedTool", toolId)
end)

upgradeEvent.OnServerEvent:Connect(function(player, toolId, statName)
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end

	if typeof(toolId) ~= "string" or typeof(statName) ~= "string" then
		return
	end

	if not VALID_STATS[statName] then
		return
	end

	local tool = ToolConfig.GetTool(toolId)
	local upgrade = ToolConfig.GetUpgrade(toolId, statName)

	if not tool or not upgrade then
		return
	end

	if not isUnlocked(player, toolId) then
		return
	end

	local currentLevel = getUpgradeLevel(player, toolId, statName)
	if currentLevel >= upgrade.MaxLevel then
		return
	end

	local price = ToolConfig.GetUpgradePrice(toolId, statName, currentLevel)
	if typeof(price) ~= "number" or price < 0 then
		return
	end

	local resetTokens = player:GetAttribute("ResetTokens") or 0
	if resetTokens < price then
		return
	end

	player:SetAttribute("ResetTokens", resetTokens - price)
	player:SetAttribute(
		getUpgradeAttribute(toolId, statName),
		currentLevel + 1
	)
end)

local function waitForData(player)
	while player.Parent and player:GetAttribute("DataLoaded") ~= true do
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end

	return player.Parent ~= nil
end

local function setupPlayer(player)
	if not waitForData(player) then
		return
	end

	setupToolAttributes(player)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

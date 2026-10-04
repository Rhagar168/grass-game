local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreLabConfig = require(ReplicatedStorage:WaitForChild("CoreLabConfig"))

local event = ReplicatedStorage:FindFirstChild("CoreLabAction") or Instance.new("RemoteEvent")
event.Name = "CoreLabAction"
event.Parent = ReplicatedStorage

local function applyBonuses(player)
	local power = player:GetAttribute("CoreLabPowerLevel") or 0
	local harvest = player:GetAttribute("CoreLabHarvestLevel") or 0
	local capacity = player:GetAttribute("CoreLabCapacityLevel") or 0
	local wisdom = player:GetAttribute("CoreLabWisdomLevel") or 0
	local critical = player:GetAttribute("CoreLabCriticalLevel") or 0
	local bossHunter = player:GetAttribute("CoreLabBossHunterLevel") or 0

	player:SetAttribute("CoreLabDamageMultiplier", 1 + power * 0.05)
	player:SetAttribute("CoreLabGrassMultiplier", 1 + harvest * 0.05)
	player:SetAttribute("CoreLabCapacityMultiplier", 1 + capacity * 0.10)
	player:SetAttribute("CoreLabXPMultiplier", 1 + wisdom * 0.05)
	player:SetAttribute("CoreLabCritDamageBonus", critical * 0.10)
	player:SetAttribute("CoreLabBossDamageMultiplier", 1 + bossHunter * 0.05)
end

local function claim(player)
	local id = player:GetAttribute("CoreLabActiveResearch") or ""
	local finishAt = player:GetAttribute("CoreLabResearchFinishAt") or 0
	if id == "" or os.time() < finishAt then return false end
	local research = CoreLabConfig.Researches[id]
	if not research then return false end
	local level = math.max(0, math.floor(player:GetAttribute(research.Attribute) or 0))
	if level >= CoreLabConfig.MaxLevel then return false end
	player:SetAttribute(research.Attribute, level + 1)
	player:SetAttribute("CoreLabActiveResearch", "")
	player:SetAttribute("CoreLabResearchFinishAt", 0)
	applyBonuses(player)
	event:FireClient(player, "Claimed", id, level + 1)
	return true
end

event.OnServerEvent:Connect(function(player, action, researchId)
	if action == "Start" then
		claim(player)
		if (player:GetAttribute("CoreLabActiveResearch") or "") ~= "" then return end
		local research, nextLevel, cost, duration = CoreLabConfig.GetNextLevelInfo(player, researchId)
		if not research then return end
		local cores = player:GetAttribute("GrassCores") or 0
		if cores < cost then return end
		player:SetAttribute("GrassCores", cores - cost)
		player:SetAttribute("CoreLabActiveResearch", researchId)
		player:SetAttribute("CoreLabResearchFinishAt", os.time() + duration)
		event:FireClient(player, "Started", researchId, nextLevel)
	elseif action == "Claim" then
		claim(player)
	end
end)

local function setup(player)
	while player.Parent and player:GetAttribute("DataLoaded") ~= true do
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end
	if not player.Parent then return end
	applyBonuses(player)
end

Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player) end

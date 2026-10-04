local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local claimEvent = ReplicatedStorage:FindFirstChild("ClaimDailyQuest") or Instance.new("RemoteEvent")
claimEvent.Name = "ClaimDailyQuest"
claimEvent.Parent = ReplicatedStorage

local QUESTS = {
	Quest1 = {stat = "TotalGrassCut", goal = 5000, rewardType = "ResetTokens", reward = 2},
	Quest2 = {stat = "Coins", goal = 100000, rewardType = "Coins", reward = 5000},
	Quest3 = {stat = "Level", goal = 4, rewardType = "ResetTokens", reward = 3},
}

local function dayKey()
	return math.floor(os.time() / 86400)
end

local function resetDay(player)
	player:SetAttribute("DailyQuestDayKey", dayKey())
	player:SetAttribute("DailyQuestStartGrass", player:GetAttribute("TotalGrassCut") or 0)
	player:SetAttribute("DailyQuestStartCoins", player:GetAttribute("Coins") or 0)
	player:SetAttribute("DailyQuestStartLevel", player:GetAttribute("Level") or 1)
	player:SetAttribute("DailyQuestCoinsEarned", 0)
	for i = 1, 3 do player:SetAttribute("DailyQuestClaimed"..i, false) end
end

local function progress(player, id)
	if id == "Quest1" then
		return math.max(0, (player:GetAttribute("TotalGrassCut") or 0) - (player:GetAttribute("DailyQuestStartGrass") or 0))
	elseif id == "Quest2" then
		return math.max(0, (player:GetAttribute("DailyQuestCoinsEarned") or 0))
	else
		return math.max(0, (player:GetAttribute("Level") or 1) - (player:GetAttribute("DailyQuestStartLevel") or 1))
	end
end

local function refresh(player)
	if player:GetAttribute("DailyQuestDayKey") ~= dayKey() then resetDay(player) end
	for i = 1, 3 do
		local id = "Quest"..i
		player:SetAttribute("DailyQuestProgress"..i, math.min(progress(player,id), QUESTS[id].goal))
	end
end

local function setup(player)
	while player.Parent and player:GetAttribute("DataLoaded") ~= true do task.wait(.1) end
	if not player.Parent then return end
	if player:GetAttribute("DailyQuestDayKey") ~= dayKey() then resetDay(player) end
	refresh(player)
	local lastCoins = player:GetAttribute("Coins") or 0
	player:GetAttributeChangedSignal("Coins"):Connect(function()
		local nowCoins = player:GetAttribute("Coins") or 0
		if nowCoins > lastCoins then
			player:SetAttribute("DailyQuestCoinsEarned", (player:GetAttribute("DailyQuestCoinsEarned") or 0) + (nowCoins - lastCoins))
		end
		lastCoins = nowCoins
		refresh(player)
	end)
	for _, attr in ipairs({"TotalGrassCut","Level"}) do
		player:GetAttributeChangedSignal(attr):Connect(function() refresh(player) end)
	end
end

claimEvent.OnServerEvent:Connect(function(player, index)
	index = tonumber(index)
	if not index or index < 1 or index > 3 then return end
	refresh(player)
	local q = QUESTS["Quest"..index]
	if player:GetAttribute("DailyQuestClaimed"..index) == true then return end
	if (player:GetAttribute("DailyQuestProgress"..index) or 0) < q.goal then return end
	player:SetAttribute("DailyQuestClaimed"..index, true)
	player:SetAttribute(q.rewardType, (player:GetAttribute(q.rewardType) or 0) + q.reward)
end)

Players.PlayerAdded:Connect(function(p) task.spawn(setup,p) end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(setup,p) end

task.spawn(function()
	while true do
		task.wait(30)
		for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute("DataLoaded")==true then refresh(p) end end
	end
end)

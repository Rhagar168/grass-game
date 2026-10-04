local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local claimEvent = ReplicatedStorage:FindFirstChild("ClaimDailyQuest") or Instance.new("RemoteEvent")
claimEvent.Name = "ClaimDailyQuest"
claimEvent.Parent = ReplicatedStorage

local QUEST_POOL = {
	{Id="Cut2K", Type="Delta", Stat="TotalGrassCut", Goal=2000, Title="CUT 2K GRASS", RewardType="Coins", Reward=3000, RewardText="+3K COINS"},
	{Id="Cut5K", Type="Delta", Stat="TotalGrassCut", Goal=5000, Title="CUT 5K GRASS", RewardType="ResetTokens", Reward=2, RewardText="+2 RESET TOKENS"},
	{Id="Cut10K", Type="Delta", Stat="TotalGrassCut", Goal=10000, Title="CUT 10K GRASS", RewardType="ResetTokens", Reward=4, RewardText="+4 RESET TOKENS"},
	{Id="Earn25K", Type="EarnCoins", Goal=25000, Title="EARN 25K COINS", RewardType="Coins", Reward=2500, RewardText="+2.5K COINS"},
	{Id="Earn100K", Type="EarnCoins", Goal=100000, Title="EARN 100K COINS", RewardType="Coins", Reward=5000, RewardText="+5K COINS"},
	{Id="Earn250K", Type="EarnCoins", Goal=250000, Title="EARN 250K COINS", RewardType="ResetTokens", Reward=3, RewardText="+3 RESET TOKENS"},
	{Id="Levels2", Type="Delta", Stat="Level", Goal=2, Title="GAIN 2 LEVELS", RewardType="Coins", Reward=3000, RewardText="+3K COINS"},
	{Id="Levels4", Type="Delta", Stat="Level", Goal=4, Title="GAIN 4 LEVELS", RewardType="ResetTokens", Reward=3, RewardText="+3 RESET TOKENS"},
	{Id="Reset1", Type="Delta", Stat="TotalResets", Goal=1, Title="DO 1 RESET", RewardType="Coins", Reward=5000, RewardText="+5K COINS"},
	{Id="Reset3", Type="Delta", Stat="TotalResets", Goal=3, Title="DO 3 RESETS", RewardType="ResetTokens", Reward=4, RewardText="+4 RESET TOKENS"},
	{Id="Gold1", Type="Delta", Stat="GoldGrassFound", Goal=1, Title="FIND 1 GOLD GRASS", RewardType="Coins", Reward=7500, RewardText="+7.5K COINS"},
	{Id="Gold3", Type="Delta", Stat="GoldGrassFound", Goal=3, Title="FIND 3 GOLD GRASS", RewardType="ResetTokens", Reward=3, RewardText="+3 RESET TOKENS"},
}

local BY_ID = {}
for _, q in ipairs(QUEST_POOL) do BY_ID[q.Id] = q end

local function dayKey()
	return math.floor(os.time() / 86400)
end

local function dailySelection(key)
	local indices = {}
	for i=1,#QUEST_POOL do indices[i]=i end
	local rng = Random.new(key + 918273)
	for i=#indices,2,-1 do
		local j=rng:NextInteger(1,i)
		indices[i],indices[j]=indices[j],indices[i]
	end
	return {QUEST_POOL[indices[1]],QUEST_POOL[indices[2]],QUEST_POOL[indices[3]]}
end

local function baselineName(q)
	return "DailyQuestStart_"..q.Stat
end

local function resetDay(player)
	local key=dayKey()
	local selected=dailySelection(key)
	player:SetAttribute("DailyQuestDayKey",key)
	player:SetAttribute("DailyQuestCoinsEarned",0)
	for i,q in ipairs(selected) do
		player:SetAttribute("DailyQuestId"..i,q.Id)
		player:SetAttribute("DailyQuestClaimed"..i,false)
		if q.Type=="Delta" then
			player:SetAttribute(baselineName(q),player:GetAttribute(q.Stat) or 0)
		end
	end
end

local function getQuest(player,index)
	local id=player:GetAttribute("DailyQuestId"..index)
	return typeof(id)=="string" and BY_ID[id] or nil
end

local function progress(player,q)
	if q.Type=="EarnCoins" then
		return math.max(0,player:GetAttribute("DailyQuestCoinsEarned") or 0)
	end
	local start=player:GetAttribute(baselineName(q)) or 0
	return math.max(0,(player:GetAttribute(q.Stat) or 0)-start)
end

local function publishQuest(player,index,q)
	player:SetAttribute("DailyQuestTitle"..index,q.Title)
	player:SetAttribute("DailyQuestGoal"..index,q.Goal)
	player:SetAttribute("DailyQuestRewardText"..index,q.RewardText)
	player:SetAttribute("DailyQuestProgress"..index,math.min(progress(player,q),q.Goal))
end

local function refresh(player)
	if player:GetAttribute("DailyQuestDayKey")~=dayKey() then resetDay(player) end
	for i=1,3 do
		local q=getQuest(player,i)
		if not q then
			resetDay(player)
			q=getQuest(player,i)
		end
		if q then publishQuest(player,i,q) end
	end
end

local function setup(player)
	while player.Parent and player:GetAttribute("DataLoaded")~=true do task.wait(.1) end
	if not player.Parent then return end
	if player:GetAttribute("DailyQuestDayKey")~=dayKey() then resetDay(player) end
	refresh(player)

	local lastCoins=player:GetAttribute("Coins") or 0
	player:GetAttributeChangedSignal("Coins"):Connect(function()
		local nowCoins=player:GetAttribute("Coins") or 0
		if nowCoins>lastCoins then
			player:SetAttribute("DailyQuestCoinsEarned",(player:GetAttribute("DailyQuestCoinsEarned") or 0)+(nowCoins-lastCoins))
		end
		lastCoins=nowCoins
		refresh(player)
	end)

	for _,attr in ipairs({"TotalGrassCut","Level","TotalResets","GoldGrassFound","RainbowGrassFound"}) do
		player:GetAttributeChangedSignal(attr):Connect(function() refresh(player) end)
	end
end

claimEvent.OnServerEvent:Connect(function(player,index)
	index=tonumber(index)
	if not index or index<1 or index>3 then return end
	refresh(player)
	local q=getQuest(player,index)
	if not q then return end
	if player:GetAttribute("DailyQuestClaimed"..index)==true then return end
	if (player:GetAttribute("DailyQuestProgress"..index) or 0)<q.Goal then return end
	player:SetAttribute("DailyQuestClaimed"..index,true)
	player:SetAttribute(q.RewardType,(player:GetAttribute(q.RewardType) or 0)+q.Reward)
end)

Players.PlayerAdded:Connect(function(p) task.spawn(setup,p) end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(setup,p) end

task.spawn(function()
	while true do
		task.wait(30)
		for _,p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("DataLoaded")==true then refresh(p) end
		end
	end
end)

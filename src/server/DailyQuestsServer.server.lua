local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local claimEvent = ReplicatedStorage:FindFirstChild("ClaimDailyQuest") or Instance.new("RemoteEvent")
claimEvent.Name = "ClaimDailyQuest"
claimEvent.Parent = ReplicatedStorage

-- One version of each quest type. These are deliberately based on activity,
-- not economy size, so early-game and end-game players get comparable dailies.
local QUEST_POOL = {
	{Id="Play30", Type="Delta", Stat="Playtime", Goal=1800, Title="PLAY 30 MINUTES", RewardType="ResetTokens", Reward=3, RewardText="+3 RESET TOKENS", Format="Time"},
	{Id="Reset3", Type="Delta", Stat="TotalResets", Goal=3, Title="DO 3 RESETS", RewardType="ResetTokens", Reward=4, RewardText="+4 RESET TOKENS"},
	{Id="Gold5", Type="Delta", Stat="GoldGrassFound", Goal=5, Title="FIND 5 GOLD GRASS", RewardType="ResetTokens", Reward=3, RewardText="+3 RESET TOKENS"},
	{Id="Rainbow2", Type="Delta", Stat="RainbowGrassFound", Goal=2, Title="FIND 2 RAINBOW GRASS", RewardType="ResetTokens", Reward=5, RewardText="+5 RESET TOKENS"},
	{Id="Locations3", Type="Counter", Stat="DailyQuestLocationsUsed", Goal=3, Title="CUT IN 3 LOCATIONS", RewardType="ResetTokens", Reward=3, RewardText="+3 RESET TOKENS"},
	{Id="Tools2", Type="Counter", Stat="DailyQuestToolsUsed", Goal=2, Title="USE 2 DIFFERENT TOOLS", RewardType="Coins", Reward=7500, RewardText="+7.5K COINS"},
	{Id="Rare8", Type="RareDelta", Goal=8, Title="FIND 8 RARE GRASS", RewardType="ResetTokens", Reward=4, RewardText="+4 RESET TOKENS"},
}

local BY_ID = {}
for _,q in ipairs(QUEST_POOL) do BY_ID[q.Id]=q end

local function dayKey()
	return math.floor(os.time()/86400)
end

local function dailySelection(key)
	local indices={}
	for i=1,#QUEST_POOL do indices[i]=i end
	local rng=Random.new(key+918273)
	for i=#indices,2,-1 do
		local j=rng:NextInteger(1,i)
		indices[i],indices[j]=indices[j],indices[i]
	end
	return {QUEST_POOL[indices[1]],QUEST_POOL[indices[2]],QUEST_POOL[indices[3]]}
end

local function baselineName(stat)
	return "DailyQuestStart_"..stat
end

local function resetDay(player)
	local selected=dailySelection(dayKey())
	player:SetAttribute("DailyQuestDayKey",dayKey())
	player:SetAttribute("DailyQuestLocationsMask",0)
	player:SetAttribute("DailyQuestLocationsUsed",0)
	player:SetAttribute("DailyQuestToolsMask",0)
	player:SetAttribute("DailyQuestToolsUsed",0)

	-- Baselines are always recorded so any of these quests can be selected.
	for _,stat in ipairs({"Playtime","TotalResets","GoldGrassFound","RainbowGrassFound"}) do
		player:SetAttribute(baselineName(stat),player:GetAttribute(stat) or 0)
	end

	for i,q in ipairs(selected) do
		player:SetAttribute("DailyQuestId"..i,q.Id)
		player:SetAttribute("DailyQuestClaimed"..i,false)
	end
end

local function getQuest(player,index)
	local id=player:GetAttribute("DailyQuestId"..index)
	return typeof(id)=="string" and BY_ID[id] or nil
end

local function progress(player,q)
	if q.Type=="Delta" then
		return math.max(0,(player:GetAttribute(q.Stat) or 0)-(player:GetAttribute(baselineName(q.Stat)) or 0))
	elseif q.Type=="Counter" then
		return math.max(0,player:GetAttribute(q.Stat) or 0)
	elseif q.Type=="RareDelta" then
		local gold=math.max(0,(player:GetAttribute("GoldGrassFound") or 0)-(player:GetAttribute(baselineName("GoldGrassFound")) or 0))
		local rainbow=math.max(0,(player:GetAttribute("RainbowGrassFound") or 0)-(player:GetAttribute(baselineName("RainbowGrassFound")) or 0))
		return gold+rainbow
	end
	return 0
end

local function publishQuest(player,index,q)
	player:SetAttribute("DailyQuestTitle"..index,q.Title)
	player:SetAttribute("DailyQuestGoal"..index,q.Goal)
	player:SetAttribute("DailyQuestRewardText"..index,q.RewardText)
	player:SetAttribute("DailyQuestFormat"..index,q.Format or "Number")
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

	for _,attr in ipairs({
		"Playtime","TotalResets","GoldGrassFound","RainbowGrassFound",
		"DailyQuestLocationsUsed","DailyQuestToolsUsed",
	}) do
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

-- Playtime is already persisted by PlayerData. Update the live attribute once
-- per minute so the 30-minute daily can progress without requiring a save.
task.spawn(function()
	while true do
		task.wait(60)
		for _,p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("DataLoaded")==true then
				p:SetAttribute("Playtime",(p:GetAttribute("Playtime") or 0)+60)
				refresh(p)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(30)
		for _,p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("DataLoaded")==true then refresh(p) end
		end
	end
end)

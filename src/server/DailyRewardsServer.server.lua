local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local claimEvent =
	ReplicatedStorage:WaitForChild("DailyRewardClaim")

local resultEvent =
	ReplicatedStorage:WaitForChild("DailyRewardResult")

-- 24 hodin
local CLAIM_COOLDOWN = 24 * 60 * 60

local REWARDS = {
	[1] = {
		Coins = 500,
	},

	[2] = {
		Coins = 1500,
	},

	[3] = {
		ResetTokens = 2,
	},

	[4] = {
		Coins = 5000,
	},

	[5] = {
		ResetTokens = 5,
	},

	[6] = {
		Coins = 15000,
	},

	[7] = {
		Coins = 25000,
		ResetTokens = 10,
	},
}

local function getTimeRemaining(player)
	local lastClaim =
		player:GetAttribute("DailyRewardLastClaim") or 0

	if lastClaim <= 0 then
		return 0
	end

	local elapsed =
		os.time() - lastClaim

	return math.max(
		0,
		CLAIM_COOLDOWN - elapsed
	)
end

local function claimReward(player)
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end

	if getTimeRemaining(player) > 0 then
		return
	end

	local day =
		player:GetAttribute("DailyRewardDay") or 1

	day = math.clamp(
		math.floor(day),
		1,
		7
	)

	local reward = REWARDS[day]

	if not reward then
		return
	end

	local now = os.time()

	player:SetAttribute(
		"DailyRewardLastClaim",
		now
	)

	if day == 1
		and (player:GetAttribute("DailyRewardCycleStart") or 0) <= 0 then

		player:SetAttribute(
			"DailyRewardCycleStart",
			now
		)
	end

	if reward.Coins then
		local coins =
			player:GetAttribute("Coins") or 0

		player:SetAttribute(
			"Coins",
			coins + reward.Coins
		)
	end

	if reward.ResetTokens then
		local tokens =
			player:GetAttribute("ResetTokens") or 0

		player:SetAttribute(
			"ResetTokens",
			tokens + reward.ResetTokens
		)
	end

	local nextDay

	if day >= 7 then
		nextDay = 1

		player:SetAttribute(
			"DailyRewardCycleStart",
			now
		)
	else
		nextDay = day + 1
	end

	player:SetAttribute(
		"DailyRewardDay",
		nextDay
	)

	resultEvent:FireClient(
		player,
		day,
		reward.Coins or 0,
		reward.ResetTokens or 0
	)
end

claimEvent.OnServerEvent:Connect(
	claimReward
)

local function setupPlayer(player)
	if player:GetAttribute("DailyRewardDay") == nil then
		player:SetAttribute("DailyRewardDay", 1)
	end

	if player:GetAttribute("DailyRewardLastClaim") == nil then
		player:SetAttribute("DailyRewardLastClaim", 0)
	end

	if player:GetAttribute("DailyRewardCycleStart") == nil then
		player:SetAttribute("DailyRewardCycleStart", 0)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

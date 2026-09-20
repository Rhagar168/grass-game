local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local boards = workspace:WaitForChild("Boards"):WaitForChild("Plains")

local UPDATE_INTERVAL = 60
local TOP_COUNT = 100

local CONFIG = {
	{
		modelName = "LeaderBoardResets",
		attribute = "TotalResets",
		store = DataStoreService:GetOrderedDataStore("GrassGame_GlobalResets_v1"),
		format = function(value)
			return formatNumber(value)
		end,
	},
	{
		modelName = "LeaderBoardGrass",
		attribute = "TotalGrassCut",
		store = DataStoreService:GetOrderedDataStore("GrassGame_GlobalGrassCut_v1"),
		format = function(value)
			return formatNumber(value)
		end,
	},
	{
		modelName = "LeaderBoardPlaytime",
		attribute = "Playtime",
		store = DataStoreService:GetOrderedDataStore("GrassGame_GlobalPlaytime_v1"),
		format = function(value)
			value = math.max(0, math.floor(value))
			local hours = math.floor(value / 3600)
			local minutes = math.floor((value % 3600) / 60)
			if hours > 0 then
				return string.format("%dh %02dm", hours, minutes)
			end
			return string.format("%dm", minutes)
		end,
	},
}

local nameCache = {}

function formatNumber(value)
	value = tonumber(value) or 0
	local absValue = math.abs(value)
	if absValue < 1000 then
		return tostring(math.floor(value))
	end
	local suffixes = {"K","M","B","T","QA","QI","SX","SP","OC","NO","DC","UD","DD","TD","QAD","QID","SXD","SPD","OCD","NOD"}
	local tier = math.max(1, math.floor(math.log10(absValue) / 3))
	if tier <= #suffixes then
		return string.format("%.2f%s", value / (10 ^ (tier * 3)), suffixes[tier])
	end
	return string.format("%.2e", value):upper()
end

local function getPlayerName(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end

	local success, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	if success and name then
		nameCache[userId] = name
		return name
	end

	return "User " .. tostring(userId)
end

local function getList(config)
	local model = boards:WaitForChild(config.modelName)
	local cube = model:WaitForChild("Cube")
	local surfaceGui = cube:WaitForChild("SurfaceGui")
	return surfaceGui:WaitForChild("LeaderboardRoot"):WaitForChild("PlayerList")
end

local function writePlayer(config, player)
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end

	local value = player:GetAttribute(config.attribute) or 0
	value = math.max(0, math.floor(value))

	local success, err = pcall(function()
		config.store:SetAsync(tostring(player.UserId), value)
	end)

	if not success then
		warn("Leaderboard write failed:", config.attribute, player.Name, err)
	end
end

local function writeAllOnlinePlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		for _, config in ipairs(CONFIG) do
			writePlayer(config, player)
		end
	end
end

local function clearRows(list)
	for rank = 1, TOP_COUNT do
		local row = list:FindFirstChild("Rank" .. rank)
		if row then
			local nameLabel = row:FindFirstChild("PlayerName")
			local valueLabel = row:FindFirstChild("Value")
			if nameLabel then nameLabel.Text = "---" end
			if valueLabel then valueLabel.Text = "-" end
		end
	end
end

local function refreshBoard(config)
	local list = getList(config)

	local success, pages = pcall(function()
		return config.store:GetSortedAsync(false, TOP_COUNT)
	end)

	if not success then
		warn("Leaderboard read failed:", config.attribute, pages)
		return
	end

	clearRows(list)

	local entries = pages:GetCurrentPage()
	for rank, entry in ipairs(entries) do
		if rank > TOP_COUNT then
			break
		end

		local row = list:FindFirstChild("Rank" .. rank)
		if row then
			local userId = tonumber(entry.key)
			local nameLabel = row:FindFirstChild("PlayerName")
			local valueLabel = row:FindFirstChild("Value")

			if nameLabel then
				nameLabel.Text = userId and getPlayerName(userId) or tostring(entry.key)
			end
			if valueLabel then
				valueLabel.Text = config.format(entry.value)
			end
		end
	end
end

local function refreshAll()
	for _, config in ipairs(CONFIG) do
		refreshBoard(config)
	end
end

Players.PlayerRemoving:Connect(function(player)
	for _, config in ipairs(CONFIG) do
		writePlayer(config, player)
	end
end)

task.spawn(function()
	task.wait(5)

	while true do
		writeAllOnlinePlayers()
		refreshAll()
		task.wait(UPDATE_INTERVAL)
	end
end)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local boards = workspace:WaitForChild("Boards"):WaitForChild("Plains")

local UPDATE_INTERVAL = 60
local TOP_COUNT = 100

local CONFIG = {
	{
		modelName = "LeaderBoardResets",
		attribute = "TotalResets",
		store = DataStoreService:GetOrderedDataStore("GrassGame_GlobalResets_v2"),
		format = function(value)
			return formatNumber(value)
		end,
	},
	{
		modelName = "LeaderBoardGrass",
		attribute = "TotalGrassEarned",
		store = DataStoreService:GetOrderedDataStore("GrassGame_GlobalGrassEarned_v2"),
		format = function(value)
			return formatNumber(value)
		end,
	},
	{
		modelName = "LeaderBoardPlaytime",
		attribute = "Playtime",
		store = DataStoreService:GetOrderedDataStore("GrassGame_GlobalPlaytime_v2"),
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

-- Season 2 starts from each player's first loaded stats after this update.
-- Baselines persist across servers so old totals never repopulate the new boards.
local baselineStore = DataStoreService:GetDataStore("GrassGame_LeaderboardSeason2Baselines")
local baselines = {}
local baselineKeys = {"TotalResets", "TotalGrassEarned", "Playtime"}

local function getBaseline(player)
    local userId = player.UserId
    if baselines[userId] then
        return baselines[userId]
    end

    local initial = {}
    for _, attribute in ipairs(baselineKeys) do
        initial[attribute] = math.max(0, math.floor(tonumber(player:GetAttribute(attribute)) or 0))
    end

    local success, stored = pcall(function()
        return baselineStore:UpdateAsync(tostring(userId), function(previous)
            if type(previous) == "table" then
                return previous
            end
            return initial
        end)
    end)
    if not success or type(stored) ~= "table" then
        warn("Leaderboard season baseline failed:", player.Name, stored)
        return nil
    end
    baselines[userId] = stored
    return stored
end

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

-- Update the existing board text without changing its Studio layout.
local function updateGrassBoardLabels()
    local model = boards:FindFirstChild("LeaderBoardGrass")
    if not model then return end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            local upper = string.upper(descendant.Text)
            if string.find(upper, "MOST GRASS CUT", 1, true) then
                descendant.Text = "MOST GRASS EARNED"
            end
        end
    end
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

	local baseline = getBaseline(player)
    if not baseline then
        return
    end
    local value = player:GetAttribute(config.attribute) or 0
    value = math.max(0, math.floor(value - (tonumber(baseline[config.attribute]) or 0)))

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
	updateGrassBoardLabels()
	for _, config in ipairs(CONFIG) do
		refreshBoard(config)
	end
end

Players.PlayerRemoving:Connect(function(player)
    for _, config in ipairs(CONFIG) do
        writePlayer(config, player)
    end
    baselines[player.UserId] = nil
end)

task.spawn(function()
	task.wait(5)

	while true do
		writeAllOnlinePlayers()
		refreshAll()
		task.wait(UPDATE_INTERVAL)
	end
end)

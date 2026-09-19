local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UpgradeConfig = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local playerStore = DataStoreService:GetDataStore("GrassGame_PlayerData_v1")

local AUTOSAVE_INTERVAL = 60
local MAX_RETRIES = 3

local DEFAULTS = {
	Coins = 0,
	GrassStored = 0,
	ResetTokens = 0,
	XP = 0,
	Level = 1,
	PlainsGrassRemaining = 500,
	ForestGrassRemaining = 500,
}

local loadedPlayers = {}
local savingPlayers = {}

local function getKey(player)
	return "Player_" .. player.UserId
end

local function withRetries(callback)
	local lastError

	for attempt = 1, MAX_RETRIES do
		local success, result = pcall(callback)
		if success then
			return true, result
		end

		lastError = result
		warn("DataStore attempt", attempt, "failed:", result)
		task.wait(attempt * 1.5)
	end

	return false, lastError
end

local function applyDefaults(player)
	for attributeName, defaultValue in pairs(DEFAULTS) do
		if player:GetAttribute(attributeName) == nil then
			player:SetAttribute(attributeName, defaultValue)
		end
	end

	if player:GetAttribute("GrassCapacity") == nil then
		player:SetAttribute("GrassCapacity", 20)
	end
end

local function applyLoadedData(player, data)
	applyDefaults(player)

	if type(data) ~= "table" then
		return
	end

	local stats = data.Stats
	if type(stats) == "table" then
		for attributeName, defaultValue in pairs(DEFAULTS) do
			local value = stats[attributeName]
			if typeof(value) == typeof(defaultValue) then
				player:SetAttribute(attributeName, value)
			end
		end
	end

	local upgrades = data.Upgrades
	if type(upgrades) == "table" then
		for upgradeName in pairs(UpgradeConfig) do
			if upgrades[upgradeName] == true then
				player:SetAttribute(upgradeName .. "Bought", true)
			end
		end
	end
end

local function buildSaveData(player)
	local stats = {}
	for attributeName, defaultValue in pairs(DEFAULTS) do
		local value = player:GetAttribute(attributeName)
		if typeof(value) ~= typeof(defaultValue) then
			value = defaultValue
		end
		stats[attributeName] = value
	end

	local upgrades = {}
	for upgradeName in pairs(UpgradeConfig) do
		if player:GetAttribute(upgradeName .. "Bought") == true then
			upgrades[upgradeName] = true
		end
	end

	return {
		Version = 2,
		Stats = stats,
		Upgrades = upgrades,
		LastSave = os.time(),
	}
end

local function savePlayer(player)
	if not loadedPlayers[player] then
		return true
	end

	if savingPlayers[player] then
		return false
	end

	if player:GetAttribute("DataLoadFailed") == true then
		return false
	end

	savingPlayers[player] = true
	local data = buildSaveData(player)
	local key = getKey(player)

	local success, err = withRetries(function()
		return playerStore:UpdateAsync(key, function(_oldData)
			return data
		end)
	end)

	savingPlayers[player] = nil

	if not success then
		warn("FAILED TO SAVE", player.Name, err)
		return false
	end

	player:SetAttribute("LastSavedAt", os.time())
	return true
end

local function loadPlayer(player)
	player:SetAttribute("DataLoaded", false)
	player:SetAttribute("DataLoadFailed", false)

	local key = getKey(player)
	local success, dataOrError = withRetries(function()
		return playerStore:GetAsync(key)
	end)

	if not player.Parent then
		return
	end

	if not success then
		warn("FAILED TO LOAD", player.Name, dataOrError)

		if RunService:IsStudio() then
			warn("Studio DataStore access failed. Using temporary defaults; this session will NOT save.")
			player:SetAttribute("DataLoadFailed", true)
			applyDefaults(player)
			loadedPlayers[player] = true
			player:SetAttribute("DataLoaded", true)
			return
		end

		player:Kick("Your data could not be loaded. Please rejoin in a moment.")
		return
	end

	applyLoadedData(player, dataOrError)
	loadedPlayers[player] = true
	player:SetAttribute("DataLoaded", true)

	print("DATA LOADED:", player.Name)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	loadedPlayers[player] = nil
	savingPlayers[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)

		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(savePlayer, player)
			task.wait(0.2)
		end
	end
end)

game:BindToClose(function()
	local players = Players:GetPlayers()
	local pending = #players

	if pending == 0 then
		return
	end

	for _, player in ipairs(players) do
		task.spawn(function()
			savePlayer(player)
			pending -= 1
		end)
	end

	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

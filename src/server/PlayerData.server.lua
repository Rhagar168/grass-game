local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UpgradeConfig = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local playerStore = DataStoreService:GetDataStore("GrassGame_PlayerData_v1")

local AUTOSAVE_INTERVAL = 30
local GRASS_SAVE_DELAY = 2
local MAX_RETRIES = 3
local STUDIO_GRASS_RESET_VERSION = 1

local DEFAULTS = {
	Coins = 0,
	GrassStored = 0,
	ResetTokens = 0,
	XP = 0,
	Level = 1,
	PlainsGrassRemaining = 500,
	ForestGrassRemaining = 1000,
	SavannaGrassRemaining = 1000,
	JungleGrassRemaining = 1000,
	PlainsResetCount = 0,
	ForestResetCount = 0,
	SavannaResetCount = 0,
	JungleResetCount = 0,
	ForestUnlocked = false,
	SavannaUnlocked = false,
	JungleUnlocked = false,
}

local loadedPlayers = {}
local savingPlayers = {}
local pendingSaves = {}
local grassSaveVersions = {}

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
		-- One-time biome count migration:
		-- old saves used 500 as the full Forest/Savanna count.
		-- Only full old values are upgraded, so real cutting progress is preserved.
		if stats.ForestGrassRemaining == 500 then
			stats.ForestGrassRemaining = 1000
		end
		if stats.SavannaGrassRemaining == 500 then
			stats.SavannaGrassRemaining = 1000
		end

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
		StudioGrassResetVersion = player:GetAttribute("StudioGrassResetVersion") or 0,
		LastSave = os.time(),
	}
end

local function savePlayer(player)
	if not loadedPlayers[player] then
		return true
	end

	if player:GetAttribute("DataLoadFailed") == true then
		return false
	end

	-- Never drop a save request. If a save is already running, remember that
	-- another pass is required with the newest player attributes.
	if savingPlayers[player] then
		pendingSaves[player] = true
		return true
	end

	savingPlayers[player] = true
	local overallSuccess = true

	repeat
		pendingSaves[player] = nil

		-- Build the snapshot immediately before this write so a queued pass
		-- always contains the newest grass progress.
		local data = buildSaveData(player)
		local key = getKey(player)

		local success, err = withRetries(function()
			return playerStore:UpdateAsync(key, function(oldData)
				-- Protect grass progress from an older server finishing its save late.
				-- During the same reset cycle, GrassRemaining is only allowed to go DOWN.
				-- A higher ResetCount means the player really reset that biome, so the
				-- refilled grass count from the new cycle is allowed.
				if type(oldData) == "table" and type(oldData.Stats) == "table" then
					for _, biomeId in ipairs({"Plains", "Forest", "Savanna", "Jungle"}) do
						local remainingKey = biomeId .. "GrassRemaining"
						local resetKey = biomeId .. "ResetCount"

						local oldRemaining = oldData.Stats[remainingKey]
						local newRemaining = data.Stats[remainingKey]
						local oldReset = oldData.Stats[resetKey] or 0
						local newReset = data.Stats[resetKey] or 0

						if typeof(oldRemaining) == "number" and typeof(newRemaining) == "number" then
							if newReset < oldReset then
								-- This snapshot is from an older reset cycle.
								data.Stats[resetKey] = oldReset
								data.Stats[remainingKey] = oldRemaining
							elseif newReset == oldReset then
								-- Same cycle: never let a stale save restore cut grass.
								data.Stats[remainingKey] = math.min(oldRemaining, newRemaining)
							end
						end
					end
				end

				return data
			end)
		end)

		if not success then
			warn("FAILED TO SAVE", player.Name, err)
			overallSuccess = false
		else
			player:SetAttribute("LastSavedAt", os.time())
		end
	until not pendingSaves[player]

	savingPlayers[player] = nil
	return overallSuccess
end

local function setupGrassProgressSaving(player)
	-- Each biome needs its own debounce. A shared version counter meant that
	-- spawning/updating another biome could cancel the pending save for Plains.
	grassSaveVersions[player] = {}

	for biomeId in pairs({
		Plains = true,
		Forest = true,
		Savanna = true,
		Jungle = true,
	}) do
		local currentBiomeId = biomeId
		local attributeName = currentBiomeId .. "GrassRemaining"
		grassSaveVersions[player][currentBiomeId] = 0

		player:GetAttributeChangedSignal(attributeName):Connect(function()
			if not loadedPlayers[player] or player:GetAttribute(currentBiomeId .. "Resetting") == true then
				return
			end

			local versions = grassSaveVersions[player]
			if not versions then
				return
			end

			versions[currentBiomeId] += 1
			local version = versions[currentBiomeId]

			task.delay(GRASS_SAVE_DELAY, function()
				local latestVersions = grassSaveVersions[player]
				if player.Parent
					and latestVersions
					and latestVersions[currentBiomeId] == version then
					print("GRASS SAVE:", currentBiomeId, player:GetAttribute(attributeName))
					savePlayer(player)
				end
			end)
		end)
	end
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

	-- Repair old/inconsistent saves: once a biome has been completed, its next
	-- gateway must stay unlocked even if an older save missed the unlock flag.
	if (player:GetAttribute("PlainsGrassRemaining") or 500) <= 0 then
		player:SetAttribute("ForestUnlocked", true)
	end
	if (player:GetAttribute("ForestGrassRemaining") or 1000) <= 0 then
		player:SetAttribute("SavannaUnlocked", true)
	end
	if (player:GetAttribute("SavannaGrassRemaining") or 1000) <= 0 then
		player:SetAttribute("JungleUnlocked", true)
	end

	-- Unlock progression is monotonic: later unlocked biomes imply all earlier
	-- gateways were unlocked too.
	if player:GetAttribute("JungleUnlocked") == true then
		player:SetAttribute("SavannaUnlocked", true)
		player:SetAttribute("ForestUnlocked", true)
	elseif player:GetAttribute("SavannaUnlocked") == true then
		player:SetAttribute("ForestUnlocked", true)
	end

	-- One-time Studio-only grass reset for testing new biome counts.
	-- The marker is saved so this does not refill grass every time Play starts.
	if RunService:IsStudio() then
		local savedVersion = 0
		if type(dataOrError) == "table" then
			savedVersion = dataOrError.StudioGrassResetVersion or 0
		end

		if savedVersion < STUDIO_GRASS_RESET_VERSION then
			player:SetAttribute("PlainsGrassRemaining", 500)
			player:SetAttribute("ForestGrassRemaining", 1000)
			player:SetAttribute("SavannaGrassRemaining", 1000)
			player:SetAttribute("StudioGrassResetVersion", STUDIO_GRASS_RESET_VERSION)
		end
	end

	loadedPlayers[player] = true
	setupGrassProgressSaving(player)
	player:SetAttribute("DataLoaded", true)

	-- Persist repaired unlock flags immediately instead of waiting for autosave.
	task.spawn(savePlayer, player)

	print("DATA LOADED:", player.Name,
		"| Plains:", player:GetAttribute("PlainsGrassRemaining"),
		"| Forest:", player:GetAttribute("ForestGrassRemaining"),
		"| Savanna:", player:GetAttribute("SavannaGrassRemaining"),
		"| Jungle:", player:GetAttribute("JungleGrassRemaining"),
		"| ForestUnlocked:", player:GetAttribute("ForestUnlocked"),
		"| SavannaUnlocked:", player:GetAttribute("SavannaUnlocked"),
		"| JungleUnlocked:", player:GetAttribute("JungleUnlocked")
	)
end

-- Studio testing command: type /resetforestunlock in chat.
-- This only resets the saved Forest gateway unlock for the current Studio test player.
local function setupStudioResetCommand(player)
	if not RunService:IsStudio() then
		return
	end

	player.Chatted:Connect(function(message)
		if string.lower(message) ~= "/resetforestunlock" then
			return
		end

		player:SetAttribute("ForestUnlocked", false)
		player:SetAttribute("SavannaUnlocked", false)
		player:SetAttribute("JungleUnlocked", false)
		savePlayer(player)
		print("FOREST UNLOCK RESET FOR:", player.Name, "- rejoin to test the gateway again.")
	end)
end

Players.PlayerAdded:Connect(function(player)
	setupStudioResetCommand(player)
	task.spawn(loadPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupStudioResetCommand(player)
	task.spawn(loadPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	-- PlayerRemoving must keep the player marked as loaded until the LAST write
	-- has finished. Otherwise a queued save can be skipped on a fast disconnect.
	pendingSaves[player] = true

	local deadline = os.clock() + 15
	while savingPlayers[player] and os.clock() < deadline do
		task.wait(0.05)
	end

	-- The previous write may already have consumed pendingSaves, so force one
	-- fresh final pass from the attributes that exist right now.
	pendingSaves[player] = nil
	savePlayer(player)

	deadline = os.clock() + 15
	while savingPlayers[player] and os.clock() < deadline do
		task.wait(0.05)
	end

	loadedPlayers[player] = nil
	savingPlayers[player] = nil
	pendingSaves[player] = nil
	grassSaveVersions[player] = nil
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
			pendingSaves[player] = true

			local playerDeadline = os.clock() + 20
			while savingPlayers[player] and os.clock() < playerDeadline do
				task.wait(0.05)
			end

			pendingSaves[player] = nil
			savePlayer(player)

			while savingPlayers[player] and os.clock() < playerDeadline do
				task.wait(0.05)
			end

			pending -= 1
		end)
	end

	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

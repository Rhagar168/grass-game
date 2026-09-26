local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

-- ========================================
-- UPDATE SETTING EVENT
-- ========================================

local updateSettingEvent =
	ReplicatedStorage:FindFirstChild("UpdateSetting")

if not updateSettingEvent then
	updateSettingEvent = Instance.new("RemoteEvent")
	updateSettingEvent.Name = "UpdateSetting"
	updateSettingEvent.Parent = ReplicatedStorage
end

-- ========================================
-- ALLOWED SETTINGS
-- ========================================

local ALLOWED_SETTINGS = {
	GrassPopups = true,
	DamagePopups = true,
	CriticalPopups = true,
	InstantSell = true,
	InstantZoneSell = true,
	InstantSellPopups = true,
	XPPopups = true,
	Music = true,
	SoundEffects = true,
}

-- ========================================
-- ALLOWED TOOL LEVELS
-- ========================================

local ALLOWED_TOOL_LEVELS = {
	[1] = true,
	[10] = true,
	[25] = true,
	[50] = true,
	[100] = true,
}

-- ========================================
-- UPDATE
-- ========================================

updateSettingEvent.OnServerEvent:Connect(function(
	player,
	settingName,
	value
)

	if typeof(settingName) ~= "string" then
		return
	end

	-- ========================================
	-- HIGHEST SEEN TOOL LEVEL
	-- ========================================

	if settingName == "HighestSeenToolLevel" then

		if typeof(value) ~= "number" then
			return
		end

		value = math.floor(value)

		if not ALLOWED_TOOL_LEVELS[value] then
			return
		end

		local playerLevel =
			player:GetAttribute("Level") or 1

		-- Hráč nemůže označit tool,
		-- který ještě neodemkl
		if value > playerLevel then
			return
		end

		local current =
			player:GetAttribute(
				"HighestSeenToolLevel"
			) or 1

		-- Hodnota může pouze růst
		if value <= current then
			return
		end

		player:SetAttribute(
			"HighestSeenToolLevel",
			value
		)

		return
	end

	-- ========================================
	-- NORMAL SETTINGS
	-- ========================================

	if not ALLOWED_SETTINGS[settingName] then
		warn(
			"[Settings] Invalid setting:",
			settingName
		)

		return
	end

	if typeof(value) ~= "boolean" then
		warn(
			"[Settings] Invalid value:",
			settingName,
			value
		)

		return
	end

	local attributeName =
		"Setting_" .. settingName

	player:SetAttribute(
		attributeName,
		value
	)
end)

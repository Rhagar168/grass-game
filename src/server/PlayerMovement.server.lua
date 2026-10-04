local Players = game:GetService("Players")

local BASE_WALK_SPEED = 16
local JUMP_POWER = 50
local MAX_CAMERA_ZOOM = 25

local function updateWalkSpeed(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local multiplier = tonumber(player:GetAttribute("AchievementMoveSpeedMultiplier")) or 1
	humanoid.WalkSpeed = BASE_WALK_SPEED * multiplier
end

local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.UseJumpPower = true
	humanoid.JumpPower = JUMP_POWER
	updateWalkSpeed(player)
end

local function setupPlayer(player)
	player.CameraMaxZoomDistance = MAX_CAMERA_ZOOM
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	player:GetAttributeChangedSignal("AchievementMoveSpeedMultiplier"):Connect(function()
		updateWalkSpeed(player)
	end)

	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

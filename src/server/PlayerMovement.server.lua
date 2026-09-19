local Players = game:GetService("Players")

local JUMP_POWER = 50
local MAX_CAMERA_ZOOM = 18

local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.UseJumpPower = true
	humanoid.JumpPower = JUMP_POWER
end

local function setupPlayer(player)
	player.CameraMaxZoomDistance = MAX_CAMERA_ZOOM
	player.CharacterAdded:Connect(setupCharacter)

	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

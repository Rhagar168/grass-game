local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainUI = playerGui:WaitForChild("MainUI")
local menu = mainUI:WaitForChild("CoreLabMenu")

local lab = workspace:WaitForChild("CoreLab")
local zone = lab:WaitForChild("CoreLabZone")

local wasInside = false
menu.Visible = false

local function isInside()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	local offset = root.Position - zone.Position
	local radius = math.max(zone.Size.X, zone.Size.Y, zone.Size.Z) * 0.5
	return Vector2.new(offset.X, offset.Z).Magnitude <= radius
		and math.abs(offset.Y) <= 10
end

while true do
	local inside = isInside()

	if inside ~= wasInside then
		wasInside = inside
		menu.Visible = inside
	end

	task.wait(0.1)
end

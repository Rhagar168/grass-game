local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

StarterGui:SetCoreGuiEnabled(
	Enum.CoreGuiType.Backpack,
	false
)

local function equipShears(character)
	local backpack =
		player:WaitForChild("Backpack")

	local humanoid =
		character:WaitForChild("Humanoid")

	local tool =
		backpack:WaitForChild("BasicShears")

	humanoid:EquipTool(tool)
end

player.CharacterAdded:Connect(equipShears)

if player.Character then
	equipShears(player.Character)
end
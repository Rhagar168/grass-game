local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local folder = Instance.new("Folder")
folder.Name = "LocalPets"
folder.Parent = workspace

local visuals = {}

local rarityColors = {
	Common = Color3.fromRGB(175, 185, 190),
	Rare = Color3.fromRGB(65, 145, 255),
	Epic = Color3.fromRGB(175, 80, 255),
	Legendary = Color3.fromRGB(255, 185, 45),
	Mythic = Color3.fromRGB(255, 80, 125),
}

local function clear()
	for _, part in pairs(visuals) do part:Destroy() end
	table.clear(visuals)
end

local function rebuild()
	clear()
	for slot = 1, PetConfig.MaxEquipped do
		local id = player:GetAttribute("EquippedPet" .. slot) or ""
		local config = PetConfig.GetPet(id)
		if config then
			local part = Instance.new("Part")
			part.Name = id
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(1.6, 1.6, 1.6)
			part.Material = Enum.Material.SmoothPlastic
			part.Color = rarityColors[config.Rarity] or Color3.new(1,1,1)
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Parent = folder

			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromOffset(150, 32)
			gui.StudsOffset = Vector3.new(0, 1.5, 0)
			gui.AlwaysOnTop = true
			gui.MaxDistance = 45
			gui.Parent = part
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1,1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.Michroma
			label.TextSize = 10
			label.TextColor3 = Color3.new(1,1,1)
			label.TextStrokeTransparency = 0.35
			label.Text = config.DisplayName .. "  " .. config.Damage .. " DMG"
			label.Parent = gui
			visuals[slot] = part
		end
	end
end

for slot = 1, PetConfig.MaxEquipped do
	player:GetAttributeChangedSignal("EquippedPet" .. slot):Connect(rebuild)
end
rebuild()

RunService.RenderStepped:Connect(function(dt)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local t = os.clock()
	for slot, part in pairs(visuals) do
		local side = (slot - 2) * 2.1
		local target = root.CFrame:PointToWorldSpace(Vector3.new(side, 1.1 + math.sin(t * 3 + slot) * 0.18, 3.2))
		part.Position = part.Position:Lerp(target, math.clamp(dt * 8, 0, 1))
	end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local hatchEvent = ReplicatedStorage:WaitForChild("PetHatch")
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local eggsFolder = workspace:WaitForChild("Eggs")

local configs = {
	Savanna = {model = "SavannaEgg", title = "SAVANNA EGG", color = Color3.fromRGB(230, 155, 49)},
	Tundra = {model = "FrozenEgg", title = "FROZEN EGG", color = Color3.fromRGB(75, 191, 255)},
	Beach = {model = "BeachEgg", title = "BEACH EGG", color = Color3.fromRGB(58, 219, 160)},
}

local eggs = {}
for biome, config in pairs(configs) do
	local folder = eggsFolder:FindFirstChild(biome)
	local model = folder and (folder:FindFirstChild(config.model) or folder:FindFirstChild("Model"))
	if model and model:IsA("Model") then
		table.insert(eggs, {
			id = biome,
			model = model,
			config = config,
			prompt = model:FindFirstChild("EggPrompt", true),
		})
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "PetEggHatchGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Visible = false
overlay.Parent = gui

local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.fromOffset(410, 250)
window.BackgroundColor3 = Color3.fromRGB(23, 30, 40)
window.Visible = false
window.Parent = gui

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

round(window, 16)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Parent = window

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(20, 14)
title.Size = UDim2.new(1, -85, 0, 40)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = window

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -52, 0, 15)
close.Size = UDim2.fromOffset(35, 35)
close.BackgroundColor3 = Color3.fromRGB(190, 55, 65)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBlack
close.TextSize = 18
close.Parent = window
round(close, 9)

local function makeButton(label, x)
	local button = Instance.new("TextButton")
	button.Position = UDim2.new(x, 0, 0, 85)
	button.Size = UDim2.new(0.42, 0, 0, 90)
	button.BackgroundColor3 = Color3.fromRGB(49, 154, 95)
	button.Text = label
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 22
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = window
	round(button, 12)
	return button
end

local hatch1 = makeButton("HATCH x1", 0.055)
local hatch3 = makeButton("HATCH x3", 0.525)

local message = Instance.new("TextLabel")
message.Position = UDim2.fromOffset(16, 188)
message.Size = UDim2.new(1, -32, 0, 45)
message.BackgroundTransparency = 1
message.TextWrapped = true
message.TextColor3 = Color3.fromRGB(255, 220, 125)
message.Font = Enum.Font.GothamBold
message.TextSize = 16
message.Parent = window

local selected = nil
local pending = false

local function closeWindow()
	selected = nil
	pending = false
	window.Visible = false
	overlay.Visible = false
end

local function openWindow(egg)
	selected = egg
	pending = false
	title.Text = egg.config.title
	stroke.Color = egg.config.color
	local config = PetConfig.Eggs[egg.id]
	if config then
		local currency = config.Currency or "Coins"
		hatch1.Text = "HATCH x1\n" .. config.Price .. " " .. currency
		hatch3.Text = "HATCH x3\n" .. (config.Price * 3) .. " " .. currency
		message.Text = ""
	else
		hatch1.Text = "HATCH x1"
		hatch3.Text = "HATCH x3"
		message.Text = "This egg is coming soon!"
	end
	window.Visible = true
	overlay.Visible = true
end

close.MouseButton1Click:Connect(closeWindow)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape and window.Visible then
		closeWindow()
	end
end)

local function requestHatch(amount)
	if not selected or pending then return end
	if not PetConfig.Eggs[selected.id] then
		message.Text = "This egg is coming soon!"
		return
	end
	pending = true
	message.Text = "Hatching..."
	hatchEvent:FireServer("Hatch", selected.id, amount)
	task.delay(4, function()
		if pending then
			pending = false
			message.Text = "No server response. Check Output."
		end
	end)
end

hatch1.MouseButton1Click:Connect(function() requestHatch(1) end)
hatch3.MouseButton1Click:Connect(function() requestHatch(3) end)

hatchEvent.OnClientEvent:Connect(function(action, eggId, data, currency)
	if not selected or selected.id ~= eggId then return end
	pending = false
	if action == "Hatched" then
		local names = {}
		local results = typeof(data) == "table" and data or {data}
		for _, id in ipairs(results) do
			local pet = PetConfig.GetPet(id)
			table.insert(names, pet and pet.DisplayName or tostring(id))
		end
		message.Text = "You hatched: " .. table.concat(names, ", ")
	elseif action == "NotEnough" then
		message.Text = "Not enough " .. tostring(currency or "Coins") .. "! Need " .. tostring(data)
	elseif action == "Locked" then
		message.Text = "Unlock this biome first!"
	elseif action == "TooFar" then
		message.Text = "Move closer to the egg!"
	elseif action == "Unavailable" then
		message.Text = "This egg is coming soon!"
	end
end)

for _, egg in ipairs(eggs) do
	if egg.prompt and egg.prompt:IsA("ProximityPrompt") then
		egg.prompt.Triggered:Connect(function()
			openWindow(egg)
		end)
	end
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.15 then return end
	elapsed = 0

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local nearest, bestDistance = nil, 18
	if root then
		for _, egg in ipairs(eggs) do
			local distance = (egg.model:GetPivot().Position - root.Position).Magnitude
			if distance < bestDistance then
				nearest, bestDistance = egg, distance
			end
		end
	end

	for _, egg in ipairs(eggs) do
		local info = egg.model:FindFirstChild("EggPetInfo", true)
		local billboard = info and info:FindFirstChild("PetInfoBillboard")
		if billboard and billboard:IsA("BillboardGui") then
			billboard.Enabled = egg == nearest and not window.Visible
		end
	end

	if selected and root and (selected.model:GetPivot().Position - root.Position).Magnitude > 22 then
		closeWindow()
	end
end)

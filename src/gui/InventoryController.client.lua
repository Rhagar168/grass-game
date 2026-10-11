local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local petAction = ReplicatedStorage:WaitForChild("PetAction")
local mainUI = script.Parent
local bottomMenu = mainUI:WaitForChild("BottomMenu")
local button = bottomMenu:WaitForChild("InventoryButton")
local xpFrame = mainUI:FindFirstChild("XPFrame")

local COLORS = {
	bg = Color3.fromRGB(18, 27, 23),
	panel = Color3.fromRGB(28, 32, 38),
	card = Color3.fromRGB(38, 44, 53),
	green = Color3.fromRGB(48, 180, 82),
	white = Color3.fromRGB(246, 249, 253),
	muted = Color3.fromRGB(174, 182, 194),
}
local rarity = {
	Common = Color3.fromRGB(181, 194, 203),
	Rare = Color3.fromRGB(75, 164, 255),
	Epic = Color3.fromRGB(181, 105, 255),
	Legendary = Color3.fromRGB(255, 190, 66),
	Mythic = Color3.fromRGB(255, 93, 142),
}
local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do instance[key] = value end
	instance.Parent = parent
	return instance
end
local function corner(parent, px)
	make("UICorner", {CornerRadius = UDim.new(0, px)}, parent)
end
local function stroke(parent, color, width)
	make("UIStroke", {Color = color, Thickness = width}, parent)
end
local MICHROMA = Font.new("rbxasset://fonts/families/Michroma.json")
local function applyFont(label)
	label.FontFace = MICHROMA
end
local function text(parent, value, size, color)
	local label = make("TextLabel", {
		BackgroundTransparency = 1,
		Text = value,
		TextSize = size,
		TextColor3 = color or COLORS.white,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = MICHROMA,
	}, parent)
	return label
end

local window = mainUI:WaitForChild("InventoryWindow")
local header = window:WaitForChild("Title")
local close = window:WaitForChild("Close")
local tabs = window:WaitForChild("Tabs")
local petsTab = tabs:WaitForChild("PETSTab")
local potionsTab = tabs:WaitForChild("POTIONSTab")
local info = window:WaitForChild("Info")
local content = window:WaitForChild("PetsContent")
local equippedTitle = content:WaitForChild("EquippedTitle")
local equippedList = content:WaitForChild("EquippedPets")
local unequippedTitle = content:WaitForChild("PetsTitle")
local list = content:WaitForChild("PetList")
local empty = content:WaitForChild("Empty")
local activeTab = "PETS"

local function equippedIds()
	local ids = {}
	for slot = 1, PetConfig.MaxEquipped do
		local id = player:GetAttribute("EquippedPet" .. slot)
		if typeof(id) == "string" and id ~= "" then
			ids[id] = true
		end
	end
	return ids
end

local function inventory()
	local counts = {}
	local total = 0
	local raw = player:GetAttribute("PetInventory") or ""
	for id in string.gmatch(raw, "[^,]+") do
		if PetConfig.GetPet(id) then
			counts[id] = (counts[id] or 0) + 1
			total += 1
		end
	end
	return counts, total
end

local function render()
	local isPets = activeTab == "PETS"
	petsTab.BackgroundColor3 = isPets and Color3.fromRGB(48, 180, 82) or Color3.fromRGB(35, 42, 45)
	potionsTab.BackgroundColor3 = not isPets and Color3.fromRGB(48, 180, 82) or Color3.fromRGB(35, 42, 45)
	content.Visible = isPets

	if not isPets then
		info.Text = "POTIONS - Coming soon"
		empty.Visible = false
		return
	end

	local counts, total = inventory()
	local equipped = equippedIds()
	local equippedCount = 0
	for _ in pairs(equipped) do equippedCount += 1 end
	info.Text = string.format("Total pets: %d", total)
	equippedTitle.Text = string.format("EQUIPPED PETS  %d/%d", equippedCount, PetConfig.MaxEquipped)

	for _, parent in ipairs({list, equippedList}) do
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("Frame") or child:IsA("ImageButton") then child:Destroy() end
		end
	end

	local ids = {}
	for id in pairs(counts) do table.insert(ids, id) end
	table.sort(ids, function(a, b)
		local pa, pb = PetConfig.GetPet(a), PetConfig.GetPet(b)
		if pa.Damage ~= pb.Damage then return pa.Damage > pb.Damage end
		return pa.DisplayName < pb.DisplayName
	end)

	empty.Visible = #ids == 0
	empty.Text = "No pets yet! Hatch an egg to get your first pet."

	for order, id in ipairs(ids) do
		local pet = PetConfig.GetPet(id)
		local active = equipped[id] == true
		local target = active and equippedList or list
		local accent = rarity[pet.Rarity] or COLORS.white

		-- Celá kartička funguje jako tlačítko Equip / Unequip.
		local card = make("ImageButton", {
			Name = id,
			LayoutOrder = order,
			Size = UDim2.fromOffset(160, 150),
			BackgroundColor3 = COLORS.card,
			BorderSizePixel = 0,
			Image = "",
			AutoButtonColor = false,
			ZIndex = 12,
		}, target)
		corner(card, 9)
		stroke(card, accent, active and 2.5 or 1.5)

		local portrait = make("Frame", {
			Name = "Portrait",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 7),
			Size = UDim2.new(0.72, 0, 0.60, 0),
			BackgroundColor3 = accent:Lerp(COLORS.card, 0.77),
			BorderSizePixel = 0,
			ZIndex = 13,
		}, card)
		corner(portrait, 8)

		-- Obrázek se automaticky použije, jakmile PetConfig obsahuje ImageId.
		local imageId = pet.ImageId
		local hasImage = (typeof(imageId) == "string" and imageId ~= "" and imageId ~= "0")
			or (typeof(imageId) == "number" and imageId > 0)
		if hasImage then
			make("ImageLabel", {
				Name = "PetImage",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.02, 0.02),
				Size = UDim2.fromScale(0.96, 0.96),
				Image = typeof(imageId) == "number" and ("rbxassetid://" .. imageId) or (string.find(imageId, "rbxasset") and imageId or ("rbxassetid://" .. imageId)),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 14,
			}, portrait)
		else
			local placeholder = text(portrait, string.upper(string.sub(pet.DisplayName, 1, 1)), 44, accent)
			placeholder.Name = "Placeholder"
			placeholder.Size = UDim2.fromScale(1, 1)
			placeholder.TextXAlignment = Enum.TextXAlignment.Center
			placeholder.TextYAlignment = Enum.TextYAlignment.Center
			placeholder.TextScaled = true
			make("UITextSizeConstraint", {MinTextSize = 15, MaxTextSize = 44}, placeholder)
			placeholder.ZIndex = 14
		end

		local count = text(card, "x" .. counts[id], 19, COLORS.white)
		count.Name = "Count"
		count.AnchorPoint = Vector2.new(1, 0)
		count.Position = UDim2.new(1, -7, 0, 6)
		count.Size = UDim2.new(0.48, 0, 0, 28)
		count.TextXAlignment = Enum.TextXAlignment.Right
		count.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		count.TextStrokeTransparency = 0.15
		count.ZIndex = 16

		local name = text(card, pet.DisplayName, 13, COLORS.white)
		name.Name = "PetName"
		name.Position = UDim2.new(0, 5, 0.62, 0)
		name.Size = UDim2.new(1, -10, 0, 22)
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.TextScaled = true
		make("UITextSizeConstraint", {MinTextSize = 9, MaxTextSize = 15}, name)
		name.ZIndex = 14

		local damage = text(card, tostring(pet.Damage) .. " DMG", 17, accent)
		damage.Name = "Damage"
		damage.AnchorPoint = Vector2.new(0, 1)
		damage.Position = UDim2.new(0, 5, 1, -6)
		damage.Size = UDim2.new(1, -10, 0, 26)
		damage.TextXAlignment = Enum.TextXAlignment.Center
		damage.TextScaled = true
		make("UITextSizeConstraint", {MinTextSize = 11, MaxTextSize = 19}, damage)
		damage.ZIndex = 14

		if active then
			local check = text(card, "✓", 22, COLORS.green)
			check.Name = "EquippedIndicator"
			check.Position = UDim2.fromOffset(5, 3)
			check.Size = UDim2.fromOffset(28, 28)
			check.TextXAlignment = Enum.TextXAlignment.Center
			check.ZIndex = 16
		end

		card.Activated:Connect(function()
			petAction:FireServer(active and "Unequip" or "Equip", id)
		end)
	end
end

local function setOpen(value)
	if value and (player:GetAttribute("UpgradeMenuOpen") or player:GetAttribute("ToolsMenuOpen")) then
		return
	end
	window.Visible = value
	player:SetAttribute("InventoryMenuOpen", value)
	bottomMenu.Visible = not value
	if xpFrame then xpFrame.Visible = not value end
	if value then render() end
end

player:SetAttribute("InventoryMenuOpen", false)

button.Activated:Connect(function()
	setOpen(not window.Visible)
end)
close.Activated:Connect(function() setOpen(false) end)
petsTab.Activated:Connect(function() activeTab = "PETS"; render() end)
potionsTab.Activated:Connect(function() activeTab = "POTIONS"; render() end)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape and window.Visible then
		setOpen(false)
	end
end)

player:GetAttributeChangedSignal("PetInventory"):Connect(function()
	if window.Visible then render() end
end)
for slot = 1, PetConfig.MaxEquipped do
	player:GetAttributeChangedSignal("EquippedPet" .. slot):Connect(function()
		if window.Visible then render() end
	end)
end

petAction.OnClientEvent:Connect(function(action)
	if action == "EquipFull" then
		info.Text = "All 3 pet slots are full. Unequip a pet first."
	elseif window.Visible then
		render()
	end
end)

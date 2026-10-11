local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local petAction = ReplicatedStorage:WaitForChild("PetAction")
local mainUI = script.Parent
local button = mainUI:WaitForChild("BottomMenu"):WaitForChild("InventoryButton")

local old = mainUI:FindFirstChild("InventoryWindow")
if old then old:Destroy() end

local COLORS = {
	bg = Color3.fromRGB(22, 30, 40),
	panel = Color3.fromRGB(30, 42, 55),
	card = Color3.fromRGB(42, 56, 72),
	green = Color3.fromRGB(85, 203, 104),
	white = Color3.fromRGB(246, 249, 253),
	muted = Color3.fromRGB(178, 192, 207),
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

local function text(parent, value, size, color, font)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Text = value,
		TextSize = size,
		TextColor3 = color or COLORS.white,
		Font = font or Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

local window = make("Frame", {
	Name = "InventoryWindow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.48),
	Size = UDim2.new(0.88, 0, 0.76, 0),
	BackgroundColor3 = COLORS.bg,
	Visible = false,
	ZIndex = 10,
}, mainUI)
make("UISizeConstraint", {MaxSize = Vector2.new(960, 640), MinSize = Vector2.new(320, 290)}, window)
corner(window, 16)
make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(28, 39, 53), Color3.fromRGB(17, 25, 36))}, window)
stroke(window, Color3.fromRGB(72, 201, 117), 3)

local header = text(window, "INVENTORY", 27, COLORS.white, Enum.Font.GothamBlack)
header.Position = UDim2.fromOffset(25, 13)
header.Size = UDim2.new(1, -110, 0, 42)
header.ZIndex = 11

local close = make("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -15, 0, 15),
	Size = UDim2.fromOffset(40, 38),
	Text = "X",
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	TextColor3 = COLORS.white,
	BackgroundColor3 = Color3.fromRGB(195, 70, 76),
	ZIndex = 12,
}, window)
corner(close, 9)

local tabs = make("Frame", {
	Position = UDim2.fromOffset(18, 75),
	Size = UDim2.new(0, 116, 1, -96),
	BackgroundTransparency = 1,
	ZIndex = 11,
}, window)
local tabLayout = make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	Padding = UDim.new(0, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabs)

local function tab(name, order)
	local t = make("TextButton", {
		Name = name .. "Tab",
		Size = UDim2.fromOffset(116, 66),
		LayoutOrder = order,
		Text = name,
		Font = Enum.Font.GothamBlack,
		TextSize = 19,
		TextColor3 = COLORS.white,
		BackgroundColor3 = COLORS.panel,
		ZIndex = 12,
	}, tabs)
	corner(t, 9)
	return t
end

local petsTab = tab("PETS", 1)
local potionsTab = tab("POTIONS", 2)

local info = text(window, "", 15, COLORS.muted)
info.Position = UDim2.new(0, 154, 0, 76)
info.Size = UDim2.new(1, -175, 0, 35)
info.ZIndex = 11

local list = make("ScrollingFrame", {
	Name = "PetList",
	Position = UDim2.fromOffset(150, 122),
	Size = UDim2.new(1, -169, 1, -143),
	BackgroundColor3 = COLORS.panel,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = COLORS.green,
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	BorderSizePixel = 0,
	ZIndex = 11,
}, window)
corner(list, 10)
stroke(list, Color3.fromRGB(57, 78, 94), 1)
make("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, list)
make("UIGridLayout", {
	CellPadding = UDim2.fromOffset(10, 10),
	CellSize = UDim2.new(0.333, -10, 0, 150),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, list)

local empty = text(window, "", 19, COLORS.muted)
empty.Position = UDim2.new(0.19, 0, 0.47, 0)
empty.Size = UDim2.new(0.77, 0, 0, 70)
empty.TextXAlignment = Enum.TextXAlignment.Center
empty.TextWrapped = true
empty.ZIndex = 12

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
	petsTab.BackgroundColor3 = isPets and Color3.fromRGB(43, 134, 83) or COLORS.panel
	potionsTab.BackgroundColor3 = not isPets and Color3.fromRGB(43, 134, 83) or COLORS.panel
	list.Visible = isPets

	if not isPets then
		info.Text = "POTIONS"
		empty.Text = "Potions will be available soon!"
		empty.Visible = true
		return
	end

	local counts, total = inventory()
	local equipped = equippedIds()
	local equippedCount = 0
	for _ in pairs(equipped) do equippedCount += 1 end
	info.Text = string.format("Pets: %d   |   Equipped: %d / %d", total, equippedCount, PetConfig.MaxEquipped)

	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
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
		local card = make("Frame", {
			Name = id,
			LayoutOrder = order,
			Size = UDim2.fromOffset(160, 150),
			BackgroundColor3 = COLORS.card,
			ZIndex = 12,
		}, list)
		corner(card, 9)
		make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(49, 65, 83), Color3.fromRGB(33, 46, 62))}, card)
		stroke(card, rarity[pet.Rarity] or COLORS.white, 1.5)

		local name = text(card, pet.DisplayName .. "  x" .. counts[id], 17, COLORS.white, Enum.Font.GothamBlack)
		name.Position = UDim2.fromOffset(9, 13)
		name.Size = UDim2.new(1, -18, 0, 46)
		name.TextWrapped = true
		name.TextTruncate = Enum.TextTruncate.None
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.TextSize = 15
		name.ZIndex = 13

		local details = text(card, pet.Rarity .. "  |  " .. pet.Damage .. " DMG", 14, rarity[pet.Rarity] or COLORS.muted)
		details.Position = UDim2.fromOffset(7, 62)
		details.Size = UDim2.new(1, -14, 0, 26)
		details.TextXAlignment = Enum.TextXAlignment.Center
		details.TextSize = 13
		details.ZIndex = 13

		local action = make("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(1, -20, 0, 40),
			BackgroundColor3 = active and Color3.fromRGB(191, 88, 76) or COLORS.green,
			Text = active and "UNEQUIP" or "EQUIP",
			Font = Enum.Font.GothamBlack,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			ZIndex = 13,
		}, card)
		corner(action, 8)
		action.MouseButton1Click:Connect(function()
			if active then
				petAction:FireServer("Unequip", id)
			else
				petAction:FireServer("Equip", id)
			end
		end)
	end
end

local function setOpen(value)
	window.Visible = value
	if value then render() end
end

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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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
local petModels = ReplicatedStorage:WaitForChild("PetModels")

-- Use the actual 3D pet models for inventory portraits, just like egg previews.
local function addPetPortrait(portrait, id)
    local template = petModels:FindFirstChild(id)
    if not template or not template:IsA("Model") then return false end

    local view = make("ViewportFrame", {
        Name = "PetViewport",
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
        Ambient = Color3.fromRGB(185, 185, 185),
        LightColor = Color3.new(1, 1, 1),
        LightDirection = Vector3.new(-1, -1, -1),
        ZIndex = 14,
    }, portrait)
    local camera = make("Camera", {}, view)
    view.CurrentCamera = camera
    local world = make("WorldModel", {}, view)
    local model = template:Clone()
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
        elseif obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("BillboardGui") then
            obj:Destroy()
        end
    end
    model.Parent = world
    local bounds, size = model:GetBoundingBox()
    local largest = math.max(size.X, size.Y, size.Z)
    if largest > 0.001 then
        model:ScaleTo(model:GetScale() * (4.2 / largest))
    end
    bounds = model:GetBoundingBox()
    model:PivotTo(CFrame.Angles(0, math.pi, 0) * model:GetPivot():ToObjectSpace(bounds):Inverse())
    camera.CFrame = CFrame.lookAt(Vector3.new(-1.35, 0.75, 3.5), Vector3.new(0, 0.1, 0))
    return true
end

local activeTab = "PETS"

-- Větší rozestupy mezi kartičkami v obou sekcích.
for _, container in ipairs({equippedList, list}) do
	for _, layout in ipairs(container:GetChildren()) do
		if layout:IsA("UIListLayout") then
			layout.Padding = UDim.new(0, 18)
		elseif layout:IsA("UIGridLayout") then
			layout.CellSize = UDim2.fromOffset(130, 142)
			layout.CellPadding = UDim2.fromOffset(14, 14)
			if container == equippedList then
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			end
		end
	end
end


local menuScale = window:FindFirstChild("MenuScale")
if not menuScale then
	menuScale = Instance.new("UIScale")
	menuScale.Name = "MenuScale"
	menuScale.Parent = window
end
menuScale.Scale = 1
local openTween

local function hoverScale(gui, amount)
	local scale = gui:FindFirstChild("HoverScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "HoverScale"
		scale.Parent = gui
	end
	local function animate(target)
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target}):Play()
	end
	gui.MouseEnter:Connect(function() animate(amount) end)
	gui.MouseLeave:Connect(function() animate(1) end)
end
hoverScale(petsTab, 1.045)
hoverScale(potionsTab, 1.045)


local function equippedIds()
	local ids = {}
	for slot = 1, PetConfig.MaxEquipped do
		local id = player:GetAttribute("EquippedPet" .. slot)
		if typeof(id) == "string" and id ~= "" then
			ids[id] = (ids[id] or 0) + 1
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
	for _, amount in pairs(equipped) do equippedCount += amount end
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
		local equippedAmount = equipped[id] or 0
		local remainingAmount = counts[id] - equippedAmount
		for _, active in ipairs({true, false}) do
		local cardCount = active and equippedAmount or (remainingAmount > 0 and 1 or 0)
		for copyIndex = 1, cardCount do
		local target = active and equippedList or list
		local accent = rarity[pet.Rarity] or COLORS.white

		-- Celá kartička funguje jako tlačítko Equip / Unequip.
		local card = make("ImageButton", {
			Name = id .. (active and ("_Equipped_" .. copyIndex) or "_Available"),
			LayoutOrder = order * 10 + copyIndex,
			Size = UDim2.fromOffset(130, 142),
			BackgroundColor3 = COLORS.card,
			BorderSizePixel = 0,
			Image = "",
			AutoButtonColor = false,
			ZIndex = 12,
		}, target)
		corner(card, 9)
		stroke(card, accent, active and 2.5 or 1.5)
		hoverScale(card, 1.055)

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
		if addPetPortrait(portrait, id) then
            -- Render the original pet model from a three-quarter angle.
        elseif hasImage then
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

		local count = text(card, active and "" or ("x" .. remainingAmount), 19, COLORS.white)
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

		card.Activated:Connect(function()
			petAction:FireServer(active and "Unequip" or "Equip", id)
		end)
		end
		end
	end
end

local function setOpen(value)
	if value and (player:GetAttribute("UpgradeMenuOpen") or player:GetAttribute("ToolsMenuOpen")) then
		return
	end
	window.Visible = value
	if openTween then openTween:Cancel() openTween = nil end
	if value then
		menuScale.Scale = 0.9
		openTween = TweenService:Create(menuScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
		openTween:Play()
	else
		menuScale.Scale = 1
	end
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

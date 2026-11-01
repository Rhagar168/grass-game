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

		local damage = text(card, formatPetDamage(pet.Damage), 17, accent)
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
		end)        end -- create card only if missing

		end
		end
	end
    for cardName, card in pairs(existingCards) do
        if not usedCards[cardName] then card:Destroy() end
    end
    schedulePetLayout()
end

-- Keep Equip Best anchored to the lower-right of the inventory window.
equipBestButton = make("TextButton", {
    Name = "EquipBestButton",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -24, 1, -17),
    Size = UDim2.fromOffset(174, 42),
    BackgroundColor3 = COLORS.green,
    BorderSizePixel = 0,
    Text = "EQUIP BEST",
    TextColor3 = COLORS.white,
    TextSize = 15,
    FontFace = MICHROMA,
    ZIndex = 30,
    AutoButtonColor = true,
}, window)
corner(equipBestButton, 9)

hoverScale(equipBestButton, 1.045)
equipBestButton.Activated:Connect(function()
    petAction:FireServer("EquipBest")
end)

local menuClosing = false
local function setOpen(value)
    if menuClosing or (value == window.Visible) then return end
    if value and (player:GetAttribute("UpgradeMenuOpen") or player:GetAttribute("ToolsMenuOpen")) then
        return
    end
    if openTween then openTween:Cancel() openTween = nil end
    if value then
        window.Visible = true
        menuScale.Scale = 0.9
        openTween = TweenService:Create(menuScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
        openTween:Play()
        player:SetAttribute("InventoryMenuOpen", true)
        bottomMenu.Visible = false
        if xpFrame then xpFrame.Visible = false end
        render()
    else
        menuClosing = true
        local tween = TweenService:Create(menuScale, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.92})
        tween:Play()
        tween.Completed:Wait()
        window.Visible = false
        menuScale.Scale = 1
        menuClosing = false
        player:SetAttribute("InventoryMenuOpen", false)
        bottomMenu.Visible = true
        if xpFrame then xpFrame.Visible = true end
    end
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

for _, attr in ipairs({"Gamepass_PetEquip", "HasPetEquipGamepass", "PetEquipLevel"}) do
    player:GetAttributeChangedSignal(attr):Connect(function()
        if window.Visible then render() end
    end)
end

-- Equipping can change several attributes in one server update.
-- Rebuild pet portraits once per burst instead of once per attribute.
local renderQueued = false
local function queueRender()
    if renderQueued then return end
    renderQueued = true
    task.delay(0.12, function()
        renderQueued = false
        if window.Visible then render() end
    end)
end

player:GetAttributeChangedSignal("PetInventory"):Connect(function()
	queueRender()
end)
for slot = 1, PetConfig.MaxEquipped do
	player:GetAttributeChangedSignal("EquippedPet" .. slot):Connect(function()
		queueRender()
	end)
end

petAction.OnClientEvent:Connect(function(action)
	if action == "EquipFull" then
		info.Text = "All " .. PetConfig.EquipLimit(player) .. " pet slots are full. Unequip a pet first."
	elseif window.Visible then
        queueRender()
	end
end)
        local cardName = id .. (active and ("_Equipped_" .. copyIndex) or "_Available")
        local card = existingCards[cardName]
        if card then
            usedCards[cardName] = true
            card.Parent = target
            card.LayoutOrder = order * 10 + copyIndex
            local countLabel = card:FindFirstChild("Count")
            if countLabel and countLabel:IsA("TextLabel") then
                countLabel.Text = active and "" or ("x" .. remainingAmount)
            end
        else
		local card = make("ImageButton", {
			Name = cardName,
			LayoutOrder = order * 10 + copyIndex,
			Size = UDim2.fromOffset(130, 142),
			BackgroundColor3 = COLORS.card,
			BorderSizePixel = 0,
			Image = "",
			AutoButtonColor = false,
			ZIndex = 12,
		}, target)
        card:SetAttribute("InventoryPetCard", true)
        usedCards[cardName] = true
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

		local damage = text(card, formatPetDamage(pet.Damage), 17, accent)
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
    schedulePetLayout()
end

-- Keep Equip Best anchored to the lower-right of the inventory window.
equipBestButton = make("TextButton", {
    Name = "EquipBestButton",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -24, 1, -17),
    Size = UDim2.fromOffset(174, 42),
    BackgroundColor3 = COLORS.green,
    BorderSizePixel = 0,
    Text = "EQUIP BEST",
    TextColor3 = COLORS.white,
    TextSize = 15,
    FontFace = MICHROMA,
    ZIndex = 30,
    AutoButtonColor = true,
}, window)
corner(equipBestButton, 9)

hoverScale(equipBestButton, 1.045)
equipBestButton.Activated:Connect(function()
    petAction:FireServer("EquipBest")
end)

local menuClosing = false
local function setOpen(value)
    if menuClosing or (value == window.Visible) then return end
    if value and (player:GetAttribute("UpgradeMenuOpen") or player:GetAttribute("ToolsMenuOpen")) then
        return
    end
    if openTween then openTween:Cancel() openTween = nil end
    if value then
        window.Visible = true
        menuScale.Scale = 0.9
        openTween = TweenService:Create(menuScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
        openTween:Play()
        player:SetAttribute("InventoryMenuOpen", true)
        bottomMenu.Visible = false
        if xpFrame then xpFrame.Visible = false end
        render()
    else
        menuClosing = true
        local tween = TweenService:Create(menuScale, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.92})
        tween:Play()
        tween.Completed:Wait()
        window.Visible = false
        menuScale.Scale = 1
        menuClosing = false
        player:SetAttribute("InventoryMenuOpen", false)
        bottomMenu.Visible = true
        if xpFrame then xpFrame.Visible = true end
    end
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

for _, attr in ipairs({"Gamepass_PetEquip", "HasPetEquipGamepass", "PetEquipLevel"}) do
    player:GetAttributeChangedSignal(attr):Connect(function()
        if window.Visible then render() end
    end)
end

-- Equipping can change several attributes in one server update.
-- Rebuild pet portraits once per burst instead of once per attribute.
local renderQueued = false
local function queueRender()
    if renderQueued then return end
    renderQueued = true
    task.delay(0.12, function()
        renderQueued = false
        if window.Visible then render() end
    end)
end

player:GetAttributeChangedSignal("PetInventory"):Connect(function()
	queueRender()
end)
for slot = 1, PetConfig.MaxEquipped do
	player:GetAttributeChangedSignal("EquippedPet" .. slot):Connect(function()
		queueRender()
	end)
end

petAction.OnClientEvent:Connect(function(action)
	if action == "EquipFull" then
		info.Text = "All " .. PetConfig.EquipLimit(player) .. " pet slots are full. Unequip a pet first."
	elseif window.Visible then
        queueRender()
	end
end)

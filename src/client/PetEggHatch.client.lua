local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

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

local function refreshEggs()
	table.clear(eggs)
	for biome, config in pairs(configs) do
		local folder = eggsFolder:FindFirstChild(biome)
		local model = folder and (folder:FindFirstChild(config.model) or folder:FindFirstChild("Model"))
		if model and model:IsA("Model") then
			table.insert(eggs, {
				id = biome,
				model = model,
				config = config,
			})
		end
	end
end

refreshEggs()

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

-- Listen globally: prompts can replicate after this script starts.
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name ~= "EggPrompt" then return end

	-- Resolve the biome by ancestry, not by a potentially stale startup list.
	local current = prompt.Parent
	while current and current ~= eggsFolder do
		local parent = current.Parent
		if parent == eggsFolder then
			local config = configs[current.Name]
			if not config then return end
			local model = current:FindFirstChild(config.model) or current:FindFirstChild("Model")
			if not model or not model:IsA("Model") or not prompt:IsDescendantOf(model) then return end
			openWindow({id = current.Name, model = model, config = config})
			return
		end
		current = parent
	end
end)

-- Local-only egg collection preview: real 3D pets, permanent discovery silhouettes.
local previews = {}
local function discoveredPet(id)
    local raw = player:GetAttribute("DiscoveredPets") or ""
    for owned in string.gmatch(raw, "[^,]+") do
        if owned == id then return true end
    end
    -- Support players who already owned pets before discovery tracking existed.
    for owned in string.gmatch(player:GetAttribute("PetInventory") or "", "[^,]+") do
        if owned == id then return true end
    end
    return false
end

local function buildPreview(egg)
    local existing = previews[egg.model]
    if existing then return existing end
    local anchor = egg.model:FindFirstChild("EggPetInfo", true)
    if not (anchor and anchor:IsA("BasePart")) then
        anchor = egg.model:FindFirstChild("EggDisplayBase", true)
    end
    if not (anchor and anchor:IsA("BasePart")) then
        anchor = egg.model:FindFirstChildWhichIsA("BasePart", true)
    end
    if not anchor then return nil end

    local board = Instance.new("BillboardGui")
    board.Name = "CollectionPreview"
    -- Attach to the actual top-center of the egg instead of an offset mesh part.
    local boundsCF, boundsSize = egg.model:GetBoundingBox()
    local attachment = Instance.new("Attachment")
    attachment.Name = "CollectionPreviewAnchor"
    attachment.Position = anchor.CFrame:PointToObjectSpace(
        boundsCF.Position + Vector3.new(0, boundsSize.Y * 0.5 + 0.5, 0)
    )
    attachment.Parent = anchor
    board.Adornee = attachment
    -- Offset size is measured in screen pixels and remains constant with camera zoom.
    board.Size = UDim2.fromOffset(285, 215)
    board.StudsOffsetWorldSpace = Vector3.zero
    board.MaxDistance = 32
    board.AlwaysOnTop = true
    board.Enabled = false
    board.Parent = gui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(15, 24, 20)
    panel.Parent = board
    round(panel, 15)
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(58, 185, 103)
    border.Thickness = 2.5
    border.Parent = panel

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 29)
    header.BackgroundTransparency = 1
    header.Text = egg.config.title
    header.TextColor3 = Color3.fromRGB(112, 236, 146)
    header.TextSize = 17
    header.Font = Enum.Font.GothamBlack
    header.Parent = panel

    local cards = {}
    local eggData = PetConfig.Eggs[egg.id]
    if eggData then
        for i, entry in ipairs(eggData.Pets) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local x = row == 1 and (0.18 + col * 0.34) or (0.02 + col * 0.33)
            local card = Instance.new("Frame")
            card.Position = UDim2.new(x, 0, 0, 34 + row * 87)
            card.Size = UDim2.new(0.30, 0, 0, 83)
            card.BackgroundColor3 = Color3.fromRGB(29, 43, 36)
            card.Parent = panel
            round(card, 10)
            local cardStroke = Instance.new("UIStroke")
            cardStroke.Color = Color3.fromRGB(48, 91, 65)
            cardStroke.Thickness = 1
            cardStroke.Parent = card

            local chance = Instance.new("TextLabel")
            chance.Size = UDim2.new(1, 0, 0, 18)
            chance.BackgroundTransparency = 1
            chance.Text = tostring(entry.Chance) .. "%"
            chance.Font = Enum.Font.GothamBlack
            chance.TextSize = 15
            chance.TextColor3 = Color3.fromRGB(116, 242, 151)
            chance.Parent = card

            local view = Instance.new("ViewportFrame")
            view.Position = UDim2.fromOffset(1, 15)
            view.Size = UDim2.new(1, -2, 0, 59)
            view.BackgroundTransparency = 1
            view.Ambient = Color3.fromRGB(185, 185, 185)
            view.LightColor = Color3.new(1, 1, 1)
            view.LightDirection = Vector3.new(-1, -1, -1)
            view.Parent = card
            local cam = Instance.new("Camera")
            cam.Parent = view
            view.CurrentCamera = cam
            local world = Instance.new("WorldModel")
            world.Parent = view

            local name = Instance.new("TextLabel")
            name.Position = UDim2.new(0, 2, 1, -17)
            name.Size = UDim2.new(1, -4, 0, 15)
            name.BackgroundTransparency = 1
            name.TextColor3 = Color3.fromRGB(237, 245, 239)
            name.Font = Enum.Font.GothamBold
            name.TextScaled = true
            name.Parent = card

            local unknown = Instance.new("TextLabel")
            unknown.Position = UDim2.new(0, 0, 0, 18)
            unknown.Size = UDim2.new(1, 0, 0, 60)
            unknown.BackgroundTransparency = 1
            unknown.Text = "?"
            unknown.Font = Enum.Font.GothamBlack
            unknown.TextSize = 36
            unknown.TextColor3 = Color3.fromRGB(98, 112, 103)
            unknown.Parent = card

            cards[i] = {id = entry.Id, world = world, camera = cam, name = name, unknown = unknown}
        end
    end
    local state = {board = board, cards = cards, egg = egg}
    previews[egg.model] = state
    return state
end

local function refreshPreview(state)
    local templates = ReplicatedStorage:FindFirstChild("PetModels")
    for _, card in ipairs(state.cards) do
        local known = discoveredPet(card.id)
        if card.known == known then continue end
        card.known = known
        card.world:ClearAllChildren()
        local config = PetConfig.GetPet(card.id)
        card.name.Text = known and (config and config.DisplayName or card.id) or "???"
        local template = templates and templates:FindFirstChild(card.id)
        card.unknown.Visible = not template
        if template and template:IsA("Model") then
            local model = template:Clone()
            for _, obj in ipairs(model:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Anchored = true
                    obj.CanCollide = false
                    if not known then
                        obj.Color = Color3.fromRGB(2, 4, 3)
                        obj.Material = Enum.Material.SmoothPlastic
                        obj.Transparency = 0
                        if obj:IsA("MeshPart") then obj.TextureID = "" end
                    end
                elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
                    if not known then obj:Destroy() end
                elseif obj:IsA("BillboardGui") or obj:IsA("Script") or obj:IsA("LocalScript") then
                    obj:Destroy()
                end
            end
            model.Parent = card.world
            local bounds, size = model:GetBoundingBox()
            local largest = math.max(size.X, size.Y, size.Z)
            if largest > 0 then model:ScaleTo(model:GetScale() * (3.4 / largest)) end
            bounds = model:GetBoundingBox()
            model:PivotTo(CFrame.Angles(0, math.pi, 0) * model:GetPivot():ToObjectSpace(bounds):Inverse())
            card.camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.25, 3.5), Vector3.zero)
            card.unknown.Visible = false
        end
    end
end

player:GetAttributeChangedSignal("DiscoveredPets"):Connect(function()
    for _, state in pairs(previews) do refreshPreview(state) end
end)
player:GetAttributeChangedSignal("PetInventory"):Connect(function()
    for _, state in pairs(previews) do refreshPreview(state) end
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.15 then return end
	elapsed = 0
	refreshEggs()

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
			billboard.Enabled = false
		end
		local preview = buildPreview(egg)
		if preview then
			preview.board.Enabled = egg == nearest and not window.Visible
			if preview.board.Enabled then refreshPreview(preview) end
		end
	end

	if selected and root and (selected.model:GetPivot().Position - root.Position).Magnitude > 22 then
		closeWindow()
	end
end)

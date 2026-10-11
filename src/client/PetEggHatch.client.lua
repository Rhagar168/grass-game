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

-- GUI is authored in StarterGui using tools/CreatePetEggGui.command.lua.
-- Do not generate a second copy at runtime.
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:FindFirstChild("PetEggHatchGui")
if not gui then
    -- Fallback for places where the Studio Command Bar UI was not saved/published.
    -- The purchase prompt and 3D pet icon preview must still work.
    local function createFallbackGui()
        gui = Instance.new("ScreenGui")
        gui.Name = "PetEggHatchGui"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.Parent = playerGui
        
        local overlay = Instance.new("Frame")
        overlay.Name = "Overlay"
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        overlay.BackgroundTransparency = 0.5
        overlay.Visible = false
        overlay.Parent = gui
        
        local window = Instance.new("Frame")
        window.Name = "MainFrame"
        window.AnchorPoint = Vector2.new(0.5, 0.5)
        window.Position = UDim2.fromScale(0.5, 0.5)
        window.Size = UDim2.fromOffset(560, 380)
        window.BackgroundColor3 = Color3.fromRGB(15, 26, 22)
        window.Visible = false
        window.Parent = gui
        
        local function round(parent, radius)
        	local corner = Instance.new("UICorner")
        	corner.CornerRadius = UDim.new(0, radius)
        	corner.Parent = parent
        end
        
        round(window, 16)
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Parent = window
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Position = UDim2.fromOffset(20, 14)
        title.Size = UDim2.new(1, -85, 0, 40)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.Gotham
        title.TextSize = 30
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = Color3.fromRGB(54, 218, 112)
        title.Parent = window
        
        local close = Instance.new("TextButton")
        close.Name = "CloseButton"
        close.Position = UDim2.new(1, -8, 0, -8)
        close.Size = UDim2.fromOffset(58, 58)
        close.BackgroundColor3 = Color3.fromRGB(207, 47, 58)
        close.Text = "×"
        close.TextColor3 = Color3.new(1, 1, 1)
        close.Font = Enum.Font.Gotham
        close.TextSize = 38
        close.Parent = window
        round(close, 5)
        
        local function makeButton(label, x)
        	local button = Instance.new("TextButton")
        	button.Position = UDim2.new(x, 0, 0, 286)
        	button.Size = UDim2.new(0.42, 0, 0, 55)
        	button.BackgroundColor3 = Color3.fromRGB(39, 177, 82)
        	button.Text = label
        	button.Font = Enum.Font.GothamBlack
        	button.TextSize = 22
        	button.TextColor3 = Color3.new(1, 1, 1)
        	button.Parent = window
        	round(button, 12)
        	return button
        end
        
        local hatch1 = makeButton("HATCH x1", 0.055)
        hatch1.Name = "Hatch1Button"
        local hatch3 = makeButton("HATCH x3", 0.525)
        hatch3.Name = "Hatch3Button"
        
        local message = Instance.new("TextLabel")
        message.Name = "Message"
        message.Position = UDim2.fromOffset(16, 345)
        message.Size = UDim2.new(1, -32, 0, 28)
        message.BackgroundTransparency = 1
        message.TextWrapped = true
        message.TextColor3 = Color3.fromRGB(255, 220, 125)
        message.Font = Enum.Font.GothamBold
        message.TextSize = 16
        message.Parent = window
        
        local banner = Instance.new("Frame")
        banner.Name = "Banner"
        banner.Size = UDim2.new(1, -6, 0, 70)
        banner.Position = UDim2.fromOffset(3, 3)
        banner.BackgroundColor3 = Color3.fromRGB(15, 26, 22)
        banner.BorderSizePixel = 0
        banner.Parent = window
        round(banner, 12)
        title.ZIndex = 2
        close.ZIndex = 2
        
        local function makePrice(x)
            local label = Instance.new("TextLabel")
            label.Position = UDim2.new(x, 0, 0, 243)
            label.Size = UDim2.new(0.42, 0, 0, 35)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 23
            label.TextColor3 = Color3.fromRGB(255, 212, 76)
            label.Parent = window
            return label
        end
        
        local price1 = makePrice(0.055)
        price1.Name = "Price1"
        local price3 = makePrice(0.525)
        price3.Name = "Price3"
        
        local contentPanel = Instance.new("Frame")
        contentPanel.Name = "ContentPanel"
        contentPanel.Position = UDim2.fromOffset(17, 82)
        contentPanel.Size = UDim2.new(1, -34, 0, 178)
        contentPanel.BackgroundColor3 = Color3.fromRGB(28, 34, 40)
        contentPanel.BorderSizePixel = 0
        contentPanel.ZIndex = 0
        contentPanel.Parent = window
        round(contentPanel, 12)
        local contentStroke = Instance.new("UIStroke")
        contentStroke.Color = Color3.fromRGB(55, 73, 72)
        contentStroke.Thickness = 1.5
        contentStroke.Parent = contentPanel
        
        
        
    end
    createFallbackGui()
    warn("[PetEggHatch] StarterGui/PetEggHatchGui missing; created temporary UI. Run the Command Bar setup in Edit mode and save the place.")
end
local overlay = gui:WaitForChild("Overlay")
local window = gui:WaitForChild("MainFrame")
local stroke = window:FindFirstChildOfClass("UIStroke")
local title = window:WaitForChild("Title")
local close = window:WaitForChild("CloseButton")
local hatch1 = window:WaitForChild("Hatch1Button")
local hatch3 = window:WaitForChild("Hatch3Button")
local message = window:WaitForChild("Message")
local price1 = window:WaitForChild("Price1")
local price3 = window:WaitForChild("Price3")

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

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
	if stroke then stroke.Color = Color3.fromRGB(75, 91, 86) end
	
	local config = PetConfig.Eggs[egg.id]
	if config then
		local currency = config.Currency or "Coins"
		hatch1.Text = "HATCH x1"
		price1.Text = tostring(config.Price) .. " C"
		hatch3.Text = "HATCH x3"
		price3.Text = tostring(config.Price * 3) .. " C"
		message.Text = ""
	else
		hatch1.Text = "HATCH x1"
		hatch3.Text = "HATCH x3"
		price1.Text = ""
		price3.Text = ""
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
		closeWindow()
		return
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
    panel.BackgroundColor3 = Color3.fromRGB(12, 25, 18)
    panel.Parent = board
    round(panel, 15)
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(52, 216, 105)
    border.Thickness = 2
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
            card.BackgroundColor3 = Color3.fromRGB(24, 43, 32)
            card.Parent = panel
            round(card, 10)
            local cardStroke = Instance.new("UIStroke")
            cardStroke.Color = Color3.fromRGB(65, 112, 79)
            cardStroke.Thickness = 1.2
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
            view.Position = UDim2.fromOffset(1, 17)
            view.Size = UDim2.new(1, -2, 0, 49)
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
            name.Position = UDim2.new(0, 2, 1, -18)
            name.Size = UDim2.new(1, -4, 0, 17)
            name.BackgroundColor3 = Color3.fromRGB(15, 31, 22)
            name.BackgroundTransparency = 0.08
            name.ZIndex = 3
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
            -- Keep the original PetModels meshes; show them from a slight 3/4 angle.
            card.camera.CFrame = CFrame.lookAt(Vector3.new(1.35, 0.75, 3.5), Vector3.new(0, 0.1, 0))
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
	local nearest, bestDistance = nil, 8
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

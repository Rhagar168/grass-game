local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local hatchEvent = ReplicatedStorage:FindFirstChild("PetHatch")
if not hatchEvent then
	hatchEvent = Instance.new("RemoteEvent")
	hatchEvent.Name = "PetHatch"
	hatchEvent.Parent = ReplicatedStorage
end

local lastRequest = {}

local function decode(raw)
	local pets = {}
	for id in string.gmatch(raw or "", "[^,]+") do
		if PetConfig.GetPet(id) then
			table.insert(pets, id)
		end
	end
	return pets
end

local function rollPet(egg)
	local roll = math.random() * 100
	local total = 0
	for _, entry in ipairs(egg.Pets) do
		total += entry.Chance
		if roll <= total then
			return entry.Id
		end
	end
	return egg.Pets[#egg.Pets].Id
end

local function nearEgg(player, eggId)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local eggs = workspace:FindFirstChild("Eggs")
	local folder = eggs and eggs:FindFirstChild(eggId)
	if not root or not folder then return false end

	local modelName = ({Savanna = "SavannaEgg", Tundra = "FrozenEgg", Beach = "BeachEgg"})[eggId]
	local model = folder:FindFirstChild(modelName or "") or folder:FindFirstChild("Model")
	if not model or not model:IsA("Model") then return false end

	return (model:GetPivot().Position - root.Position).Magnitude <= 18
end

hatchEvent.OnServerEvent:Connect(function(player, action, eggId, amount)
	if action ~= "Hatch" or typeof(eggId) ~= "string" then return end
	if player:GetAttribute("DataLoaded") ~= true then return end

	amount = amount == nil and 1 or amount
	if amount ~= 1 and amount ~= 3 then return end

	local now = os.clock()
	if now - (lastRequest[player] or 0) < 0.7 then return end
	lastRequest[player] = now

	local egg = PetConfig.Eggs[eggId]
	if not egg then
		hatchEvent:FireClient(player, "Unavailable", eggId)
		return
	end

	if not nearEgg(player, eggId) then
		hatchEvent:FireClient(player, "TooFar", eggId)
		return
	end

	if egg.RequiredUnlock and player:GetAttribute(egg.RequiredUnlock) ~= true then
		hatchEvent:FireClient(player, "Locked", eggId)
		return
	end

	local currency = egg.Currency or "Coins"
	local price = egg.Price * amount
	local balance = player:GetAttribute(currency) or 0
	if balance < price then
		hatchEvent:FireClient(player, "NotEnough", eggId, price, currency)
		return
	end

	local pets = decode(player:GetAttribute("PetInventory"))
	local results = {}
	for _ = 1, amount do
		local petId = rollPet(egg)
		table.insert(pets, petId)
		table.insert(results, petId)
	end

	player:SetAttribute(currency, balance - price)
	player:SetAttribute("PetInventory", table.concat(pets, ","))
	hatchEvent:FireClient(player, "Hatched", eggId, results)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)

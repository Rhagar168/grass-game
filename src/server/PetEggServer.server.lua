local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local hatchEvent = ReplicatedStorage:FindFirstChild("PetHatch")
if not hatchEvent then
	hatchEvent = Instance.new("RemoteEvent")
	hatchEvent.Name = "PetHatch"
	hatchEvent.Parent = ReplicatedStorage
end

local function decode(raw)
	local pets = {}
	for id in string.gmatch(raw or "", "[^,]+") do
		if PetConfig.GetPet(id) then table.insert(pets, id) end
	end
	return pets
end

local function encode(pets)
	return table.concat(pets, ",")
end

local function rollPet(egg)
	local roll = math.random() * 100
	local total = 0
	for _, entry in ipairs(egg.Pets) do
		total += entry.Chance
		if roll <= total then return entry.Id end
	end
	return egg.Pets[#egg.Pets].Id
end

hatchEvent.OnServerEvent:Connect(function(player, action, eggId)
	if action ~= "Hatch" or typeof(eggId) ~= "string" then return end
	if player:GetAttribute("DataLoaded") ~= true then return end

	local egg = PetConfig.Eggs[eggId]
	if not egg then return end
	if egg.RequiredUnlock and player:GetAttribute(egg.RequiredUnlock) ~= true then
		hatchEvent:FireClient(player, "Locked", eggId)
		return
	end

	local currency = egg.Currency or "Coins"
	local balance = player:GetAttribute(currency) or 0
	if balance < egg.Price then
		hatchEvent:FireClient(player, "NotEnough", eggId, egg.Price, currency)
		return
	end

	player:SetAttribute(currency, balance - egg.Price)
	local petId = rollPet(egg)
	local pets = decode(player:GetAttribute("PetInventory"))
	table.insert(pets, petId)
	player:SetAttribute("PetInventory", encode(pets))
	hatchEvent:FireClient(player, "Hatched", eggId, petId)
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local petAction = ReplicatedStorage:FindFirstChild("PetAction")
if not petAction then
	petAction = Instance.new("RemoteEvent")
	petAction.Name = "PetAction"
	petAction.Parent = ReplicatedStorage
end

local function decodeInventory(player)
	local result = {}
	local raw = player:GetAttribute("PetInventory") or ""
	for id in string.gmatch(raw, "[^,]+") do
		if PetConfig.GetPet(id) then
			result[id] = (result[id] or 0) + 1
		end
	end
	return result
end

local function ownsPet(player, petId)
	return (decodeInventory(player)[petId] or 0) > 0
end

local function getEquipped(player)
	local equipped = {}
	for slot = 1, PetConfig.MaxEquipped do
		equipped[slot] = player:GetAttribute("EquippedPet" .. slot) or ""
	end
	return equipped
end

local function refreshAttributes(player)
	local equipped = getEquipped(player)
	local count = 0
	for _, id in ipairs(equipped) do
		if id ~= "" then count += 1 end
	end
	player:SetAttribute("EquippedPetCount", count)
end

local function equip(player, petId)
	if typeof(petId) ~= "string" or not PetConfig.GetPet(petId) or not ownsPet(player, petId) then return end
	local equipped = getEquipped(player)
	for _, id in ipairs(equipped) do
		if id == petId then return end
	end
	for slot = 1, PetConfig.MaxEquipped do
		if equipped[slot] == "" then
			player:SetAttribute("EquippedPet" .. slot, petId)
			refreshAttributes(player)
			petAction:FireClient(player, "Equipped", petId, slot)
			return
		end
	end
	petAction:FireClient(player, "EquipFull", petId)
end

local function unequip(player, petId)
	if typeof(petId) ~= "string" then return end
	for slot = 1, PetConfig.MaxEquipped do
		if player:GetAttribute("EquippedPet" .. slot) == petId then
			player:SetAttribute("EquippedPet" .. slot, "")
			refreshAttributes(player)
			petAction:FireClient(player, "Unequipped", petId, slot)
			return
		end
	end
end

petAction.OnServerEvent:Connect(function(player, action, petId)
	if player:GetAttribute("DataLoaded") ~= true then return end
	if action == "Equip" then
		equip(player, petId)
	elseif action == "Unequip" then
		unequip(player, petId)
	end
end)

local function setup(player)
	if player:GetAttribute("DataLoaded") ~= true then
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end
	if not player.Parent then return end
	for slot = 1, PetConfig.MaxEquipped do
		local attr = "EquippedPet" .. slot
		local id = player:GetAttribute(attr) or ""
		if id ~= "" and (not PetConfig.GetPet(id) or not ownsPet(player, id)) then
			player:SetAttribute(attr, "")
		end
	end
	refreshAttributes(player)
end

Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player) end

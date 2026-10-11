-- Server-to-client visual notification for successful egg hatches.
-- The actual egg purchasing code should call:
-- ReplicatedStorage.PetHatched:FireClient(player, awardedPetId)
-- only AFTER the server validates the purchase and awards the pet.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local event = ReplicatedStorage:FindFirstChild("PetHatched")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "PetHatched"
    event.Parent = ReplicatedStorage
end

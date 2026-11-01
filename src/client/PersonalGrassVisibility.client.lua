local Players =
	game:GetService("Players")

local CollectionService =
	game:GetService("CollectionService")

local player =
	Players.LocalPlayer

-- Keep grass belonging to other players invisible, even when owner
-- attributes arrive after the part is replicated.
local vegetation = workspace:WaitForChild("Vegetation")
local myFolderName = tostring(player.UserId)

local function updateGrassVisibility(grass)
    if not grass:IsA("BasePart") then return end
    local folder = grass
    while folder and folder.Parent ~= vegetation do
        folder = folder.Parent
    end
    if folder and folder.Parent == vegetation then
        grass.LocalTransparencyModifier = (folder.Name == myFolderName) and 0 or 1
    else
        local owner = grass:GetAttribute("OwnerUserId")
        if owner ~= nil then
            grass.LocalTransparencyModifier = (owner == player.UserId) and 0 or 1
        end
    end
end

for _, grass in ipairs(vegetation:GetDescendants()) do
    updateGrassVisibility(grass)
end
vegetation.DescendantAdded:Connect(function(grass)
    updateGrassVisibility(grass)
    if grass:IsA("BasePart") then
        grass:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
            updateGrassVisibility(grass)
        end)
    end
end)
for _, grass in ipairs(CollectionService:GetTagged("Cuttable")) do
    updateGrassVisibility(grass)
end
CollectionService:GetInstanceAddedSignal("Cuttable"):Connect(function(grass)
    updateGrassVisibility(grass)
end)


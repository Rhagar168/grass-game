local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Codes = require(script.Parent:WaitForChild("RedeemCodeConfig"))

local remote = Instance.new("RemoteFunction")
remote.Name = "RedeemCode"
remote.Parent = ReplicatedStorage

local lastAttempt = {}
local inProgress = {}
local function redeemedSet(serialized)
    local set = {}
    for code in string.gmatch(serialized or "", "[^|]+") do
        set[code] = true
    end
    return set
end

remote.OnServerInvoke = function(player, rawCode)
    if type(rawCode) ~= "string" or #rawCode > 40 then
        return false, "INVALID CODE"
    end
    if inProgress[player] then return false, "PLEASE WAIT" end
    local now = os.clock()
    if now - (lastAttempt[player] or -100) < 1 then
        return false, "PLEASE WAIT"
    end
    lastAttempt[player] = now
    if player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("DataLoadFailed") == true then
        return false, "DATA NOT READY"
    end
    local code = string.upper(rawCode:match("^%s*(.-)%s*$"))
    if not code:match("^[A-Z0-9_%-]+$") then
        return false, "INVALID CODE"
    end
    local reward = Codes[code]
    if not reward then return false, "INVALID CODE" end
    local saved = player:GetAttribute("RedeemedCodes") or ""
    if redeemedSet(saved)[code] then return false, "ALREADY REDEEMED" end
    inProgress[player] = true
    -- Mark redeemed before giving the reward to prevent duplicate concurrent claims.
    player:SetAttribute("RedeemedCodes", saved .. code .. "|")
    local descriptions = {}
    for _, stat in ipairs({"Coins", "ResetTokens", "GrassCores"}) do
        local amount = reward[stat]
        if type(amount) == "number" and amount > 0 and amount == math.floor(amount) then
            player:SetAttribute(stat, (player:GetAttribute(stat) or 0) + amount)
            table.insert(descriptions, "+" .. tostring(amount) .. " " .. stat)
        end
    end
    inProgress[player] = nil
    return true, #descriptions > 0 and table.concat(descriptions, ", ") or "CODE REDEEMED"
end
game:GetService("Players").PlayerRemoving:Connect(function(player)
    lastAttempt[player] = nil
    inProgress[player] = nil
end)

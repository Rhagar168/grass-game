local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local boards = workspace:WaitForChild("Boards")
local resetEvent = ReplicatedStorage:WaitForChild("ResetBiome")
local BIOMES = {Plains=500,Forest=1000,Savanna=1000,Jungle=1000,Tundra=1000,Volcano=1000,Beach=1000}

local function setup(biome, total)
    local folder = boards:WaitForChild(biome)
    local cube = folder:WaitForChild(biome .. "Board"):WaitForChild("Cube")
    local template = cube:WaitForChild("SurfaceGui")
    local personal = template:Clone()
    personal.Name = "PersonalResetBoard_" .. biome
    personal.Adornee = cube
    personal.Enabled = true
    personal.Parent = player:WaitForChild("PlayerGui")
    template.Enabled = false

    local count = personal:FindFirstChild("ResetCountText", true)
    local progressBG = personal:FindFirstChild("ProgressBarBG", true)
    local fill = progressBG and progressBG:FindFirstChild("ProgressFill")
    local progressText = progressBG and progressBG:FindFirstChild("ProgressText")
    local button = personal:FindFirstChild("TextButton", true)
    if progressBG then progressBG.ClipsDescendants = true end

    local function update()
        local resets = player:GetAttribute(biome .. "ResetCount") or 0
        local remaining = player:GetAttribute(biome .. "GrassRemaining")
        if typeof(remaining) ~= "number" then remaining = total end
        local fraction = math.clamp((total - remaining) / total, 0, 1)
        local canReset = remaining <= 0
        if count then count.Text = "RESETS: " .. tostring(resets) end
        if progressText then
            progressText.Text = canReset and "COMPLETE!" or (tostring(math.floor(fraction * 100 + 0.5)) .. "%")
        end
        if fill then
            TweenService:Create(fill, TweenInfo.new(0.2), {Size=UDim2.new(fraction,0,1,0)}):Play()
        end
        if button then
            button.Text = "RESET"
            button.BackgroundColor3 = canReset and Color3.fromRGB(102,229,134) or Color3.fromRGB(80,80,80)
            button.TextColor3 = canReset and Color3.new(1,1,1) or Color3.fromRGB(160,160,160)
            button.AutoButtonColor = canReset
        end
    end
    if button and button:IsA("GuiButton") then
        button.Activated:Connect(function()
            if (player:GetAttribute(biome .. "GrassRemaining") or total) <= 0 then
                resetEvent:FireServer(biome)
            end
        end)
    end
    player:GetAttributeChangedSignal(biome .. "ResetCount"):Connect(update)
    player:GetAttributeChangedSignal(biome .. "GrassRemaining"):Connect(update)
    player:GetAttributeChangedSignal("DataLoaded"):Connect(update)
    update()
end
for biome,total in pairs(BIOMES) do task.spawn(setup,biome,total) end

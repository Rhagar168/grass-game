-- Keep unreleased tools visible as placeholders, without allowing selection.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConfig = require(ReplicatedStorage:WaitForChild("ToolConfig"))

local gui = script.Parent
local toolList = gui:WaitForChild("ToolsMenu"):WaitForChild("ToolList")

for _, toolId in ipairs(ToolConfig.Order) do
    local config = ToolConfig.GetTool(toolId)
    if config and config.ComingSoon then
        local button = toolList:WaitForChild(toolId)
        if button:IsA("GuiButton") then
            local function refresh()
                if button.Text ~= "COMING SOON" then
                    button.Text = "COMING SOON"
                end
                button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                button.TextColor3 = Color3.fromRGB(145, 145, 145)
                button.Interactable = false
                button.AutoButtonColor = false
            end

            -- Existing Studio menu controller rewrites button text on level changes.
            button:GetPropertyChangedSignal("Text"):Connect(refresh)
            button:GetPropertyChangedSignal("Interactable"):Connect(function()
                if button.Interactable then button.Interactable = false end
            end)
            refresh()
        end
    end
end

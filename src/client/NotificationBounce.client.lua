local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("MainUI")

-- Give every notification "!" the same bounce used by the profile notification.
-- Existing animated badges mark themselves with BounceStarted, so this script
-- does not interfere with ProfileMenuController or any future badge that
-- already owns its animation.
local function startBounce(badge)
	if not badge:IsA("TextLabel") or badge.Text ~= "!" then
		return
	end
	if badge:GetAttribute("BounceStarted") then
		return
	end

	-- Bottom-menu alerts should sit in exactly the same top-right spot as Profile.
	-- Do not touch Profile's own badge; ProfileMenuController already positions it.
	local parent = badge.Parent
	if parent and parent.Parent and parent.Parent.Name == "BottomMenu" and parent.Name ~= "ProfileButton" then
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.new(0.78, 0, 0.18, 0)
	end

	badge:SetAttribute("BounceStarted", true)
	local basePosition = badge.Position

	task.spawn(function()
		while badge.Parent do
			if badge.Visible then
				local up = UDim2.new(
					basePosition.X.Scale,
					basePosition.X.Offset,
					basePosition.Y.Scale,
					basePosition.Y.Offset - 5
				)
				local rise = TweenService:Create(
					badge,
					TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Position = up}
				)
				rise:Play()
				rise.Completed:Wait()
				if not badge.Parent then break end

				local fall = TweenService:Create(
					badge,
					TweenInfo.new(0.34, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
					{Position = basePosition}
				)
				fall:Play()
				fall.Completed:Wait()
				task.wait(0.65)
			else
				badge.Position = basePosition
				task.wait(0.2)
			end
		end
	end)
end

for _, descendant in ipairs(gui:GetDescendants()) do
	startBounce(descendant)
end

gui.DescendantAdded:Connect(function(descendant)
	task.defer(startBounce, descendant)
end)

print("[NotificationBounce] Ready")

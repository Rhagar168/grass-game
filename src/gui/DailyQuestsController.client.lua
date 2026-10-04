local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local menu = script.Parent:WaitForChild("DailyQuestsMenu")
local panel = menu:WaitForChild("Panel")
local list = panel:WaitForChild("QuestList")
local toggle = menu:WaitForChild("ToggleButton")
local claimEvent = ReplicatedStorage:WaitForChild("ClaimDailyQuest")

local open = true
local openPos = panel.Position
local closedPos = openPos

local function fmt(n)
	if n >= 1000000 then return string.format("%.2fM",n/1000000) end
	if n >= 1000 then return string.format("%.2fK",n/1000) end
	return tostring(math.floor(n))
end

local function update()
	local claimedCount = 0
	for i=1,3 do
		local row=list:FindFirstChild("Quest"..i)
		if row then
			local goal=player:GetAttribute("DailyQuestGoal"..i) or 1
			local title=player:GetAttribute("DailyQuestTitle"..i) or "DAILY QUEST"
			local reward=player:GetAttribute("DailyQuestRewardText"..i) or ""
			local p=math.min(player:GetAttribute("DailyQuestProgress"..i) or 0,goal)
			local claimed=player:GetAttribute("DailyQuestClaimed"..i)==true
			local done=p>=goal

			if claimed then claimedCount+=1 end

			row.QuestTitle.Text=title
			row.ProgressText.Text=claimed and "CLAIMED" or (fmt(p).." / "..fmt(goal))
			row.Reward.Text=reward
			row.ProgressBar.Fill.Size=UDim2.new(goal>0 and p/goal or 0,0,1,0)

			-- The old CLAIM button is never shown. The whole quest row is clickable.
			local claim=row:FindFirstChild("ClaimButton")
			if claim then claim.Visible=false end

			row.QuestTitle.Visible=true
			row.ProgressText.Visible=true
			row.Reward.Visible=true
			row.ProgressBar.Visible=true

			row.Active=done and not claimed
			row:SetAttribute("CanClaimDailyQuest",done and not claimed)
		end
	end
	toggle.Count.Text=claimedCount.." / 3"
end

for i=1,3 do
	local row=list:WaitForChild("Quest"..i)
	local claim=row:FindFirstChild("ClaimButton")
	if claim then claim.Visible=false end

	row.Active=true
	row.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then
			if row:GetAttribute("CanClaimDailyQuest")==true then
				claimEvent:FireServer(i)
			end
		end
	end)
end

local activeTween

local function setOpen(value)
	open = value

	local arrow = toggle:FindFirstChild("Arrow")
	if arrow then
		arrow.Text = value and "▲" or "▼"
	end

	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	if value then
		panel.Visible = true
		panel.Position = UDim2.new(openPos.X.Scale, openPos.X.Offset, openPos.Y.Scale, openPos.Y.Offset + 18)

		activeTween = TweenService:Create(
			panel,
			TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{Position = openPos}
		)
		activeTween:Play()
	else
		activeTween = TweenService:Create(
			panel,
			TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{Position = UDim2.new(openPos.X.Scale, openPos.X.Offset, openPos.Y.Scale, openPos.Y.Offset + 18)}
		)
		activeTween:Play()

		local thisTween = activeTween
		thisTween.Completed:Connect(function()
			if activeTween == thisTween and not open then
				panel.Visible = false
				panel.Position = openPos
				activeTween = nil
			end
		end)
	end
end

toggle.Activated:Connect(function() setOpen(not open) end)
local close=panel:FindFirstChild("CloseButton")
if close then close.Activated:Connect(function() setOpen(false) end) end

for i=1,3 do
	for _,a in ipairs({"DailyQuestProgress"..i,"DailyQuestClaimed"..i,"DailyQuestTitle"..i,"DailyQuestGoal"..i,"DailyQuestRewardText"..i}) do
		player:GetAttributeChangedSignal(a):Connect(update)
	end
end

task.spawn(function()
	while menu.Parent do
		local remaining=86400-(os.time()%86400)
		local h=math.floor(remaining/3600)
		local m=math.floor((remaining%3600)/60)
		local s=remaining%60
		local timer=toggle:FindFirstChild("ResetTimer")
		if timer then timer.Text=string.format("%02d:%02d:%02d",h,m,s) end
		task.wait(1)
	end
end)

update()
setOpen(false)

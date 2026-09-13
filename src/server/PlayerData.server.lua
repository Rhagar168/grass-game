local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)

	player:SetAttribute(
		"GrassStored",
		0
	)

	player:SetAttribute(
		"GrassCapacity",
		20
	)

	player:SetAttribute(
		"Coins",
		0
	)
	
	player:SetAttribute(
		"ResetTokens",
		0
	)

end)
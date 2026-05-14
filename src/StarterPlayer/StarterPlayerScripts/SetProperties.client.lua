local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SetPropertiesEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("SetProperties")

SetPropertiesEvent.OnClientEvent:Connect(function(Identifier, Object, Properties)
	if not Identifier then return end

	if Object and Object:IsDescendantOf(game) and type(Properties) == "table" then
		for Property, Value in pairs(Properties) do
			pcall(function()
				Object[Property] = Value
			end)
		end
	end

	SetPropertiesEvent:FireServer(Identifier)
end)

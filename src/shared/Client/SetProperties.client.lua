local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))

local ScriptTrove = Trove.new()

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

Packets.Listen(Packets.setPropertiesApply, function(Data)
	local Identifier = Data and Data.Identifier
	local Object = Data and Data.Object
	local Properties = Data and Data.Properties

	if not Identifier then return end

	if Object and Object:IsDescendantOf(game) and type(Properties) == "table" then
		for Property, Value in pairs(Properties) do
			pcall(function()
				Object[Property] = Value
			end)
		end
	end

	Packets.setPropertiesConfirm.send({
		Identifier = Identifier,
	})
end, ScriptTrove)

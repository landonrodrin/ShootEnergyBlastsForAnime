local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local InventoryController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("InventoryController"))
local Player = Players.LocalPlayer

local function DropApp()
	local CanDrop, SetCanDrop = React.useState(InventoryController.CanDrop())

	React.useEffect(function()
		local ChangedConnection = InventoryController.Changed:Connect(function(Name, Value)
			if Name ~= "CanDrop" then return end
			SetCanDrop(Value == true)
		end)

		local CharacterConnection = Player.CharacterRemoving:Connect(function()
			SetCanDrop(false)
		end)

		return function()
			ChangedConnection:Disconnect()
			CharacterConnection:Disconnect()
		end
	end, {})

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.92),
		Size = UDim2.fromOffset(180, 54),
		Visible = CanDrop,
	}, {
		Drop = React.createElement(ReactUi.Button, {
			BackgroundColor3 = ReactUi.Colours.Red,
			OnActivated = function()
				InventoryController.Drop()
			end,
			Size = UDim2.fromScale(1, 1),
			Text = "Drop",
		}),
	})
end

return DropApp

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local BUTTON_SIZE = UDim2.fromOffset(150, 54)
local RIGHT_PADDING = 28
local ROW_SPACING = 64

local function RightRailButton(Props)
	local Row = Props.Row or 1

	return React.createElement(ReactUi.Button, {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Props.BackgroundColor3,
		MaxTextSize = Props.MaxTextSize or 24,
		OnActivated = Props.OnActivated,
		Position = UDim2.new(1, -RIGHT_PADDING, 0.5, (Row - 2) * ROW_SPACING),
		Size = Props.Size or BUTTON_SIZE,
		StrokeColor = Props.StrokeColor,
		Text = Props.Text,
		ZIndex = Props.ZIndex or 20,
	})
end

return RightRailButton

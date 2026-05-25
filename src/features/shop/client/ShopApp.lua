local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ReactUi"))
local RightRailButton = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("RightRailButton"))

local function ShopApp()
	local Open, SetOpen = React.useState(false)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Button = React.createElement(RightRailButton, {
			BackgroundColor3 = ReactUi.Colours.Accent,
			OnActivated = function()
				SetOpen(function(WasOpen)
					return not WasOpen
				end)
			end,
			Row = 1,
			Text = "Shop",
		}),
		Panel = React.createElement(ReactUi.Panel, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromOffset(420, 240),
			StrokeColor = ReactUi.Colours.Accent,
			StrokeThickness = 3,
			Visible = Open,
		}, {
			Header = React.createElement(ReactUi.Header, {
				OnClose = function()
					SetOpen(false)
				end,
				Title = "Shop",
			}),
			Message = React.createElement(ReactUi.EmptyState, {
				Text = "Coming Soon",
			}),
		}),
	})
end

return ShopApp

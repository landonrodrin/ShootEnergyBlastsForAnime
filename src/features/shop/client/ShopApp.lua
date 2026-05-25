local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ReactUi"))
local UiAssets = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiAssets"))
local RightRailButton = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("RightRailButton"))

local function ShopApp(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local Open = if Props.SetActivePanel then Props.ActivePanel == "Shop" else LocalOpen

	local function setOpen(NextOpen)
		if Props.SetActivePanel then
			Props.SetActivePanel(if NextOpen then "Shop" else nil)
		else
			SetLocalOpen(NextOpen)
		end
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Button = React.createElement(RightRailButton, {
			BackgroundColor3 = ReactUi.Colours.Accent,
			Icon = UiAssets.Icons.Shop,
			OnActivated = function()
				setOpen(not Open)
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
					setOpen(false)
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

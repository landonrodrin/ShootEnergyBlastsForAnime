local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local RightRailButton = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("RightRailButton"))
local UiAssets = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiAssets"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ReactUi"))

local RIGHT_RAIL = UiTuning.RightRail

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		IconSize = RIGHT_RAIL.IconSize,
		ItemWidth = RIGHT_RAIL.ItemWidth,
		ItemHeight = RIGHT_RAIL.ItemHeight,
		RowSpacing = RIGHT_RAIL.RowSpacing,
		RightPadding = RIGHT_RAIL.RightPadding,
		LabelMaxTextSize = RIGHT_RAIL.LabelMaxTextSize,
		LabelHeight = RIGHT_RAIL.LabelHeight,
	},
	story = function(Props)
		local Controls = Props.controls
		local ItemSize = UDim2.fromOffset(Controls.ItemWidth, Controls.ItemHeight)

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			Shop = React.createElement(RightRailButton, {
				BackgroundColor3 = ReactUi.Colours.Accent,
				Icon = UiAssets.Icons.Shop,
				IconSize = Controls.IconSize,
				ItemSize = ItemSize,
				LabelHeight = Controls.LabelHeight,
				LabelMaxTextSize = Controls.LabelMaxTextSize,
				LabelOffset = Controls.IconSize,
				RightPadding = Controls.RightPadding,
				Row = 1,
				RowSpacing = Controls.RowSpacing,
				Text = "Shop",
			}),
			Index = React.createElement(RightRailButton, {
				BackgroundColor3 = Color3.fromRGB(110, 116, 255),
				Icon = UiAssets.Icons.Index,
				IconSize = Controls.IconSize,
				ItemSize = ItemSize,
				LabelHeight = Controls.LabelHeight,
				LabelMaxTextSize = Controls.LabelMaxTextSize,
				LabelOffset = Controls.IconSize,
				RightPadding = Controls.RightPadding,
				Row = 2,
				RowSpacing = Controls.RowSpacing,
				Text = "Index",
			}),
			Rebirth = React.createElement(RightRailButton, {
				BackgroundColor3 = Color3.fromRGB(235, 77, 112),
				Icon = UiAssets.Icons.Rebirth,
				IconSize = Controls.IconSize,
				ItemSize = ItemSize,
				LabelHeight = Controls.LabelHeight,
				LabelMaxTextSize = Controls.LabelMaxTextSize,
				LabelOffset = Controls.IconSize,
				RightPadding = Controls.RightPadding,
				Row = 3,
				RowSpacing = Controls.RowSpacing,
				Text = "Rebirth",
			}),
		})
	end,
}

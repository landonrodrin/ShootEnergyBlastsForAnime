local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local RightRailView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("RightRailView"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))

local RIGHT_RAIL = UiTuning.RightRail

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		IconSize = RIGHT_RAIL.IconSize,
		ItemWidth = RIGHT_RAIL.ItemWidth,
		ItemHeight = RIGHT_RAIL.ItemHeight,
		RowSpacing = RIGHT_RAIL.RowSpacing,
		LabelOffset = RIGHT_RAIL.LabelOffset,
		LabelWidth = RIGHT_RAIL.LabelWidth,
		LabelTextSize = RIGHT_RAIL.LabelTextSize,
		LabelHeight = RIGHT_RAIL.LabelHeight,
	},
	story = function(Props)
		local Controls = Props.controls

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			RightRail = React.createElement(RightRailView, {
				IconSize = Controls.IconSize,
				ItemHeight = Controls.ItemHeight,
				ItemWidth = Controls.ItemWidth,
				LabelHeight = Controls.LabelHeight,
				LabelOffset = Controls.LabelOffset,
				LabelTextSize = Controls.LabelTextSize,
				LabelWidth = Controls.LabelWidth,
				OnIndexActivated = function() end,
				OnRebirthActivated = function() end,
				OnShopActivated = function() end,
				RowSpacing = Controls.RowSpacing,
			}),
		})
	end,
}

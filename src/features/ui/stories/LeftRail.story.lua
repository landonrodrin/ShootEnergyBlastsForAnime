local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local LeftRailView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("LeftRailView"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))

local LEFT_RAIL = UiTuning.LeftRail

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Speed = 58,
		Money = 723010,
		FriendBonus = 0,
		IconSize = LEFT_RAIL.IconSize,
		RowHeight = LEFT_RAIL.RowHeight,
		RowWidth = LEFT_RAIL.RowWidth,
		TextWidth = LEFT_RAIL.TextWidth,
		TextSize = LEFT_RAIL.TextSize,
		LeftPadding = LEFT_RAIL.LeftPadding,
		RowSpacing = LEFT_RAIL.RowSpacing,
	},
	story = function(Props)
		local Controls = Props.controls
		local RowHeight = Controls.RowHeight
		local RowSpacing = Controls.RowSpacing
		local ContainerHeight = RowHeight * 3 + RowSpacing * 2

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			LeftRail = React.createElement(LeftRailView, {
				ContainerHeight = ContainerHeight,
				ContainerWidth = Controls.RowWidth,
				FriendBonusPercent = Controls.FriendBonus,
				IconSize = Controls.IconSize,
				IconSlotSize = Controls.RowHeight,
				LeftPadding = Controls.LeftPadding,
				Money = Controls.Money,
				OnInvite = function() end,
				RowHeight = Controls.RowHeight,
				RowWidth = Controls.RowWidth,
				RowSpacing = Controls.RowSpacing,
				Speed = Controls.Speed,
				TextSize = Controls.TextSize,
				TextWidth = Controls.TextWidth,
			}),
		})
	end,
}

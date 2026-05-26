local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local DataHudView = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("DataHudView"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))

local DATA_HUD = UiTuning.DataHud

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Speed = 58,
		Money = 723010,
		FriendBonus = 0,
		IconSize = DATA_HUD.IconSize,
		RowHeight = DATA_HUD.RowHeight,
		RowWidth = DATA_HUD.RowWidth,
		TextWidth = DATA_HUD.TextWidth,
		TextMaxSize = DATA_HUD.TextMaxSize,
		VerticalPadding = DATA_HUD.VerticalPadding,
	},
	story = function(Props)
		local Controls = Props.controls
		local RowHeight = Controls.RowHeight
		local VerticalPadding = Controls.VerticalPadding
		local ContainerHeight = RowHeight * 3 + VerticalPadding * 2

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			DataHud = React.createElement(DataHudView, {
				ContainerHeight = ContainerHeight,
				ContainerWidth = Controls.RowWidth,
				FriendBonusPercent = Controls.FriendBonus,
				IconSize = Controls.IconSize,
				IconSlotSize = Controls.RowHeight,
				Money = Controls.Money,
				OnInvite = function() end,
				RowHeight = Controls.RowHeight,
				RowWidth = Controls.RowWidth,
				Speed = Controls.Speed,
				TextMaxSize = Controls.TextMaxSize,
				TextWidth = Controls.TextWidth,
				VerticalPadding = Controls.VerticalPadding,
			}),
		})
	end,
}

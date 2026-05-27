local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ReactUi"))
local UpgradesPanelView = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("UpgradesPanelView"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))

local GAMEPLAY_PANELS = UiTuning.GameplayPanels

local function sharedTuning(Controls)
	local Outer = GAMEPLAY_PANELS.Outer

	return {
		EmptyState = GAMEPLAY_PANELS.EmptyState,
		Header = GAMEPLAY_PANELS.Header,
		Outer = {
			AnchorPoint = Outer.AnchorPoint,
			BackgroundColor3 = Outer.BackgroundColor3,
			BackgroundTransparency = Outer.BackgroundTransparency,
			CornerRadius = Outer.CornerRadius,
			Position = UDim2.fromScale(Controls.PositionX, Controls.PositionY),
			Size = UDim2.fromScale(Controls.PanelWidthScale, Controls.PanelHeightScale),
			StrokeThickness = Outer.StrokeThickness,
			StrokeTransparency = Outer.StrokeTransparency,
		},
		ReferenceResolution = GAMEPLAY_PANELS.ReferenceResolution,
	}
end

local function rows(Maxed)
	return {
		{
			Colour = ReactUi.Colours.Blue,
			Disabled = Maxed,
			Id = "Speed1",
			MoneyText = Maxed and "MAX" or "$4.2K",
			OnMoney = function() end,
			OnRobux = function() end,
			RobuxText = Maxed and "MAX" or "\u{E002} 19",
			Title = "Speed +1",
			ValueText = Maxed and "MAX" or "42 -> 43",
		},
		{
			Colour = ReactUi.Colours.Blue,
			Disabled = Maxed,
			Id = "Speed5",
			MoneyText = Maxed and "MAX" or "$22K",
			OnMoney = function() end,
			OnRobux = function() end,
			RobuxText = Maxed and "MAX" or "\u{E002} 49",
			Title = "Speed +5",
			ValueText = Maxed and "MAX" or "42 -> 47",
		},
		{
			Colour = ReactUi.Colours.Blue,
			Disabled = Maxed,
			Id = "Speed10",
			MoneyText = Maxed and "MAX" or "$54K",
			OnMoney = function() end,
			OnRobux = function() end,
			RobuxText = Maxed and "MAX" or "\u{E002} 89",
			Title = "Speed +10",
			ValueText = Maxed and "MAX" or "42 -> 52",
		},
		{
			Colour = ReactUi.Colours.Green,
			Disabled = Maxed,
			Id = "Carry1",
			MoneyText = Maxed and "MAX" or "$18K",
			OnMoney = function() end,
			OnRobux = function() end,
			RobuxText = Maxed and "MAX" or "\u{E002} 39",
			Title = "Carry +1",
			ValueText = Maxed and "MAX" or "12 -> 13",
		},
	}
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		PanelWidthScale = GAMEPLAY_PANELS.Outer.Size.X.Scale,
		PanelHeightScale = GAMEPLAY_PANELS.Outer.Size.Y.Scale,
		PositionX = GAMEPLAY_PANELS.Outer.Position.X.Scale,
		PositionY = GAMEPLAY_PANELS.Outer.Position.Y.Scale,
		Maxed = false,
	},
	story = function(Props)
		local Controls = Props.controls

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			Panel = React.createElement(UpgradesPanelView, {
				OnClose = function() end,
				Rows = rows(Controls.Maxed),
				SharedTuning = sharedTuning(Controls),
				Tuning = GAMEPLAY_PANELS.Upgrades,
				Visible = true,
			}),
		})
	end,
}

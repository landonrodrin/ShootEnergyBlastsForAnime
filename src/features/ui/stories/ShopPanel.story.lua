local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local ShopPanelView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("ShopPanelView"))
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

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		PanelWidthScale = GAMEPLAY_PANELS.Outer.Size.X.Scale,
		PanelHeightScale = GAMEPLAY_PANELS.Outer.Size.Y.Scale,
		PositionX = GAMEPLAY_PANELS.Outer.Position.X.Scale,
		PositionY = GAMEPLAY_PANELS.Outer.Position.Y.Scale,
	},
	story = function(Props)
		local Controls = Props.controls

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			Panel = React.createElement(ShopPanelView, {
				OnClose = function() end,
				SharedTuning = sharedTuning(Controls),
				Tuning = GAMEPLAY_PANELS.Shop,
				Visible = true,
			}),
		})
	end,
}

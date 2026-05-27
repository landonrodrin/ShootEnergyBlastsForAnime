local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local RebirthPanelView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("RebirthPanelView"))
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
		Rebirths = 2,
		Speed = 1250,
		RequiredSpeed = 2500,
	},
	story = function(Props)
		local Controls = Props.controls
		local Progress = math.clamp(Controls.Speed / Controls.RequiredSpeed, 0, 1)

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			Panel = React.createElement(RebirthPanelView, {
				CanRebirth = true,
				CurrentText = string.format("Current: Rebirth %s | 2x Money", Controls.Rebirths),
				NextText = string.format("Next: Rebirth %s | 3x Money", Controls.Rebirths + 1),
				OnClose = function() end,
				OnRebirth = function() end,
				OnSkip = function() end,
				Progress = Progress,
				ProgressText = string.format("Speed %s / %s", Controls.Speed, Controls.RequiredSpeed),
				SharedTuning = sharedTuning(Controls),
				Tuning = GAMEPLAY_PANELS.Rebirth,
				Visible = true,
			}),
		})
	end,
}

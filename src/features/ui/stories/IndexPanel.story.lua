local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local IndexPanelView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("IndexPanelView"))
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

local function animeRows(UnlockCount)
	local Samples = {
		{ Accent = Color3.fromRGB(255, 190, 46), Area = "Spawn", Name = "Luffy" },
		{ Accent = Color3.fromRGB(95, 210, 255), Area = "Desert", Name = "Goku" },
		{ Accent = Color3.fromRGB(255, 218, 84), Area = "Leaf", Name = "Naruto" },
		{ Accent = Color3.fromRGB(235, 77, 112), Area = "Arena", Name = "Ichigo" },
		{ Accent = Color3.fromRGB(71, 210, 113), Area = "Forest", Name = "Tanjiro" },
	}
	local Rows = {}

	for Index = 1, 15 do
		local Sample = Samples[((Index - 1) % #Samples) + 1]
		table.insert(Rows, {
			Accent = Sample.Accent,
			Area = Sample.Area,
			IsUnlocked = Index <= UnlockCount,
			LayoutOrder = Index,
			Name = Sample.Name,
		})
	end

	return Rows
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		PanelWidthScale = GAMEPLAY_PANELS.Outer.Size.X.Scale,
		PanelHeightScale = GAMEPLAY_PANELS.Outer.Size.Y.Scale,
		PositionX = GAMEPLAY_PANELS.Outer.Position.X.Scale,
		PositionY = GAMEPLAY_PANELS.Outer.Position.Y.Scale,
		SelectedMutation = "Default",
		Unlocked = 7,
	},
	story = function(Props)
		local Controls = Props.controls
		local Mutations = {
			{ Colour = Color3.fromRGB(255, 190, 46), LayoutOrder = 1, Name = "Default" },
			{ Colour = Color3.fromRGB(95, 210, 255), LayoutOrder = 2, Name = "Diamond" },
			{ Colour = Color3.fromRGB(255, 218, 84), LayoutOrder = 3, Name = "Gold" },
		}

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			Panel = React.createElement(IndexPanelView, {
				Anime = animeRows(Controls.Unlocked),
				Mutations = Mutations,
				OnClose = function() end,
				OnSelectMutation = function() end,
				SelectedMutation = Controls.SelectedMutation,
				SharedTuning = sharedTuning(Controls),
				Tuning = GAMEPLAY_PANELS.Index,
				Visible = true,
			}),
		})
	end,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local SellPanelView = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("SellPanelView"))
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

local function buildItems(Count)
	local Samples = {
		{ Accent = Color3.fromRGB(255, 190, 46), Mutation = "Default", Name = "Luffy", SellText = "$12.5K" },
		{ Accent = Color3.fromRGB(95, 210, 255), Mutation = "Diamond", Name = "Goku", SellText = "$48K" },
		{ Accent = Color3.fromRGB(255, 218, 84), Mutation = "Gold", Name = "Naruto", SellText = "$25K" },
	}
	local Items = {}

	for Index = 1, Count do
		local Sample = Samples[((Index - 1) % #Samples) + 1]
		table.insert(Items, {
			Accent = Sample.Accent,
			Id = Index,
			Mutation = Sample.Mutation,
			MutationText = string.format("%s Lvl %s", Sample.Mutation, Index),
			Name = Sample.Name,
			SellText = Sample.SellText,
		})
	end

	return Items
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		PanelWidthScale = GAMEPLAY_PANELS.Outer.Size.X.Scale,
		PanelHeightScale = GAMEPLAY_PANELS.Outer.Size.Y.Scale,
		PositionX = GAMEPLAY_PANELS.Outer.Position.X.Scale,
		PositionY = GAMEPLAY_PANELS.Outer.Position.Y.Scale,
		ItemCount = 6,
		ConfirmVisible = false,
	},
	story = function(Props)
		local Controls = Props.controls

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			Panel = React.createElement(SellPanelView, {
				CanSellAll = Controls.ItemCount > 0,
				ConfirmText = string.format("Sell all %s inventory anime for $214.5K?", Controls.ItemCount),
				ConfirmVisible = Controls.ConfirmVisible,
				Items = buildItems(Controls.ItemCount),
				OnCancelConfirm = function() end,
				OnClose = function() end,
				OnConfirmSellAll = function() end,
				OnSellAll = function() end,
				OnSellSingle = function() end,
				SellAllText = "Sell All ($214.5K)",
				SharedTuning = sharedTuning(Controls),
				Tuning = GAMEPLAY_PANELS.Sell,
				Visible = true,
			}),
		})
	end,
}

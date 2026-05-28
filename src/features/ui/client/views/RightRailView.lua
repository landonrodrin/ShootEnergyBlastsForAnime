local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local UiAssets = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiAssets"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))
local RightRailButton = require(script.Parent:WaitForChild("RightRailButton"))

local HUD_RAILS = UiTuning.HudRails
local RIGHT_RAIL = UiTuning.RightRail

local function RightRailView(Props)
	Props = Props or {}

	local ItemWidth = Props.ItemWidth or RIGHT_RAIL.ItemWidth
	local ItemHeight = Props.ItemHeight or RIGHT_RAIL.ItemHeight
	local RowSpacing = Props.RowSpacing or RIGHT_RAIL.RowSpacing
	local ItemSize = UDim2.fromOffset(ItemWidth, ItemHeight)
	local RowPadding = math.max(0, RowSpacing - ItemHeight)
	local ContainerHeight = ItemHeight * 3 + RowPadding * 2
	local RailTuning = HUD_RAILS.Right
	local SharedButtonProps = {
		IconSize = Props.IconSize,
		ItemSize = ItemSize,
		LabelHeight = Props.LabelHeight,
		LabelOffset = Props.LabelOffset,
		LabelTextSize = Props.LabelTextSize,
		LabelWidth = Props.LabelWidth,
		ZIndex = Props.ZIndex,
	}

	return React.createElement("Frame", {
		AnchorPoint = Props.AnchorPoint or RailTuning.AnchorPoint,
		BackgroundTransparency = 1,
		Position = Props.Position or RailTuning.Position,
		Size = Props.Size or UDim2.fromOffset(ItemWidth, ContainerHeight),
		ZIndex = Props.ZIndex or 20,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, RowPadding),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		Shop = React.createElement(RightRailButton, {
			BackgroundColor3 = ReactUi.Colours.Accent,
			Icon = UiAssets.Icons.Shop,
			IconSize = SharedButtonProps.IconSize,
			ItemSize = SharedButtonProps.ItemSize,
			LabelHeight = SharedButtonProps.LabelHeight,
			LabelOffset = SharedButtonProps.LabelOffset,
			LabelTextSize = SharedButtonProps.LabelTextSize,
			LabelWidth = SharedButtonProps.LabelWidth,
			LayoutOrder = 1,
			OnActivated = Props.OnShopActivated,
			Row = 1,
			Text = "Shop",
			ZIndex = SharedButtonProps.ZIndex,
		}),
		Index = React.createElement(RightRailButton, {
			BackgroundColor3 = Color3.fromRGB(110, 116, 255),
			Icon = UiAssets.Icons.Index,
			IconSize = SharedButtonProps.IconSize,
			ItemSize = SharedButtonProps.ItemSize,
			LabelHeight = SharedButtonProps.LabelHeight,
			LabelOffset = SharedButtonProps.LabelOffset,
			LabelTextSize = SharedButtonProps.LabelTextSize,
			LabelWidth = SharedButtonProps.LabelWidth,
			LayoutOrder = 2,
			OnActivated = Props.OnIndexActivated,
			Row = 2,
			Text = "Index",
			ZIndex = SharedButtonProps.ZIndex,
		}),
		Rebirth = React.createElement(RightRailButton, {
			BackgroundColor3 = Color3.fromRGB(235, 77, 112),
			Icon = UiAssets.Icons.Rebirth,
			IconSize = SharedButtonProps.IconSize,
			ItemSize = SharedButtonProps.ItemSize,
			LabelHeight = SharedButtonProps.LabelHeight,
			LabelOffset = SharedButtonProps.LabelOffset,
			LabelTextSize = SharedButtonProps.LabelTextSize,
			LabelWidth = SharedButtonProps.LabelWidth,
			LayoutOrder = 3,
			OnActivated = Props.OnRebirthActivated,
			Row = 3,
			Text = "Rebirth",
			ZIndex = SharedButtonProps.ZIndex,
		}),
	})
end

return RightRailView

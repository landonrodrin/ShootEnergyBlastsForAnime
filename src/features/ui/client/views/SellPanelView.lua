local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local AnimeSlotIcon = require(script.Parent:WaitForChild("AnimeSlotIcon"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local function headerProps(SharedTuning, Tuning, OnClose)
	local Header = SharedTuning.Header

	return {
		BackgroundColor3 = Tuning.StrokeColor,
		CloseMaxTextSize = Header.CloseMaxTextSize,
		ClosePosition = Header.ClosePosition,
		CloseSize = Header.CloseSize,
		CloseText = Header.CloseText,
		OnClose = OnClose,
		Position = Header.Position,
		Size = Header.Size,
		Title = Tuning.Title,
		TitleMaxTextSize = Header.TitleMaxTextSize,
		TitlePosition = Header.TitlePosition,
		TitleSize = Header.TitleSize,
	}
end

local function SellPanelView(Props)
	local SharedTuning = Props.SharedTuning
	local Tuning = Props.Tuning
	local ListTuning = Tuning.List
	local SellAllTuning = Tuning.SellAll
	local ConfirmTuning = Tuning.Confirm

	local ListChildren = {
		Layout = React.createElement("UIListLayout", {
			Padding = ListTuning.Padding,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for Index, Item in ipairs(Props.Items) do
		ListChildren[string.format("Item%d", Index)] = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Color3.fromRGB(26, 29, 38),
			LayoutOrder = Index,
			Size = ListTuning.RowSize,
			StrokeColor = Item.Accent,
		}, {
			Preview = React.createElement(AnimeSlotIcon, {
				AnimeName = Item.Name,
				Level = Item.Level,
				Mutation = Item.Mutation,
				Position = ListTuning.PreviewPosition,
				Scale = ListTuning.PreviewScale,
				ShowLevelBadge = true,
				Size = ListTuning.PreviewSize,
				Tuning = ListTuning.SlotIcon,
			}),
			Mutation = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0, 0.5),
				MaxTextSize = ListTuning.DetailMaxTextSize,
				Position = ListTuning.MutationPosition,
				Size = ListTuning.MutationSize,
				Text = Item.MutationText,
				TextColor3 = Item.MutationColor,
				TextScaled = true,
				TextStrokeTransparency = 0.75,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Area = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0, 0.5),
				MaxTextSize = ListTuning.DetailMaxTextSize,
				Position = ListTuning.AreaPosition,
				Size = ListTuning.AreaSize,
				Text = Item.AreaText,
				TextColor3 = Item.AreaColor,
				TextScaled = true,
				TextStrokeTransparency = 0.75,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			NameLevel = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0, 0.5),
				MaxTextSize = ListTuning.NameLevelMaxTextSize,
				Position = ListTuning.NameLevelPosition,
				Size = ListTuning.NameLevelSize,
				Text = Item.NameLevelText,
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Income = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0, 0.5),
				MaxTextSize = ListTuning.DetailMaxTextSize,
				Position = ListTuning.IncomePosition,
				Size = ListTuning.IncomeSize,
				Text = Item.IncomeText,
				TextColor3 = ReactUi.Colours.Green,
				TextScaled = true,
				TextStrokeTransparency = 0.4,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Sell = React.createElement(ReactUi.Button, {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = ReactUi.Colours.Green,
				MaxTextSize = ListTuning.SellButtonMaxTextSize,
				OnActivated = function()
					Props.OnSellSingle(Item.Id)
				end,
				Position = ListTuning.SellButtonPosition,
				Size = ListTuning.SellButtonSize,
				Text = Item.SellText,
			}),
		})
	end

	if #Props.Items == 0 then
		ListChildren.Empty = React.createElement(ReactUi.Text, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			MaxTextSize = SharedTuning.EmptyState.MaxTextSize,
			Position = UDim2.fromOffset(ListTuning.Size.X.Offset * 0.5, ListTuning.Size.Y.Offset * 0.5),
			Size = SharedTuning.EmptyState.Size,
			Text = Tuning.EmptyText,
			TextColor3 = ReactUi.Colours.Muted,
			TextStrokeTransparency = 0.8,
		})
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Panel = React.createElement(ReactUi.GameplayPanel, {
			GameplayPanels = SharedTuning,
			SkipCloseTween = Props.SkipCloseTween,
			StrokeColor = Tuning.StrokeColor,
			Visible = Props.Visible,
		}, {
			Header = React.createElement(ReactUi.Header, headerProps(SharedTuning, Tuning, Props.OnClose)),
			List = React.createElement("ScrollingFrame", {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, 0),
				Position = ListTuning.Position,
				ScrollBarThickness = ListTuning.ScrollBarThickness,
				Size = ListTuning.Size,
			}, ListChildren),
			SellAll = React.createElement(ReactUi.Button, {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = ReactUi.Colours.Green,
				Disabled = not Props.CanSellAll,
				OnActivated = Props.OnSellAll,
				Position = SellAllTuning.Position,
				Size = SellAllTuning.Size,
				Text = Props.SellAllText,
			}),
		}),
		Confirm = React.createElement(ReactUi.Panel, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(18, 20, 28),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = ConfirmTuning.Size,
			StrokeColor = Tuning.StrokeColor,
			StrokeThickness = SharedTuning.Outer.StrokeThickness,
			Visible = Props.ConfirmVisible,
			ZIndex = 20,
		}, {
			Message = React.createElement(ReactUi.Text, {
				Position = ConfirmTuning.MessagePosition,
				Size = ConfirmTuning.MessageSize,
				Text = Props.ConfirmText,
				ZIndex = 21,
			}),
			Cancel = React.createElement(ReactUi.Button, {
				BackgroundColor3 = ReactUi.Colours.PanelLight,
				OnActivated = Props.OnCancelConfirm,
				Position = ConfirmTuning.CancelPosition,
				Size = ConfirmTuning.CancelSize,
				Text = "Cancel",
				ZIndex = 21,
			}),
			Confirm = React.createElement(ReactUi.Button, {
				BackgroundColor3 = ReactUi.Colours.Green,
				OnActivated = Props.OnConfirmSellAll,
				Position = ConfirmTuning.ConfirmPosition,
				Size = ConfirmTuning.ConfirmSize,
				Text = "Sell",
				ZIndex = 21,
			}),
		}),
	})
end

return SellPanelView

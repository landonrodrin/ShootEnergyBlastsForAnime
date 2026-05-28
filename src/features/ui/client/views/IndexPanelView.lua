local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local AnimeSlotIcon = require(script.Parent:WaitForChild("AnimeSlotIcon"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local function headerProps(SharedTuning, Tuning, SelectedMutation, OnClose)
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
		Title = string.format(Tuning.TitleFormat, SelectedMutation),
		TitleMaxTextSize = Header.TitleMaxTextSize,
		TitlePosition = Header.TitlePosition,
		TitleSize = Header.TitleSize,
	}
end

local function IndexPanelView(Props)
	local SharedTuning = Props.SharedTuning
	local Tuning = Props.Tuning
	local MutationTuning = Tuning.Mutations
	local AnimeTuning = Tuning.Anime

	local MutationChildren = {
		Layout = React.createElement("UIListLayout", {
			FillDirection = MutationTuning.FillDirection or Enum.FillDirection.Horizontal,
			Padding = MutationTuning.Padding,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for _, Entry in ipairs(Props.Mutations) do
		local IsSelected = Props.SelectedMutation == Entry.Name
		MutationChildren[Entry.Name] = React.createElement(ReactUi.Button, {
			BackgroundColor3 = Entry.Colour,
			LayoutOrder = Entry.LayoutOrder,
			MaxTextSize = MutationTuning.ButtonMaxTextSize,
			OnActivated = function()
				Props.OnSelectMutation(Entry.Name)
			end,
			Size = MutationTuning.ButtonSize,
			StrokeColor = MutationTuning.SelectedStrokeColor or ReactUi.Colours.Text,
			StrokeThickness = IsSelected and MutationTuning.SelectedStrokeThickness or MutationTuning.StrokeThickness,
			StrokeTransparency = IsSelected and 0 or MutationTuning.StrokeTransparency,
			Text = Entry.Name,
		})
	end

	local AnimeChildren = {
		Grid = React.createElement("UIGridLayout", {
			CellPadding = AnimeTuning.CellPadding,
			CellSize = AnimeTuning.CellSize,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for _, Entry in ipairs(Props.Anime) do
		AnimeChildren[Entry.Name] = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Color3.fromRGB(24, 27, 36),
			LayoutOrder = Entry.LayoutOrder,
			Size = AnimeTuning.CardSize,
			StrokeColor = Entry.IsUnlocked and Entry.Accent or Color3.fromRGB(86, 91, 108),
			StrokeTransparency = Entry.IsUnlocked and 0.15 or 0.45,
		}, {
			Rarity = React.createElement(ReactUi.Text, {
				Position = AnimeTuning.RarityPosition,
				Size = AnimeTuning.RaritySize,
				Text = Entry.Area,
				TextColor3 = Entry.Accent,
				TextScaled = true,
				TextStrokeTransparency = 0.7,
			}, {
				UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = AnimeTuning.RarityMaxTextSize,
				}),
			}),
			Preview = React.createElement(AnimeSlotIcon, {
				AnimeName = Entry.Name,
				Mutation = Props.SelectedMutation,
				Position = AnimeTuning.PreviewPosition,
				Scale = AnimeTuning.PreviewScale,
				Silhouette = not Entry.IsUnlocked,
				Size = AnimeTuning.PreviewSize,
				Tuning = AnimeTuning.SlotIcon,
			}),
			Name = React.createElement(ReactUi.Text, {
				Position = AnimeTuning.NamePosition,
				Size = AnimeTuning.NameSize,
				Text = Entry.IsUnlocked and Entry.Name or "?",
				TextScaled = true,
			}),
			Income = React.createElement(ReactUi.Text, {
				MaxTextSize = AnimeTuning.IncomeMaxTextSize,
				Position = AnimeTuning.IncomePosition,
				Size = AnimeTuning.IncomeSize,
				Text = Entry.IncomeText,
				TextColor3 = ReactUi.Colours.Green,
				TextScaled = true,
				TextStrokeTransparency = 0.45,
			}),
		})
	end

	return React.createElement(ReactUi.GameplayPanel, {
		GameplayPanels = SharedTuning,
		SkipCloseTween = Props.SkipCloseTween,
		StrokeColor = Tuning.StrokeColor,
		Visible = Props.Visible,
	}, {
		Header = React.createElement(ReactUi.Header, headerProps(SharedTuning, Tuning, Props.SelectedMutation, Props.OnClose)),
		Mutations = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = MutationTuning.BackgroundColor3,
			BackgroundTransparency = MutationTuning.BackgroundTransparency,
			Padding = MutationTuning.ContainerPadding,
			Position = MutationTuning.Position,
			Size = MutationTuning.Size,
			StrokeColor = MutationTuning.StrokeColor or Tuning.StrokeColor,
			StrokeThickness = MutationTuning.StrokeThickness,
			StrokeTransparency = MutationTuning.ContainerStrokeTransparency,
		}, MutationChildren),
		Summary = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Tuning.Summary.BackgroundColor3,
			BackgroundTransparency = Tuning.Summary.BackgroundTransparency,
			Position = Tuning.Summary.Position,
			Size = Tuning.Summary.Size,
			StrokeColor = Tuning.Summary.StrokeColor or Tuning.StrokeColor,
			StrokeThickness = Tuning.Summary.StrokeThickness,
			StrokeTransparency = Tuning.Summary.StrokeTransparency,
		}, {
			Label = React.createElement(ReactUi.Text, {
				Position = Tuning.Summary.LabelPosition,
				Size = Tuning.Summary.LabelSize,
				Text = Props.CollectionText,
				MaxTextSize = Tuning.Summary.LabelMaxTextSize,
			}),
		}),
		AnimeContainer = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = AnimeTuning.BackgroundColor3,
			BackgroundTransparency = AnimeTuning.BackgroundTransparency,
			Position = AnimeTuning.Position,
			Size = AnimeTuning.Size,
			StrokeColor = AnimeTuning.StrokeColor or Tuning.StrokeColor,
			StrokeThickness = AnimeTuning.StrokeThickness,
			StrokeTransparency = AnimeTuning.ContainerStrokeTransparency,
		}, {
			Anime = React.createElement("ScrollingFrame", {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, 0),
				Position = AnimeTuning.ScrollPosition,
				ScrollBarThickness = AnimeTuning.ScrollBarThickness,
				Size = AnimeTuning.ScrollSize,
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingBottom = AnimeTuning.PaddingBottom,
					PaddingLeft = AnimeTuning.PaddingLeft,
					PaddingRight = AnimeTuning.PaddingRight,
					PaddingTop = AnimeTuning.PaddingTop,
				}),
				Children = React.createElement(React.Fragment, nil, AnimeChildren),
			}),
		}),
	})
end

return IndexPanelView

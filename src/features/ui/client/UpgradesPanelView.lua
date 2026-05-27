local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
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

local function UpgradeRow(Props)
	local ListTuning = Props.ListTuning

	return React.createElement(ReactUi.Panel, {
		BackgroundColor3 = Color3.fromRGB(26, 29, 38),
		LayoutOrder = Props.LayoutOrder,
		Size = ListTuning.RowSize,
		StrokeColor = Props.Colour,
	}, {
		Title = React.createElement(ReactUi.Text, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = ListTuning.TitlePosition,
			Size = ListTuning.TitleSize,
			Text = Props.Title,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Value = React.createElement(ReactUi.Text, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = ListTuning.ValuePosition,
			Size = ListTuning.ValueSize,
			Text = Props.ValueText,
			TextColor3 = ReactUi.Colours.Muted,
			TextScaled = true,
			TextStrokeTransparency = 0.8,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Money = React.createElement(ReactUi.Button, {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = ReactUi.Colours.Green,
			Disabled = Props.Disabled,
			MaxTextSize = ListTuning.ButtonMaxTextSize,
			OnActivated = Props.OnMoney,
			Position = ListTuning.MoneyButtonPosition,
			Size = ListTuning.MoneyButtonSize,
			Text = Props.MoneyText,
		}),
		Robux = React.createElement(ReactUi.Button, {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = ReactUi.Colours.Accent,
			Disabled = Props.Disabled,
			MaxTextSize = ListTuning.ButtonMaxTextSize,
			OnActivated = Props.OnRobux,
			Position = ListTuning.RobuxButtonPosition,
			Size = ListTuning.RobuxButtonSize,
			Text = Props.RobuxText,
		}),
	})
end

local function UpgradesPanelView(Props)
	local SharedTuning = Props.SharedTuning
	local Tuning = Props.Tuning
	local ListTuning = Tuning.List
	local RowChildren = {
		Layout = React.createElement("UIListLayout", {
			Padding = ListTuning.Padding,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for Index, Row in ipairs(Props.Rows) do
		RowChildren[Row.Id] = React.createElement(UpgradeRow, {
			Colour = Row.Colour,
			Disabled = Row.Disabled,
			LayoutOrder = Index,
			ListTuning = ListTuning,
			MoneyText = Row.MoneyText,
			OnMoney = Row.OnMoney,
			OnRobux = Row.OnRobux,
			RobuxText = Row.RobuxText,
			Title = Row.Title,
			ValueText = Row.ValueText,
		})
	end

	return React.createElement(ReactUi.GameplayPanel, {
		GameplayPanels = SharedTuning,
		StrokeColor = Tuning.StrokeColor,
		Visible = Props.Visible,
	}, {
		Header = React.createElement(ReactUi.Header, headerProps(SharedTuning, Tuning, Props.OnClose)),
		List = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = ListTuning.Position,
			Size = ListTuning.Size,
		}, RowChildren),
	})
end

return UpgradesPanelView

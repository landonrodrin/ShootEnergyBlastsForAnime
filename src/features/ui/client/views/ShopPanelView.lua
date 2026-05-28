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

local function ShopPanelView(Props)
	local SharedTuning = Props.SharedTuning
	local Tuning = Props.Tuning
	local EmptyState = SharedTuning.EmptyState

	return React.createElement(ReactUi.GameplayPanel, {
		GameplayPanels = SharedTuning,
		SkipCloseTween = Props.SkipCloseTween,
		StrokeColor = Tuning.StrokeColor,
		Visible = Props.Visible,
	}, {
		Header = React.createElement(ReactUi.Header, headerProps(SharedTuning, Tuning, Props.OnClose)),
		Message = React.createElement(ReactUi.Text, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			MaxTextSize = EmptyState.MaxTextSize,
			Position = EmptyState.Position,
			Size = EmptyState.Size,
			Text = Tuning.EmptyText,
			TextColor3 = ReactUi.Colours.Muted,
			TextStrokeTransparency = 0.8,
		}),
	})
end

return ShopPanelView

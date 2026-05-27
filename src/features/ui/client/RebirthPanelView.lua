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

local function RebirthPanelView(Props)
	local SharedTuning = Props.SharedTuning
	local Tuning = Props.Tuning

	return React.createElement(ReactUi.GameplayPanel, {
		GameplayPanels = SharedTuning,
		StrokeColor = Tuning.StrokeColor,
		Visible = Props.Visible,
	}, {
		Header = React.createElement(ReactUi.Header, headerProps(SharedTuning, Tuning, Props.OnClose)),
		Current = React.createElement(ReactUi.Text, {
			Position = Tuning.CurrentPosition,
			Size = Tuning.CurrentSize,
			Text = Props.CurrentText,
		}),
		Next = React.createElement(ReactUi.Text, {
			Position = Tuning.NextPosition,
			Size = Tuning.NextSize,
			Text = Props.NextText,
		}),
		ProgressBackground = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(42, 46, 60),
			BorderSizePixel = 0,
			Position = Tuning.ProgressPosition,
			Size = Tuning.ProgressSize,
		}, {
			UICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			Fill = React.createElement("Frame", {
				BackgroundColor3 = ReactUi.Colours.Green,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(Props.Progress, 1),
			}, {
				UICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			Label = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = Tuning.ProgressLabelPosition,
				Size = Tuning.ProgressLabelSize,
				Text = Props.ProgressText,
			}),
		}),
		Rebirth = React.createElement(ReactUi.Button, {
			BackgroundColor3 = ReactUi.Colours.Green,
			Disabled = not Props.CanRebirth,
			OnActivated = Props.OnRebirth,
			Position = Tuning.RebirthButtonPosition,
			Size = Tuning.RebirthButtonSize,
			Text = "Rebirth",
		}),
		Skip = React.createElement(ReactUi.Button, {
			BackgroundColor3 = ReactUi.Colours.Accent,
			Disabled = not Props.CanRebirth,
			OnActivated = Props.OnSkip,
			Position = Tuning.SkipButtonPosition,
			Size = Tuning.SkipButtonSize,
			Text = "Skip",
		}),
	})
end

return RebirthPanelView

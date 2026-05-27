local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))

local ReactUi = {}

ReactUi.Font = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
ReactUi.Colours = {
	Panel = Color3.fromRGB(20, 22, 30),
	PanelLight = Color3.fromRGB(36, 39, 52),
	Accent = Color3.fromRGB(255, 190, 46),
	Blue = Color3.fromRGB(61, 169, 255),
	Green = Color3.fromRGB(71, 210, 113),
	Red = Color3.fromRGB(235, 72, 72),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(178, 186, 205),
}

local function corner(Radius)
	return React.createElement("UICorner", {
		CornerRadius = Radius or UDim.new(0, 8),
	})
end

local function stroke(Colour, Thickness, Transparency)
	return React.createElement("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Colour or ReactUi.Colours.Accent,
		Thickness = Thickness or 2,
		Transparency = Transparency or 0,
	})
end

function ReactUi.Text(Props)
	local Children = Props.Children or Props.children
	if Props.MaxTextSize then
		Children = {
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = Props.MaxTextSize,
			}),
			Children = Children and React.createElement(React.Fragment, nil, Children) or nil,
		}
	end

	return React.createElement("TextLabel", {
		AnchorPoint = Props.AnchorPoint,
		AutomaticSize = Props.AutomaticSize,
		BackgroundTransparency = 1,
		FontFace = ReactUi.Font,
		LayoutOrder = Props.LayoutOrder,
		Position = Props.Position,
		RichText = Props.RichText == true,
		Size = Props.Size or UDim2.fromScale(1, 1),
		Text = Props.Text or "",
		TextColor3 = Props.TextColor3 or ReactUi.Colours.Text,
		TextScaled = Props.TextScaled ~= false,
		TextSize = Props.TextSize or 24,
		TextStrokeColor3 = Props.TextStrokeColor3,
		TextStrokeTransparency = Props.TextStrokeTransparency or 0.55,
		TextTransparency = Props.TextTransparency or 0,
		TextWrapped = Props.TextWrapped ~= false,
		TextXAlignment = Props.TextXAlignment or Enum.TextXAlignment.Center,
		TextYAlignment = Props.TextYAlignment or Enum.TextYAlignment.Center,
		Visible = Props.Visible ~= false,
		ZIndex = Props.ZIndex,
	}, Children)
end

function ReactUi.Panel(Props)
	local Children = Props.Children or Props.children

	return React.createElement("Frame", {
		AnchorPoint = Props.AnchorPoint,
		AutomaticSize = Props.AutomaticSize,
		BackgroundColor3 = Props.BackgroundColor3 or ReactUi.Colours.Panel,
		BackgroundTransparency = Props.BackgroundTransparency or 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = Props.ClipsDescendants == true,
		LayoutOrder = Props.LayoutOrder,
		Position = Props.Position,
		ref = Props.ref,
		Size = Props.Size,
		Visible = Props.Visible ~= false,
		ZIndex = Props.ZIndex,
	}, {
		UICorner = corner(Props.CornerRadius),
		UIStroke = stroke(Props.StrokeColor or ReactUi.Colours.Accent, Props.StrokeThickness or 2, Props.StrokeTransparency or 0.15),
		Padding = Props.Padding and React.createElement("UIPadding", {
			PaddingBottom = Props.Padding,
			PaddingLeft = Props.Padding,
			PaddingRight = Props.Padding,
			PaddingTop = Props.Padding,
		}) or nil,
		Children = Children and React.createElement(React.Fragment, nil, Children) or nil,
	})
end

function ReactUi.GetGameplayCanvasSize(GameplayPanels)
	local ReferenceResolution = GameplayPanels.ReferenceResolution
	local OuterSize = GameplayPanels.Outer.Size

	return Vector2.new(
		ReferenceResolution.X * OuterSize.X.Scale,
		ReferenceResolution.Y * OuterSize.Y.Scale
	)
end

function ReactUi.GameplayPanel(Props)
	local ViewportRef = React.useRef(nil)
	local DesignScale, SetDesignScale = React.useState(1)
	local ViewportSize, SetViewportSize = React.useState(Vector2.zero)
	local GameplayPanels = Props.GameplayPanels
	local ReferenceResolution = GameplayPanels.ReferenceResolution
	local Outer = GameplayPanels.Outer
	local CanvasSize = ReactUi.GetGameplayCanvasSize(GameplayPanels)
	local Children = Props.Children or Props.children
	local DebugGameplayPanel = GameplayPanels.DebugGameplayPanel == true
	local DebugText = string.format(
		"Viewport: %dx%d | Root: %.0fx%.0f | RootScale: %.3f | Panel: %.0fx%.0f | Canvas: %.0fx%.0f",
		ViewportSize.X,
		ViewportSize.Y,
		ReferenceResolution.X,
		ReferenceResolution.Y,
		DesignScale,
		CanvasSize.X,
		CanvasSize.Y,
		CanvasSize.X,
		CanvasSize.Y
	)

	React.useEffect(function()
		local Viewport = ViewportRef.current
		if not Viewport then return nil end

		local function updateDesignScale()
			local AbsoluteSize = Viewport.AbsoluteSize
			if AbsoluteSize.X <= 0 or AbsoluteSize.Y <= 0 then return end

			local NextScale = math.min(AbsoluteSize.X / ReferenceResolution.X, AbsoluteSize.Y / ReferenceResolution.Y)
			SetViewportSize(AbsoluteSize)
			SetDesignScale(NextScale)

			if DebugGameplayPanel then
				print(string.format(
					"GameplayPanel Debug | Viewport=%dx%d | Root=%.1fx%.1f | RootScale=%.3f | Panel=%.1fx%.1f | Canvas=%.1fx%.1f",
					AbsoluteSize.X,
					AbsoluteSize.Y,
					ReferenceResolution.X,
					ReferenceResolution.Y,
					NextScale,
					CanvasSize.X,
					CanvasSize.Y,
					CanvasSize.X,
					CanvasSize.Y
				))
			end
		end

		updateDesignScale()
		local Connection = Viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateDesignScale)

		return function()
			Connection:Disconnect()
		end
	end, { ReferenceResolution.X, ReferenceResolution.Y, CanvasSize.X, CanvasSize.Y })

	return React.createElement("Frame", {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ref = ViewportRef,
		Size = UDim2.fromScale(1, 1),
		Visible = Props.Visible,
		ZIndex = Props.ZIndex,
	}, {
		DesignRoot = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(ReferenceResolution.X, ReferenceResolution.Y),
			ZIndex = Props.ZIndex,
		}, {
			UIScale = React.createElement("UIScale", {
				Scale = DesignScale,
			}),
			Panel = React.createElement("Frame", {
				AnchorPoint = Outer.AnchorPoint,
				BackgroundColor3 = Outer.BackgroundColor3,
				BackgroundTransparency = Outer.BackgroundTransparency,
				ClipsDescendants = true,
				BorderSizePixel = 0,
				Position = Outer.Position,
				Size = Outer.Size,
				Visible = Props.Visible,
				ZIndex = Props.ZIndex,
			}, {
				UICorner = corner(Outer.CornerRadius),
				UIStroke = stroke(Props.StrokeColor, Outer.StrokeThickness, Outer.StrokeTransparency),
				Canvas = React.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					ClipsDescendants = false,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(CanvasSize.X, CanvasSize.Y),
					ZIndex = Props.ZIndex,
				}, {
					DebugStroke = DebugGameplayPanel and React.createElement("UIStroke", {
						Color = Color3.fromRGB(0, 255, 255),
						Thickness = 2,
						Transparency = 0,
					}) or nil,
					Children = Children and React.createElement(React.Fragment, nil, Children) or nil,
				}),
				DebugLabel = DebugGameplayPanel and React.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.25,
					FontFace = ReactUi.Font,
					Position = UDim2.fromOffset(8, 8),
					Size = UDim2.new(1, -16, 0, 34),
					Text = DebugText,
					TextColor3 = Color3.fromRGB(80, 255, 255),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = (Props.ZIndex or 1) + 50,
				}, {
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8),
					}),
				}) or nil,
				DebugStroke = DebugGameplayPanel and React.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 0, 255),
					Thickness = 3,
					Transparency = 0,
				}) or nil,
			}),
		}),
	})
end

function ReactUi.Button(Props)
	local Scale, SetScale = React.useState(1)
	local Disabled = Props.Disabled == true
	local Colour = Disabled and Color3.fromRGB(92, 97, 112) or (Props.BackgroundColor3 or ReactUi.Colours.Accent)

	return React.createElement("Frame", {
		AnchorPoint = Props.AnchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = Props.LayoutOrder,
		Position = Props.Position,
		Size = Props.Size or UDim2.fromOffset(180, 48),
		Visible = Props.Visible ~= false,
		ZIndex = Props.ZIndex,
	}, {
		UIScale = React.createElement("UIScale", {
			Scale = Scale,
		}),
		Button = React.createElement("TextButton", {
			AutoButtonColor = not Disabled,
			BackgroundColor3 = Colour,
			BackgroundTransparency = Props.BackgroundTransparency or 0,
			BorderSizePixel = 0,
			FontFace = ReactUi.Font,
			Size = UDim2.fromScale(1, 1),
			Text = Props.Text or "",
			TextColor3 = Props.TextColor3 or ReactUi.Colours.Text,
			TextScaled = true,
			TextStrokeTransparency = Props.TextStrokeTransparency or 0.45,
			TextWrapped = true,
			ZIndex = Props.ZIndex,

			[React.Event.Activated] = function()
				if Disabled or not Props.OnActivated then return end
				Props.OnActivated()
			end,
			[React.Event.MouseEnter] = function()
				if Disabled then return end
				SetScale(1.06)
			end,
			[React.Event.MouseLeave] = function()
				SetScale(1)
			end,
			[React.Event.MouseButton1Down] = function()
				if Disabled then return end
				SetScale(0.94)
			end,
			[React.Event.MouseButton1Up] = function()
				if Disabled then return end
				SetScale(1.06)
			end,
		}, {
			UICorner = corner(Props.CornerRadius),
			UIStroke = stroke(Props.StrokeColor or Color3.fromRGB(0, 0, 0), Props.StrokeThickness or 2, Props.StrokeTransparency or 0.2),
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = Props.MaxTextSize or 34,
			}),
		}),
	})
end

function ReactUi.Header(Props)
	return React.createElement("Frame", {
		BackgroundColor3 = Props.BackgroundColor3 or ReactUi.Colours.Accent,
		BorderSizePixel = 0,
		Position = Props.Position,
		Size = Props.Size or UDim2.new(1, 0, 0, 58),
		ZIndex = Props.ZIndex,
	}, {
		UICorner = corner(UDim.new(0, 8)),
		Title = React.createElement(ReactUi.Text, {
			AnchorPoint = Vector2.new(0, 0.5),
			MaxTextSize = Props.TitleMaxTextSize,
			Position = Props.TitlePosition or UDim2.fromScale(0.035, 0.5),
			Size = Props.TitleSize or UDim2.fromScale(0.65, 0.7),
			Text = Props.Title,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = Props.ZIndex,
		}),
		Close = Props.OnClose and React.createElement(ReactUi.Button, {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = ReactUi.Colours.Red,
			MaxTextSize = Props.CloseMaxTextSize or 28,
			OnActivated = Props.OnClose,
			Position = Props.ClosePosition or UDim2.fromScale(0.97, 0.5),
			Size = Props.CloseSize or UDim2.fromOffset(46, 40),
			Text = Props.CloseText or "X",
			ZIndex = Props.ZIndex,
		}) or nil,
	})
end

function ReactUi.EmptyState(Props)
	return React.createElement(ReactUi.Text, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.85, 0.24),
		Text = Props.Text,
		TextColor3 = ReactUi.Colours.Muted,
		TextStrokeTransparency = 0.8,
	})
end

return ReactUi

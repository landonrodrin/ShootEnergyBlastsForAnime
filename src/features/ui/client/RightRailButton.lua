local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local BUTTON_SIZE = UDim2.fromOffset(112, 112)
local ICON_SIZE = UDim2.fromOffset(86, 86)
local RIGHT_PADDING = 32
local ROW_SPACING = 112
local LABEL_STROKE = Color3.fromRGB(0, 0, 0)

local function hasIcon(Icon)
	return type(Icon) == "string" and Icon ~= ""
end

local function RightRailButton(Props)
	local Row = Props.Row or 1
	local Scale, SetScale = React.useState(0.01)
	local Icon = Props.Icon
	local HasIcon = hasIcon(Icon)

	React.useEffect(function()
		local Cancelled = false

		task.spawn(function()
			task.wait((Row - 1) * 0.06)
			if Cancelled then return end
			SetScale(0.82)

			task.wait(0.05)
			if Cancelled then return end
			SetScale(1.08)

			task.wait(0.08)
			if Cancelled then return end
			SetScale(1)
		end)

		return function()
			Cancelled = true
		end
	end, { Row })

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -RIGHT_PADDING, 0.5, (Row - 2) * ROW_SPACING),
		Size = Props.Size or BUTTON_SIZE,
		ZIndex = Props.ZIndex or 20,
	}, {
		UIScale = React.createElement("UIScale", {
			Scale = Scale,
		}),
		Button = React.createElement("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = ReactUi.Font,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = Props.ZIndex or 20,

			[React.Event.Activated] = function()
				if Props.OnActivated then
					Props.OnActivated()
				end
			end,
			[React.Event.MouseEnter] = function()
				SetScale(1.06)
			end,
			[React.Event.MouseLeave] = function()
				SetScale(1)
			end,
			[React.Event.MouseButton1Down] = function()
				SetScale(0.94)
			end,
			[React.Event.MouseButton1Up] = function()
				SetScale(1.06)
			end,
		}, {
			Icon = HasIcon and React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Image = Icon,
				Position = UDim2.fromScale(0.5, 0),
				ScaleType = Enum.ScaleType.Fit,
				Size = ICON_SIZE,
				ZIndex = Props.ZIndex or 20,
			}) or nil,
			Label = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0.5, HasIcon and 0 or 0.5),
				Position = HasIcon and UDim2.new(0.5, 0, 0, 86) or UDim2.fromScale(0.5, 0.5),
				Size = HasIcon and UDim2.new(1, 0, 0, 26) or UDim2.new(1, -10, 0.72, 0),
				Text = Props.Text,
				TextScaled = true,
				TextStrokeColor3 = LABEL_STROKE,
				TextStrokeTransparency = 0,
				ZIndex = Props.ZIndex or 20,
			}, {
				UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = Props.MaxTextSize or 26,
				}),
			}),
		}),
	})
end

return RightRailButton

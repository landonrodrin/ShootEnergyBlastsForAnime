local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local UiAssets = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiAssets"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local HUD_TEXT_STROKE = Color3.fromRGB(0, 0, 0)
local DATA_HUD = UiTuning.DataHud

local function hasIcon(Icon)
	return type(Icon) == "string" and Icon ~= ""
end

local function StatRow(Props)
	local Icon = Props.Icon
	local HasIcon = hasIcon(Icon)
	local HasAction = Props.OnIconActivated ~= nil
	local IconScale, SetIconScale = React.useState(1)
	local RowHeight = Props.RowHeight or DATA_HUD.RowHeight
	local IconSlotSize = Props.IconSlotSize or RowHeight
	local IconSize = Props.IconSize or DATA_HUD.IconSize

	local IconProps = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(IconSlotSize, IconSlotSize),
	}

	if HasAction then
		IconProps.AutoButtonColor = false
		IconProps.FontFace = ReactUi.Font
		IconProps.Text = ""

		IconProps[React.Event.Activated] = function()
			Props.OnIconActivated()
		end
		IconProps[React.Event.MouseEnter] = function()
			SetIconScale(1.06)
		end
		IconProps[React.Event.MouseLeave] = function()
			SetIconScale(1)
		end
		IconProps[React.Event.MouseButton1Down] = function()
			SetIconScale(0.94)
		end
		IconProps[React.Event.MouseButton1Up] = function()
			SetIconScale(1.06)
		end
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = Props.LayoutOrder,
		Size = UDim2.fromOffset(Props.RowWidth or DATA_HUD.RowWidth, RowHeight),
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, Props.RowPadding or 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		Icon = React.createElement(HasAction and "TextButton" or "Frame", IconProps, {
			UIScale = React.createElement("UIScale", {
				Scale = IconScale,
			}),
			Image = HasIcon and React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = Icon,
				Position = UDim2.fromScale(0.5, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(IconSize, IconSize),
			}) or nil,
			Fallback = not HasIcon and React.createElement(ReactUi.Text, {
				Size = UDim2.fromScale(1, 1),
				Text = Props.Fallback,
				TextScaled = true,
				TextStrokeColor3 = HUD_TEXT_STROKE,
				TextStrokeTransparency = 0.45,
			}, {
				UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = 26,
				}),
			}) or nil,
		}),
		Value = React.createElement(ReactUi.Text, {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(Props.TextWidth or DATA_HUD.TextWidth, RowHeight),
			Text = Props.Text,
			TextScaled = true,
			TextStrokeColor3 = HUD_TEXT_STROKE,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = Props.TextMaxSize or DATA_HUD.TextMaxSize,
			}),
		}),
	})
end

local function DataHudView(Props)
	Props = Props or {}

	return React.createElement("Frame", {
		AnchorPoint = Props.AnchorPoint or Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Position = Props.Position or UDim2.new(0, 24, 1, -28),
		Size = Props.Size or UDim2.fromOffset(Props.ContainerWidth or DATA_HUD.RowWidth, Props.ContainerHeight or (DATA_HUD.RowHeight * 3 + DATA_HUD.VerticalPadding * 2)),
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, Props.VerticalPadding or DATA_HUD.VerticalPadding),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Speed = React.createElement(StatRow, {
			Fallback = "SPD",
			Icon = UiAssets.Icons.Speed,
			IconSize = Props.IconSize,
			IconSlotSize = Props.IconSlotSize,
			LayoutOrder = 1,
			RowHeight = Props.RowHeight,
			RowPadding = Props.RowPadding,
			RowWidth = Props.RowWidth,
			Text = Format.Number(Props.Speed or 0),
			TextMaxSize = Props.TextMaxSize,
			TextWidth = Props.TextWidth,
		}),
		Money = React.createElement(StatRow, {
			Fallback = "$",
			Icon = UiAssets.Icons.Money,
			IconSize = Props.IconSize,
			IconSlotSize = Props.IconSlotSize,
			LayoutOrder = 2,
			RowHeight = Props.RowHeight,
			RowPadding = Props.RowPadding,
			RowWidth = Props.RowWidth,
			Text = string.format("$%s", Format.Number(Props.Money or 0)),
			TextMaxSize = Props.TextMaxSize,
			TextWidth = Props.TextWidth,
		}),
		FriendBonus = React.createElement(StatRow, {
			Fallback = "+",
			Icon = UiAssets.Icons.Invite,
			IconSize = Props.IconSize,
			IconSlotSize = Props.IconSlotSize,
			LayoutOrder = 3,
			OnIconActivated = Props.OnInvite,
			RowHeight = Props.RowHeight,
			RowPadding = Props.RowPadding,
			RowWidth = Props.RowWidth,
			Text = string.format("Friend Bonus: %s%%", Format.Number(Props.FriendBonusPercent or 0)),
			TextMaxSize = Props.TextMaxSize,
			TextWidth = Props.TextWidth,
		}),
	})
end

return DataHudView

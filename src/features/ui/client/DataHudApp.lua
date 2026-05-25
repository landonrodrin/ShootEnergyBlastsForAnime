local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local UiAssets = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiAssets"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
local Player = Players.LocalPlayer

local HUD_TEXT_STROKE = Color3.fromRGB(0, 0, 0)
local ROW_HEIGHT = 56
local ICON_SIZE = 52
local ICON_SLOT_SIZE = 56

local function useStat(Name, Default)
	local Value, SetValue = React.useState(StatsController.Get(Name) or Default)

	React.useEffect(function()
		local Connection = StatsController.Changed:Connect(function(ChangedName, NextValue)
			if ChangedName ~= Name then return end
			SetValue(NextValue)
		end)

		return function()
			Connection:Disconnect()
		end
	end, { Name })

	return Value
end

local function hasIcon(Icon)
	return type(Icon) == "string" and Icon ~= ""
end

local function StatRow(Props)
	local Icon = Props.Icon
	local HasIcon = hasIcon(Icon)
	local HasAction = Props.OnIconActivated ~= nil
	local IconScale, SetIconScale = React.useState(1)

	local IconProps = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(ICON_SLOT_SIZE, ICON_SLOT_SIZE),
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
		Size = UDim2.fromOffset(420, ROW_HEIGHT),
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
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
				Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
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
			Size = UDim2.fromOffset(340, ROW_HEIGHT),
			Text = Props.Text,
			TextScaled = true,
			TextStrokeColor3 = HUD_TEXT_STROKE,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = 42,
			}),
		}),
	})
end

local function DataHudApp()
	local Money = useStat("Money", 0)
	local Speed = useStat("Speed", 0)
	local FriendBonusPercent = useStat("FriendBonusPercent", 0)

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 1, -28),
		Size = UDim2.fromOffset(430, 176),
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Speed = React.createElement(StatRow, {
			Colour = ReactUi.Colours.Blue,
			Fallback = "SPD",
			Icon = UiAssets.Icons.Speed,
			LayoutOrder = 1,
			Text = Format.Number(Speed),
		}),
		Money = React.createElement(StatRow, {
			Colour = ReactUi.Colours.Green,
			Fallback = "$",
			Icon = UiAssets.Icons.Money,
			LayoutOrder = 2,
			Text = string.format("$%s", Format.Number(Money)),
		}),
		FriendBonus = React.createElement(StatRow, {
			Fallback = "+",
			Icon = UiAssets.Icons.Invite,
			LayoutOrder = 3,
			OnIconActivated = function()
				pcall(function()
					SocialService:PromptGameInvite(Player)
				end)
			end,
			Text = string.format("Friend Bonus: %s%%", Format.Number(FriendBonusPercent)),
		}),
	})
end

return DataHudApp

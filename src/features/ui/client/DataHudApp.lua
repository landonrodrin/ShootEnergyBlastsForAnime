local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
local Player = Players.LocalPlayer

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

local function StatLabel(Props)
	return React.createElement(ReactUi.Text, {
		LayoutOrder = Props.LayoutOrder,
		Size = UDim2.fromOffset(270, 34),
		Text = Props.Text,
		TextScaled = true,
		TextStrokeTransparency = 0.15,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local function InviteButton()
	local Scale, SetScale = React.useState(1)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(82, 38),
	}, {
		UIScale = React.createElement("UIScale", {
			Scale = Scale,
		}),
		Button = React.createElement("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(34, 38, 50),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			FontFace = ReactUi.Font,
			Size = UDim2.fromScale(1, 1),
			Text = "Invite",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextStrokeTransparency = 0.35,

			[React.Event.Activated] = function()
				pcall(function()
					SocialService:PromptGameInvite(Player)
				end)
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
			UICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			UIStroke = React.createElement("UIStroke", {
				Color = ReactUi.Colours.Green,
				Thickness = 2,
				Transparency = 0.15,
			}),
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = 22,
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
		Position = UDim2.new(0, 24, 1, -96),
		Size = UDim2.fromOffset(330, 128),
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Speed = React.createElement(StatLabel, {
			LayoutOrder = 1,
			Text = string.format("Speed: %s", Format.Number(Speed)),
		}),
		Money = React.createElement(StatLabel, {
			LayoutOrder = 2,
			Text = string.format("Money: $%s", Format.Number(Money)),
		}),
		FriendBonusRow = React.createElement("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			Size = UDim2.fromOffset(330, 42),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Invite = React.createElement(InviteButton),
			FriendBonus = React.createElement(ReactUi.Text, {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(220, 38),
				Text = string.format("Friend Bonus: %s%%", Format.Number(FriendBonusPercent)),
				TextScaled = true,
				TextStrokeTransparency = 0.18,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
	})
end

return DataHudApp

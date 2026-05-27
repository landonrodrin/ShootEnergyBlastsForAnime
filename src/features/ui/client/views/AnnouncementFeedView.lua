local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local ANNOUNCEMENTS = UiTuning.Announcements

local function AnnouncementFeedView(Props)
	Props = Props or {}
	local Messages = Props.Messages or {}
	local MessageWidth = Props.MessageWidth or ANNOUNCEMENTS.MessageWidth
	local MessageHeight = Props.MessageHeight or ANNOUNCEMENTS.MessageHeight

	local Children = {
		Layout = React.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, Props.MessagePadding or ANNOUNCEMENTS.MessagePadding),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
	}

	for Index, Message in ipairs(Messages) do
		local Id = Message.Id or Index
		Children[string.format("Message%d", Id)] = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Color3.fromRGB(18, 20, 28),
			LayoutOrder = Index,
			Size = UDim2.fromOffset(MessageWidth, MessageHeight),
			StrokeColor = Message.Colour or ReactUi.Colours.Accent,
			StrokeThickness = 2,
		}, {
			Text = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -34, 1, -16),
				Text = Message.Text or "",
				TextScaled = true,
				TextStrokeTransparency = 0.45,
			}, {
				UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = Props.MaxTextSize or ANNOUNCEMENTS.MaxTextSize,
				}),
			}),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Props.AnchorPoint or Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = Props.Position or UDim2.fromScale(0.5, 0.13),
		Size = Props.Size or UDim2.fromOffset(Props.ContainerWidth or 600, Props.ContainerHeight or 280),
	}, Children)
end

return AnnouncementFeedView

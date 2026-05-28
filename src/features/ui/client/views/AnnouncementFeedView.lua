local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local ANNOUNCEMENTS = UiTuning.Announcements

local function AnnouncementCard(Props)
	local TargetPosition = Props.TargetPosition
	local CardRef = React.useRef(nil)
	local TweenRef = React.useRef(nil)
	local RenderedPosition, SetRenderedPosition = React.useState(TargetPosition)

	React.useEffect(function()
		local Card = CardRef.current
		if not Card then
			SetRenderedPosition(TargetPosition)
			return nil
		end

		if TweenRef.current then
			TweenRef.current:Cancel()
			TweenRef.current = nil
		end

		local Tween = TweenService:Create(Card, Props.MoveTweenInfo, {
			Position = TargetPosition,
		})
		local CompletedConnection

		TweenRef.current = Tween
		CompletedConnection = Tween.Completed:Connect(function(PlaybackState)
			if PlaybackState ~= Enum.PlaybackState.Completed then
				return
			end

			if TweenRef.current == Tween then
				TweenRef.current = nil
			end
			SetRenderedPosition(TargetPosition)
		end)
		Tween:Play()

		return function()
			if CompletedConnection then
				CompletedConnection:Disconnect()
			end
			if TweenRef.current == Tween then
				TweenRef.current = nil
			end
			Tween:Cancel()
		end
	end, { TargetPosition })

	return React.createElement(ReactUi.Panel, {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(18, 20, 28),
		Position = RenderedPosition,
		Size = UDim2.fromOffset(Props.MessageWidth, Props.MessageHeight),
		StrokeColor = Props.Colour or ReactUi.Colours.Accent,
		StrokeThickness = 2,
		ZIndex = Props.ZIndex,

		Ref = CardRef,
	}, {
		Text = React.createElement(ReactUi.Text, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -34, 1, -16),
			Text = Props.Text or "",
			TextScaled = true,
			TextStrokeTransparency = 0.45,
			ZIndex = Props.ZIndex,
		}, {
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = Props.MaxTextSize,
			}),
		}),
	})
end

local function AnnouncementFeedView(Props)
	Props = Props or {}
	local Messages = Props.Messages or {}
	local MessageWidth = Props.MessageWidth or ANNOUNCEMENTS.MessageWidth
	local MessageHeight = Props.MessageHeight or ANNOUNCEMENTS.MessageHeight
	local MessagePadding = Props.MessagePadding or ANNOUNCEMENTS.MessagePadding
	local StackBottomY = Props.StackBottomY or ANNOUNCEMENTS.StackBottomY
	local StackCenterX = Props.StackCenterX or ANNOUNCEMENTS.StackCenterX
	local BaseZIndex = Props.ZIndex or ANNOUNCEMENTS.ZIndex
	local MoveTweenInfo = Props.MoveTweenInfo or ANNOUNCEMENTS.MoveTweenInfo

	local NewestStackOrder = 0
	for Index, Message in ipairs(Messages) do
		NewestStackOrder = math.max(NewestStackOrder, Message.StackOrder or Index)
	end

	local Children = {}

	for Index, Message in ipairs(Messages) do
		local Id = Message.Id or Index
		local StackOrder = Message.StackOrder or Index
		local StackOffset = NewestStackOrder - StackOrder

		Children[string.format("Message%d", Id)] = React.createElement(AnnouncementCard, {
			Colour = Message.Colour,
			MaxTextSize = Props.MaxTextSize or ANNOUNCEMENTS.MaxTextSize,
			MessageHeight = MessageHeight,
			MessageWidth = MessageWidth,
			MoveTweenInfo = MoveTweenInfo,
			TargetPosition = UDim2.new(StackCenterX, 0, 0, StackBottomY - StackOffset * (MessageHeight + MessagePadding)),
			Text = Message.Text,
			ZIndex = BaseZIndex + Index,
		})
	end

	return React.createElement(ReactUi.ReferenceScaledFrame, {
		FillScaledViewport = true,
		ReferenceResolution = Props.ReferenceResolution or ANNOUNCEMENTS.ReferenceResolution,
		ZIndex = BaseZIndex,
	}, Children)
end

return AnnouncementFeedView

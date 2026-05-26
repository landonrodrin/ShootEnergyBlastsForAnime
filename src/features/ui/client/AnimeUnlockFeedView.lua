local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))
local ViewportPreview = require(script.Parent:WaitForChild("ViewportPreview"))

local ANIME_UNLOCK = UiTuning.AnimeUnlock

local function mutationColour(Mutation)
	local Configuration = MutationsConfigurations[Mutation]
	return Configuration and Configuration.Colour or Color3.fromRGB(120, 180, 255)
end

local function AnimeUnlockFeedView(Props)
	Props = Props or {}
	local Unlocks = Props.Unlocks or {}
	local CardWidth = Props.CardWidth or ANIME_UNLOCK.CardWidth
	local CardHeight = Props.CardHeight or ANIME_UNLOCK.CardHeight
	local PreviewSize = Props.PreviewSize or ANIME_UNLOCK.PreviewSize

	local Children = {
		Layout = React.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, Props.CardPadding or 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for Index, Unlock in ipairs(Unlocks) do
		local Id = Unlock.Id or Index
		local Mutation = Unlock.Mutation or "Default"
		local Accent = mutationColour(Mutation)
		local Name = Unlock.Name or "Anime"

		Children[string.format("Unlock%d", Id)] = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Color3.fromRGB(18, 20, 28),
			LayoutOrder = Index,
			Size = UDim2.fromOffset(CardWidth, CardHeight),
			StrokeColor = Accent,
			StrokeThickness = 3,
		}, {
			Preview = React.createElement(ViewportPreview, {
				AnimeName = Name,
				BackgroundColor3 = Accent,
				BackgroundTransparency = 0.65,
				Mutation = Mutation,
				Position = UDim2.fromOffset(18, 14),
				Scale = Props.PreviewScale or ANIME_UNLOCK.PreviewScale,
				Size = UDim2.fromOffset(PreviewSize, PreviewSize),
				StrokeColor = Accent,
			}),
			Title = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.24, 0.5),
				Size = UDim2.fromScale(0.68, 0.7),
				Text = string.format("Unlocked %s!", Name),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Props.AnchorPoint or Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = Props.Position or UDim2.fromScale(0.5, 0.02),
		Size = Props.Size or UDim2.fromOffset(Props.ContainerWidth or 540, Props.ContainerHeight or 260),
	}, Children)
end

return AnimeUnlockFeedView

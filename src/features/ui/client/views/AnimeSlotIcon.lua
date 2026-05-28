local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local AnimeViewports = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeViewports"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local AREA_COLORS: { [string]: Color3 } = {
	Common = Color3.fromRGB(115, 115, 115),
	Uncommon = Color3.fromRGB(35, 165, 70),
	Rare = Color3.fromRGB(45, 105, 255),
	Epic = Color3.fromRGB(150, 70, 220),
	Legendary = Color3.fromRGB(255, 210, 45),
}

local DEFAULT_BACKGROUND_COLOR = Color3.fromRGB(25, 27, 29)
local DEFAULT_CORNER_RADIUS = UDim.new(0, 8)
local DEFAULT_BADGE_BACKGROUND = Color3.fromRGB(12, 14, 18)
local DEFAULT_TEXT_OUTLINE = Color3.fromRGB(0, 0, 0)

local function getAreaColor(AnimeName: string?): Color3
	local Configuration = AnimeName and AnimeConfigurations[AnimeName]
	local Area = Configuration and Configuration.Area

	if type(Area) ~= "string" then
		return DEFAULT_BACKGROUND_COLOR
	end

	return AREA_COLORS[Area] or DEFAULT_BACKGROUND_COLOR
end

local function getMutationColor(Mutation: string?): Color3?
	if not Mutation or Mutation == "Default" then
		return nil
	end

	local Configuration = MutationsConfigurations[Mutation]
	return Configuration and Configuration.Colour or nil
end

local function AnimeSlotIcon(Props)
	local Tuning = Props.Tuning or {}
	local PlaceholderRef = React.useRef(nil)
	local Mutation = Props.Mutation or "Default"
	local MutationColor = getMutationColor(Mutation)
	local ShowLevelBadge = Props.ShowLevelBadge == true and Props.Level ~= nil
	local ShowSlotNumber = Props.ShowSlotNumber == true and Props.SlotNumber ~= nil
	local BorderInset = Tuning.MutationBorderInset or 4

	React.useEffect(function()
		local Placeholder = PlaceholderRef.current
		if not Placeholder then return nil end

		local Viewport = AnimeViewports.Mount(Placeholder, Props.AnimeName, Mutation, {
			Scale = Props.Scale or Tuning.ViewportScale or 1.15,
			Silhouette = Props.Silhouette == true,
		})

		return function()
			if Viewport then
				Viewport:Destroy()
			end
		end
	end, { Props.AnimeName, Mutation, Props.Silhouette, Props.Scale })

	return React.createElement("Frame", {
		BackgroundColor3 = Props.BackgroundColor3 or getAreaColor(Props.AnimeName),
		BackgroundTransparency = if Props.BackgroundTransparency ~= nil
			then Props.BackgroundTransparency
			else (Tuning.BackgroundTransparency or 0.3),
		BorderSizePixel = 0,
		ClipsDescendants = Props.ClipsDescendants == true,
		LayoutOrder = Props.LayoutOrder,
		Position = Props.Position,
		Size = Props.Size or UDim2.fromOffset(80, 80),
		ref = PlaceholderRef,
		ZIndex = Props.ZIndex,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = Tuning.CornerRadius or DEFAULT_CORNER_RADIUS,
		}),
		MutationBorder = MutationColor and React.createElement("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(BorderInset, BorderInset),
			Size = UDim2.new(1, -BorderInset * 2, 1, -BorderInset * 2),
			ZIndex = (Props.ZIndex or 1) + 3,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = (Tuning.CornerRadius or DEFAULT_CORNER_RADIUS) - UDim.new(0, BorderInset),
			}),
			Stroke = React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = MutationColor,
				Thickness = Tuning.MutationBorderThickness or 4,
				Transparency = Tuning.MutationBorderTransparency or 0,
			}),
		}) or nil,
		LevelBadge = ShowLevelBadge and React.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Tuning.LevelBadgeBackgroundColor or DEFAULT_BADGE_BACKGROUND,
			BackgroundTransparency = if Tuning.LevelBadgeBackgroundTransparency ~= nil
				then Tuning.LevelBadgeBackgroundTransparency
				else 0.15,
			BorderSizePixel = 0,
			Position = Tuning.LevelBadgePosition or UDim2.new(1, -7, 0, 7),
			Size = Tuning.LevelBadgeSize or UDim2.fromOffset(46, 26),
			ZIndex = (Props.ZIndex or 1) + 4,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = Tuning.LevelBadgeCornerRadius or UDim.new(0, 6),
			}),
			Text = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = ReactUi.Font,
				Size = UDim2.fromScale(1, 1),
				Text = string.format("Lvl %s", tostring(Props.Level)),
				TextColor3 = Tuning.LevelBadgeTextColor or Color3.fromRGB(255, 255, 255),
				TextSize = Tuning.LevelBadgeTextSize or 16,
				TextStrokeColor3 = Tuning.TextOutlineColor or DEFAULT_TEXT_OUTLINE,
				TextStrokeTransparency = if Tuning.TextOutlineTransparency ~= nil
					then Tuning.TextOutlineTransparency
					else 0.5,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = (Props.ZIndex or 1) + 5,
			}),
		}) or nil,
		SlotNumber = ShowSlotNumber and React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = ReactUi.Font,
			Size = Tuning.SlotNumberSize or UDim2.fromScale(0.4, 0.4),
			Text = tostring(Props.SlotNumber),
			TextColor3 = Tuning.SlotNumberTextColor or Color3.fromRGB(255, 255, 255),
			TextSize = Tuning.SlotNumberTextSize or 16,
			TextStrokeColor3 = Tuning.TextOutlineColor or DEFAULT_TEXT_OUTLINE,
			TextStrokeTransparency = if Tuning.TextOutlineTransparency ~= nil
				then Tuning.TextOutlineTransparency
				else 0.5,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = (Props.ZIndex or 1) + 4,
		}) or nil,
	})
end

return AnimeSlotIcon

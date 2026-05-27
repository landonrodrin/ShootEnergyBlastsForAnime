local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local AnimeViewports = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeViewports"))

local function ViewportPreview(Props)
	local PlaceholderRef = React.useRef(nil)

	React.useEffect(function()
		local Placeholder = PlaceholderRef.current
		if not Placeholder then return nil end

		local Viewport = AnimeViewports.Mount(Placeholder, Props.AnimeName, Props.Mutation or "Default", {
			Scale = Props.Scale or 1.15,
			Silhouette = Props.Silhouette == true,
		})

		return function()
			if Viewport then
				Viewport:Destroy()
			end
		end
	end, { Props.AnimeName, Props.Mutation, Props.Silhouette })

	return React.createElement("Frame", {
		BackgroundColor3 = Props.BackgroundColor3 or Color3.fromRGB(30, 33, 44),
		BackgroundTransparency = Props.BackgroundTransparency or 0.05,
		BorderSizePixel = 0,
		LayoutOrder = Props.LayoutOrder,
		Position = Props.Position,
		Size = Props.Size or UDim2.fromOffset(80, 80),
		ref = PlaceholderRef,
		ZIndex = Props.ZIndex,
	}, {
		UICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		UIStroke = React.createElement("UIStroke", {
			Color = Props.StrokeColor or Color3.fromRGB(255, 190, 46),
			Thickness = 2,
			Transparency = 0.25,
		}),
	})
end

return ViewportPreview

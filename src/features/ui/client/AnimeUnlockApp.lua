local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))
local ViewportPreview = require(script.Parent:WaitForChild("ViewportPreview"))

local DISPLAY_TIME = 2.7

local function mutationColour(Mutation)
	local Configuration = MutationsConfigurations[Mutation]
	return Configuration and Configuration.Colour or Color3.fromRGB(120, 180, 255)
end

local function removeUnlock(Unlocks, Id)
	local Next = {}
	for _, Unlock in ipairs(Unlocks) do
		if Unlock.Id ~= Id then
			table.insert(Next, Unlock)
		end
	end
	return Next
end

local function AnimeUnlockApp()
	local Unlocks, SetUnlocks = React.useState({})
	local NextId = React.useRef(0)

	React.useEffect(function()
		local Connection = Packets.Listen(Packets.animeUnlocked, function(Data)
			NextId.current += 1
			local Id = NextId.current
			local Mutation = Data.Mutation or "Default"

			SetUnlocks(function(Previous)
				local Next = table.clone(Previous)
				table.insert(Next, {
					Id = Id,
					Mutation = Mutation,
					Name = tostring(Data.Name or "Anime"),
				})
				return Next
			end)

			task.delay(DISPLAY_TIME, function()
				SetUnlocks(function(Previous)
					return removeUnlock(Previous, Id)
				end)
			end)
		end)

		return function()
			Connection()
		end
	end, {})

	local Children = {
		Layout = React.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for Index, Unlock in ipairs(Unlocks) do
		local Accent = mutationColour(Unlock.Mutation)
		Children[string.format("Unlock%d", Unlock.Id)] = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Color3.fromRGB(18, 20, 28),
			LayoutOrder = Index,
			Size = UDim2.fromOffset(520, 116),
			StrokeColor = Accent,
			StrokeThickness = 3,
		}, {
			Preview = React.createElement(ViewportPreview, {
				AnimeName = Unlock.Name,
				BackgroundColor3 = Accent,
				BackgroundTransparency = 0.65,
				Mutation = Unlock.Mutation,
				Position = UDim2.fromOffset(18, 14),
				Scale = 1.3,
				Size = UDim2.fromOffset(88, 88),
				StrokeColor = Accent,
			}),
			Title = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.24, 0.5),
				Size = UDim2.fromScale(0.68, 0.7),
				Text = string.format("Unlocked %s!", Unlock.Name),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.02),
		Size = UDim2.fromOffset(540, 260),
	}, Children)
end

return AnimeUnlockApp

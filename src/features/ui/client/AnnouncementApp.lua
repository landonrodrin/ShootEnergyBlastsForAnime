local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))

local MESSAGE_LIFETIME = 2.25
local MAX_MESSAGES = 4

local function removeMessage(Messages, Id)
	local Next = {}
	for _, Message in ipairs(Messages) do
		if Message.Id ~= Id then
			table.insert(Next, Message)
		end
	end
	return Next
end

local function AnnouncementApp()
	local Messages, SetMessages = React.useState({})
	local NextId = React.useRef(0)

	React.useEffect(function()
		local Connection = Packets.Listen(Packets.announcement, function(Data)
			NextId.current += 1
			local Id = NextId.current

			SetMessages(function(Previous)
				local Next = table.clone(Previous)
				table.insert(Next, {
					Colour = Packets.DecodeColour(Data.Colour),
					Id = Id,
					Text = tostring(Data.Text or ""),
				})

				while #Next > MAX_MESSAGES do
					table.remove(Next, 1)
				end

				return Next
			end)

			task.delay(MESSAGE_LIFETIME, function()
				SetMessages(function(Previous)
					return removeMessage(Previous, Id)
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
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
	}

	for Index, Message in ipairs(Messages) do
		Children[string.format("Message%d", Message.Id)] = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Color3.fromRGB(18, 20, 28),
			LayoutOrder = Index,
			Size = UDim2.fromOffset(520, 46),
			StrokeColor = Message.Colour or ReactUi.Colours.Accent,
			StrokeThickness = 2,
		}, {
			Text = React.createElement(ReactUi.Text, {
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.92, 0.72),
				Text = Message.Text,
				TextScaled = true,
			}),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.13),
		Size = UDim2.fromOffset(560, 220),
	}, Children)
end

return AnnouncementApp

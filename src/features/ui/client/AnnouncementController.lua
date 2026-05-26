local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local AnnouncementFeedView = require(script.Parent:WaitForChild("AnnouncementFeedView"))

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

local function AnnouncementController()
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

	return React.createElement(AnnouncementFeedView, {
		Messages = Messages,
	})
end

return AnnouncementController

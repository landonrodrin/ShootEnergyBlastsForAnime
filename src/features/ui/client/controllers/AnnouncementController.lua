local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local AnnouncementFeedView = require(script.Parent.Parent.Views:WaitForChild("AnnouncementFeedView"))

local ANNOUNCEMENTS = UiTuning.Announcements

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
	local IsMounted = React.useRef(false)
	local IsProcessing = React.useRef(false)
	local Queue = React.useRef({})

	local function showMessage(Message)
		NextId.current += 1
		local Id = NextId.current

		SetMessages(function(Previous)
			local Next = table.clone(Previous)
			table.insert(Next, {
				Colour = Message.Colour,
				Id = Id,
				StackOrder = Id,
				Text = Message.Text,
			})

			while #Next > ANNOUNCEMENTS.MaxMessages do
				table.remove(Next, 1)
			end

			return Next
		end)

		task.delay(ANNOUNCEMENTS.MessageLifetime, function()
			if not IsMounted.current then
				return
			end

			SetMessages(function(Previous)
				return removeMessage(Previous, Id)
			end)
		end)
	end

	local function processQueue()
		if IsProcessing.current then
			return
		end

		IsProcessing.current = true
		task.spawn(function()
			while IsMounted.current and #Queue.current > 0 do
				local Message = table.remove(Queue.current, 1)
				showMessage(Message)

				if #Queue.current > 0 then
					task.wait(ANNOUNCEMENTS.SpawnDelay)
				end
			end

			IsProcessing.current = false
		end)
	end

	React.useEffect(function()
		IsMounted.current = true

		local Connection = Packets.Listen(Packets.announcement, function(Data)
			table.insert(Queue.current, {
				Colour = Packets.DecodeColour(Data.Colour),
				Text = tostring(Data.Text or ""),
			})
			processQueue()
		end)

		return function()
			IsMounted.current = false
			table.clear(Queue.current)
			Connection()
		end
	end, {})

	return React.createElement(AnnouncementFeedView, {
		Messages = Messages,
	})
end

return AnnouncementController

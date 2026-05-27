local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local AnimeUnlockFeedView = require(script.Parent.Parent.Views:WaitForChild("AnimeUnlockFeedView"))

local DISPLAY_TIME = 2.7

local function removeUnlock(Unlocks, Id)
	local Next = {}
	for _, Unlock in ipairs(Unlocks) do
		if Unlock.Id ~= Id then
			table.insert(Next, Unlock)
		end
	end
	return Next
end

local function AnimeUnlockController()
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

	return React.createElement(AnimeUnlockFeedView, {
		Unlocks = Unlocks,
	})
end

return AnimeUnlockController

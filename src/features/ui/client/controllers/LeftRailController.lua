local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local LeftRailView = require(script.Parent.Parent.Views:WaitForChild("LeftRailView"))

local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
local Player = Players.LocalPlayer

local function useStat(Name, Default)
	local Value, SetValue = React.useState(StatsController.Get(Name) or Default)

	React.useEffect(function()
		local Connection = StatsController.Changed:Connect(function(ChangedName, NextValue)
			if ChangedName ~= Name then return end
			SetValue(NextValue)
		end)

		return function()
			Connection:Disconnect()
		end
	end, { Name })

	return Value
end

local function LeftRailController()
	local Money = useStat("Money", 0)
	local Speed = useStat("Speed", 0)
	local FriendBonusPercent = useStat("FriendBonusPercent", 0)

	return React.createElement(LeftRailView, {
		FriendBonusPercent = FriendBonusPercent,
		Money = Money,
		OnInvite = function()
			pcall(function()
				SocialService:PromptGameInvite(Player)
			end)
		end,
		Speed = Speed,
	})
end

return LeftRailController

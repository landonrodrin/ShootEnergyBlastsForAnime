local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local AnnouncementFeedView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("AnnouncementFeedView"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))

local SUCCESS = Color3.fromRGB(95, 255, 140)
local WARNING = Color3.fromRGB(255, 210, 90)
local ERROR = Color3.fromRGB(255, 0, 0)
local ANNOUNCEMENTS = UiTuning.Announcements

local SCENARIOS = {
	InsufficientFunds = "Insufficient Funds",
	SellSingle = "Sold anime for $48K.",
	SellMany = "Sold 8 anime for $723.01K.",
	UpgradeWarning = "Reach 100 speed to rebirth.",
	SellWarning = "Stand by the sell shop to sell anime.",
	Stacked = "Stacked",
}

local function messageForScenario(Scenario)
	if Scenario == SCENARIOS.InsufficientFunds then
		return {
			Colour = ERROR,
			Text = "Insufficient Funds",
		}
	elseif Scenario == SCENARIOS.SellSingle then
		return {
			Colour = SUCCESS,
			Text = "Sold anime for $48K.",
		}
	elseif Scenario == SCENARIOS.SellMany then
		return {
			Colour = SUCCESS,
			Text = "Sold 8 anime for $723.01K.",
		}
	elseif Scenario == SCENARIOS.UpgradeWarning then
		return {
			Colour = WARNING,
			Text = "Reach 100 speed to rebirth.",
		}
	elseif Scenario == SCENARIOS.SellWarning then
		return {
			Colour = WARNING,
			Text = "Stand by the sell shop to sell anime.",
		}
	end

	return {
		Colour = WARNING,
		Text = "Inventory is still loading.",
	}
end

local function buildMessages(Scenario, Count)
	local Samples = {
		{
			Colour = ERROR,
			Text = "Insufficient Funds",
		},
		{
			Colour = SUCCESS,
			Text = "Sold 8 anime for $723.01K.",
		},
		{
			Colour = WARNING,
			Text = "Stand by the sell shop to sell anime.",
		},
		{
			Colour = WARNING,
			Text = "Reach 100 speed to rebirth.",
		},
	}

	if Scenario ~= SCENARIOS.Stacked then
		Samples = { messageForScenario(Scenario) }
	end

	local Messages = {}
	for Index = 1, math.max(1, Count) do
		local Sample = Samples[((Index - 1) % #Samples) + 1]
		table.insert(Messages, {
			Colour = Sample.Colour,
			Id = Index,
			Text = Sample.Text,
		})
	end
	return Messages
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Scenario = SCENARIOS.Stacked,
		Count = 4,
		MessageWidth = ANNOUNCEMENTS.MessageWidth,
		MessageHeight = ANNOUNCEMENTS.MessageHeight,
		MaxTextSize = ANNOUNCEMENTS.MaxTextSize,
		MessagePadding = ANNOUNCEMENTS.MessagePadding,
	},
	story = function(Props)
		local Controls = Props.controls

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			Announcements = React.createElement(AnnouncementFeedView, {
				MaxTextSize = Controls.MaxTextSize,
				MessageHeight = Controls.MessageHeight,
				MessagePadding = Controls.MessagePadding,
				MessageWidth = Controls.MessageWidth,
				Messages = buildMessages(Controls.Scenario, Controls.Count),
			}),
		})
	end,
}

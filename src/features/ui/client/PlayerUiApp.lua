local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))

local AnnouncementApp = require(script.Parent:WaitForChild("AnnouncementApp"))
local AnimeUnlockApp = require(script.Parent:WaitForChild("AnimeUnlockApp"))
local AreaApp = require(script.Parent:WaitForChild("AreaApp"))
local DataHudApp = require(script.Parent:WaitForChild("DataHudApp"))
local DropApp = require(script.Parent:WaitForChild("DropApp"))
local IndexApp = require(script.Parent:WaitForChild("IndexApp"))
local RebirthApp = require(ReplicatedStorage.Features.Shop.Client:WaitForChild("RebirthApp"))
local SellApp = require(ReplicatedStorage.Features.Shop.Client:WaitForChild("SellApp"))
local ShopApp = require(ReplicatedStorage.Features.Shop.Client:WaitForChild("ShopApp"))
local UpgradesApp = require(ReplicatedStorage.Features.Shop.Client:WaitForChild("UpgradesApp"))

local function PlayerUiApp()
	local ActivePanel, SetActivePanel = React.useState(nil)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Data = React.createElement(DataHudApp),
		Area = React.createElement(AreaApp),
		Shop = React.createElement(ShopApp, {
			ActivePanel = ActivePanel,
			SetActivePanel = SetActivePanel,
		}),
		Index = React.createElement(IndexApp, {
			ActivePanel = ActivePanel,
			SetActivePanel = SetActivePanel,
		}),
		Rebirth = React.createElement(RebirthApp, {
			ActivePanel = ActivePanel,
			SetActivePanel = SetActivePanel,
		}),
		Drop = React.createElement(DropApp),
		Sell = React.createElement(SellApp),
		Upgrades = React.createElement(UpgradesApp),
		Announcements = React.createElement(AnnouncementApp),
		Unlocks = React.createElement(AnimeUnlockApp),
	})
end

return PlayerUiApp

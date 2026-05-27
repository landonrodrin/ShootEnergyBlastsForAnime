local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))

local AnnouncementController = require(script.Parent:WaitForChild("AnnouncementController"))
local AnimeUnlockController = require(script.Parent:WaitForChild("AnimeUnlockController"))
local AreaController = require(script.Parent:WaitForChild("AreaController"))
local LeftRailController = require(script.Parent:WaitForChild("LeftRailController"))
local DropController = require(script.Parent:WaitForChild("DropController"))
local IndexController = require(script.Parent:WaitForChild("IndexController"))
local RebirthController = require(script.Parent:WaitForChild("RebirthController"))
local SellController = require(script.Parent:WaitForChild("SellController"))
local ShopController = require(script.Parent:WaitForChild("ShopController"))
local UpgradesController = require(script.Parent:WaitForChild("UpgradesController"))

local function PlayerUiController()
	local ActivePanel, SetActivePanel = React.useState(nil)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		LeftRail = React.createElement(LeftRailController),
		Area = React.createElement(AreaController),
		Shop = React.createElement(ShopController, {
			ActivePanel = ActivePanel,
			SetActivePanel = SetActivePanel,
		}),
		Index = React.createElement(IndexController, {
			ActivePanel = ActivePanel,
			SetActivePanel = SetActivePanel,
		}),
		Rebirth = React.createElement(RebirthController, {
			ActivePanel = ActivePanel,
			SetActivePanel = SetActivePanel,
		}),
		Drop = React.createElement(DropController),
		Sell = React.createElement(SellController, {
			ActivePanel = ActivePanel,
			SetActivePanel = SetActivePanel,
		}),
		Upgrades = React.createElement(UpgradesController, {
			ActivePanel = ActivePanel,
			SetActivePanel = SetActivePanel,
		}),
		Announcements = React.createElement(AnnouncementController),
		Unlocks = React.createElement(AnimeUnlockController),
	})
end

return PlayerUiController

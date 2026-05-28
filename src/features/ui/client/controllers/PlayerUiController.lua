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
local ReactUi = require(script.Parent.Parent.Views:WaitForChild("ReactUi"))
local RightRailView = require(script.Parent.Parent.Views:WaitForChild("RightRailView"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))

local HUD_RAILS = UiTuning.HudRails

local function PlayerUiController()
	local ActivePanel, SetActivePanel = React.useState(nil)

	local function togglePanel(PanelName)
		SetActivePanel(if ActivePanel == PanelName then nil else PanelName)
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Rails = React.createElement(ReactUi.ReferenceScaledFrame, {
			DebugEnabled = HUD_RAILS.DebugHudRails == true,
			DebugName = "HudRails",
			FillScaledViewport = true,
			ReferenceResolution = HUD_RAILS.ReferenceResolution,
			ZIndex = 20,
		}, {
			LeftRail = React.createElement(LeftRailController),
			RightRail = React.createElement(RightRailView, {
				OnShopActivated = function()
					togglePanel("Shop")
				end,
				OnIndexActivated = function()
					togglePanel("Index")
				end,
				OnRebirthActivated = function()
					togglePanel("Rebirth")
				end,
				ZIndex = 20,
			}),
		}),
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

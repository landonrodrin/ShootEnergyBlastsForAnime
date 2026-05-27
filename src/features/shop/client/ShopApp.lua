local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ReactUi"))
local UiAssets = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiAssets"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local RightRailButton = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("RightRailButton"))
local ShopPanelView = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ShopPanelView"))

local GAMEPLAY_PANELS = UiTuning.GameplayPanels

local function ShopApp(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local Open = if Props.SetActivePanel then Props.ActivePanel == "Shop" else LocalOpen

	local function setOpen(NextOpen)
		if Props.SetActivePanel then
			Props.SetActivePanel(if NextOpen then "Shop" else nil)
		else
			SetLocalOpen(NextOpen)
		end
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Button = React.createElement(RightRailButton, {
			BackgroundColor3 = ReactUi.Colours.Accent,
			Icon = UiAssets.Icons.Shop,
			OnActivated = function()
				setOpen(not Open)
			end,
			Row = 1,
			Text = "Shop",
		}),
		Panel = React.createElement(ShopPanelView, {
			OnClose = function()
				setOpen(false)
			end,
			SharedTuning = GAMEPLAY_PANELS,
			Tuning = GAMEPLAY_PANELS.Shop,
			Visible = Open,
		}),
	})
end

return ShopApp

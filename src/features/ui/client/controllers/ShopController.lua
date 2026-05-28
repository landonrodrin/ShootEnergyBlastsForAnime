local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local ShopPanelView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("ShopPanelView"))

local GAMEPLAY_PANELS = UiTuning.GameplayPanels

local function ShopController(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local ActivePanelRef = React.useRef(Props.ActivePanel)
	local Open = if Props.SetActivePanel then Props.ActivePanel == "Shop" else LocalOpen

	React.useEffect(function()
		ActivePanelRef.current = Props.ActivePanel

		return nil
	end, { Props.ActivePanel })

	local function closeIfActive()
		if Props.SetActivePanel then
			if ActivePanelRef.current == "Shop" then
				Props.SetActivePanel(nil)
			end
		else
			SetLocalOpen(false)
		end
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Panel = React.createElement(ShopPanelView, {
			OnClose = function()
				closeIfActive()
			end,
			SharedTuning = GAMEPLAY_PANELS,
			SkipCloseTween = Props.SkipCloseTween,
			Tuning = GAMEPLAY_PANELS.Shop,
			Visible = Open,
		}),
	})
end

return ShopController

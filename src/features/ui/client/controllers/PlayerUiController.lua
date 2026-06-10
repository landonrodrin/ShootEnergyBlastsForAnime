local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Satchel = require(ReplicatedStorage:WaitForChild("Vendor"):WaitForChild("Satchel"))

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

local DEBUG_SELL_ZONE = false
local HUD_RAILS = UiTuning.HudRails

local function PlayerUiController()
	local ActivePanel, SetActivePanel = React.useState(nil)
	local ActivePanelRef = React.useRef(ActivePanel)
	local IgnoreInventoryCloseRef = React.useRef(false)

	React.useEffect(function()
		ActivePanelRef.current = ActivePanel

		return nil
	end, { ActivePanel })

	React.useEffect(function()
		local StateChanged = Satchel:GetStateChangedEvent()
		local Connection = StateChanged.Event:Connect(function(IsOpen)
			if IsOpen then
				ActivePanelRef.current = "Inventory"
				SetActivePanel("Inventory")
			elseif not IgnoreInventoryCloseRef.current and ActivePanelRef.current == "Inventory" then
				ActivePanelRef.current = nil
				SetActivePanel(nil)
			end
		end)

		return function()
			Connection:Disconnect()
		end
	end, {})

	local setActivePanel = React.useCallback(function(NextPanel)
		if ActivePanelRef.current == NextPanel then
			return
		end

		if NextPanel ~= nil and NextPanel ~= "Inventory" then
			if Satchel:IsOpened() then
				IgnoreInventoryCloseRef.current = true
				Satchel:Close({
					SkipTween = true,
				})
				IgnoreInventoryCloseRef.current = false
			end
		end

		if DEBUG_SELL_ZONE and (ActivePanelRef.current == "Sell" or NextPanel == "Sell") then
			print("[PlayerUiController] SetActivePanel", ActivePanelRef.current, "->", NextPanel)
		end

		ActivePanelRef.current = NextPanel
		SetActivePanel(NextPanel)
	end, {})

	local function togglePanel(PanelName)
		setActivePanel(if ActivePanelRef.current == PanelName then nil else PanelName)
	end

	local function shouldSkipClose(PanelName)
		return ActivePanel ~= nil and ActivePanel ~= PanelName
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
			SetActivePanel = setActivePanel,
			SkipCloseTween = shouldSkipClose("Shop"),
		}),
		Index = React.createElement(IndexController, {
			ActivePanel = ActivePanel,
			SetActivePanel = setActivePanel,
			SkipCloseTween = shouldSkipClose("Index"),
		}),
		Rebirth = React.createElement(RebirthController, {
			ActivePanel = ActivePanel,
			SetActivePanel = setActivePanel,
			SkipCloseTween = shouldSkipClose("Rebirth"),
		}),
		Drop = React.createElement(DropController),
		Sell = React.createElement(SellController, {
			ActivePanel = ActivePanel,
			SetActivePanel = setActivePanel,
			SkipCloseTween = shouldSkipClose("Sell"),
		}),
		Upgrades = React.createElement(UpgradesController, {
			ActivePanel = ActivePanel,
			SetActivePanel = setActivePanel,
			SkipCloseTween = shouldSkipClose("Upgrades"),
		}),
		Unlocks = React.createElement(AnimeUnlockController),
	})
end

return PlayerUiController

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("RebirthsConfigurations"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local RebirthPanelView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("RebirthPanelView"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
local Player = Players.LocalPlayer
local GAMEPLAY_PANELS = UiTuning.GameplayPanels

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

local function RebirthController(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local Rebirths = useStat("Rebirths", 0)
	local Speed = useStat("Speed", GameConfigurations.Defaults.Speed)
	local CurrentConfiguration = RebirthsConfigurations[Rebirths]
	local NextConfiguration = RebirthsConfigurations[Rebirths + 1]
	local CurrentMultiplier = CurrentConfiguration and CurrentConfiguration.Multiplier or 1
	local Progress = NextConfiguration and math.clamp(Speed / NextConfiguration.Speed, 0, 1) or 1
	local ActivePanelRef = React.useRef(Props.ActivePanel)
	local Open = if Props.SetActivePanel then Props.ActivePanel == "Rebirth" else LocalOpen

	React.useEffect(function()
		ActivePanelRef.current = Props.ActivePanel

		return nil
	end, { Props.ActivePanel })

	local function closeIfActive()
		if Props.SetActivePanel then
			if ActivePanelRef.current == "Rebirth" then
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
		Panel = React.createElement(RebirthPanelView, {
			CanRebirth = NextConfiguration ~= nil,
			CurrentText = string.format("Current: Rebirth %s | %sx Money", Rebirths, CurrentMultiplier),
			NextText = NextConfiguration and string.format("Next: Rebirth %s | %sx Money", Rebirths + 1, NextConfiguration.Multiplier) or "Max rebirth reached",
			OnClose = function()
				closeIfActive()
			end,
			OnRebirth = function()
				RequestController.Rebirth()
			end,
			OnSkip = function()
				MarketplaceService:PromptProductPurchase(Player, GameConfigurations.ProductsIds.SkipRebirth)
			end,
			Progress = Progress,
			ProgressText = NextConfiguration and string.format("Speed %s / %s", Format.Number(Speed), Format.Number(NextConfiguration.Speed)) or "MAX",
			SharedTuning = GAMEPLAY_PANELS,
			SkipCloseTween = Props.SkipCloseTween,
			Tuning = GAMEPLAY_PANELS.Rebirth,
			Visible = Open,
		}),
	})
end

return RebirthController

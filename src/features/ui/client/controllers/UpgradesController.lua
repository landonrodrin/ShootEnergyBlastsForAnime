local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local StationZones = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("StationZones"))
local UpgradesConfigurations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UpgradesConfigurations"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("ReactUi"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local ShopZonePanel = require(script.Parent:WaitForChild("ShopZonePanel"))
local UpgradesPanelView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("UpgradesPanelView"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
local Player = Players.LocalPlayer
local GAMEPLAY_PANELS = UiTuning.GameplayPanels
local ROBUX_PENDING_TEXT = "\u{E002} --"

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

local function getProductPriceText(ProductId)
	if not ProductId then
		return ROBUX_PENDING_TEXT
	end

	local Success, ProductInfo = pcall(function()
		return MarketplaceService:GetProductInfoAsync(ProductId, Enum.InfoType.Product)
	end)

	if not Success or typeof(ProductInfo) ~= "table" then
		return ROBUX_PENDING_TEXT
	end

	return string.format("\u{E002} %s", Format.Number(ProductInfo.PriceInRobux or 0))
end

local function getCachedPriceText(PriceTexts, Name)
	local Text = PriceTexts[Name]
	if Text then
		return Text
	end

	return ROBUX_PENDING_TEXT
end

local function buildUpgradeRow(Options)
	local Maxed = Options.NextValue > Options.Maximum

	if Maxed then
		return {
			Colour = Options.Colour,
			Disabled = true,
			Id = Options.Id,
			MoneyText = "MAX",
			OnMoney = Options.OnMoney,
			OnRobux = Options.OnRobux,
			RobuxText = "MAX",
			Title = Options.Title,
			ValueText = "MAX",
		}
	end

	return {
		Colour = Options.Colour,
		Disabled = false,
		Id = Options.Id,
		MoneyText = string.format("$%s", Format.Number(Options.MoneyCost)),
		OnMoney = Options.OnMoney,
		OnRobux = Options.OnRobux,
		RobuxText = Options.RobuxText,
		Title = Options.Title,
		ValueText = string.format("%s -> %s", Format.Number(Options.CurrentValue), Format.Number(Options.NextValue)),
	}
end

local function UpgradesController(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local Speed = useStat("Speed", GameConfigurations.Defaults.Speed)
	local Carry = useStat("Carry", GameConfigurations.Defaults.Carry)
	local PriceTexts, SetPriceTexts = React.useState({})
	local ZonePanel = ShopZonePanel.UsePanelZone({
		ActivePanel = Props.ActivePanel,
		GetZoneContainer = StationZones.GetUpgradeZoneContainer,
		LocalOpen = LocalOpen,
		PanelName = "Upgrades",
		SetActivePanel = Props.SetActivePanel,
		SetLocalOpen = SetLocalOpen,
		WarnMissingZone = StationZones.WarnMissingUpgradeZone,
	})
	local Open = ZonePanel.Open

	React.useEffect(function()
		local Alive = true

		task.spawn(function()
			local NextTexts = {}
			for Name, Configuration in pairs(UpgradesConfigurations) do
				NextTexts[Name] = getProductPriceText(Configuration.ProductId)
			end

			if Alive then
				SetPriceTexts(NextTexts)
			end
		end)

		return function()
			Alive = false
		end
	end, {})

	local Speed1Cost = math.round(UpgradesConfigurations.Speed1.Money * UpgradesConfigurations.Speed1.IncrementMultiplier ^ Speed)
	local Speed5Cost = math.round(UpgradesConfigurations.Speed1.Money * UpgradesConfigurations.Speed1.IncrementMultiplier ^ (Speed + 4))
	local Speed10Cost = math.round(UpgradesConfigurations.Speed1.Money * UpgradesConfigurations.Speed1.IncrementMultiplier ^ (Speed + 9))
	local CarryCost = math.round(UpgradesConfigurations.Carry1.Money * UpgradesConfigurations.Carry1.IncrementMultiplier ^ Carry)
	local Rows = {
		buildUpgradeRow({
			Colour = ReactUi.Colours.Blue,
			CurrentValue = Speed,
			Id = "Speed1",
			Maximum = GameConfigurations.Maximums.Speed,
			MoneyCost = Speed1Cost,
			NextValue = Speed + 1,
			OnMoney = function()
				RequestController.IncrementSpeed(1)
			end,
			OnRobux = function()
				MarketplaceService:PromptProductPurchase(Player, UpgradesConfigurations.Speed1.ProductId)
			end,
			RobuxText = getCachedPriceText(PriceTexts, "Speed1"),
			Title = "Speed +1",
		}),
		buildUpgradeRow({
			Colour = ReactUi.Colours.Blue,
			CurrentValue = Speed,
			Id = "Speed5",
			Maximum = GameConfigurations.Maximums.Speed,
			MoneyCost = Speed5Cost,
			NextValue = Speed + 5,
			OnMoney = function()
				RequestController.IncrementSpeed(5)
			end,
			OnRobux = function()
				MarketplaceService:PromptProductPurchase(Player, UpgradesConfigurations.Speed5.ProductId)
			end,
			RobuxText = getCachedPriceText(PriceTexts, "Speed5"),
			Title = "Speed +5",
		}),
		buildUpgradeRow({
			Colour = ReactUi.Colours.Blue,
			CurrentValue = Speed,
			Id = "Speed10",
			Maximum = GameConfigurations.Maximums.Speed,
			MoneyCost = Speed10Cost,
			NextValue = Speed + 10,
			OnMoney = function()
				RequestController.IncrementSpeed(10)
			end,
			OnRobux = function()
				MarketplaceService:PromptProductPurchase(Player, UpgradesConfigurations.Speed10.ProductId)
			end,
			RobuxText = getCachedPriceText(PriceTexts, "Speed10"),
			Title = "Speed +10",
		}),
		buildUpgradeRow({
			Colour = ReactUi.Colours.Green,
			CurrentValue = Carry,
			Id = "Carry1",
			Maximum = GameConfigurations.Maximums.Carry,
			MoneyCost = CarryCost,
			NextValue = Carry + 1,
			OnMoney = function()
				RequestController.IncrementCarry(1)
			end,
			OnRobux = function()
				MarketplaceService:PromptProductPurchase(Player, UpgradesConfigurations.Carry1.ProductId)
			end,
			RobuxText = getCachedPriceText(PriceTexts, "Carry1"),
			Title = "Carry +1",
		}),
	}

	return React.createElement(UpgradesPanelView, {
		OnClose = function()
			ZonePanel.CloseManually()
		end,
		Rows = Rows,
		SharedTuning = GAMEPLAY_PANELS,
		SkipCloseTween = Props.SkipCloseTween,
		Tuning = GAMEPLAY_PANELS.Upgrades,
		Visible = Open,
	})
end

return UpgradesController

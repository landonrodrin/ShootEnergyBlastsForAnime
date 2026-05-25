local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ZonePlus = require(ReplicatedStorage.Shared.Packages:WaitForChild("ZonePlus"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local UpgradesConfigurations = require(ReplicatedStorage.Features.Shop.Shared:WaitForChild("UpgradesConfigurations"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ReactUi"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
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

local function getProductPriceText(ProductId)
	if not ProductId then
		return "\u{E002} --"
	end

	local Success, ProductInfo = pcall(function()
		return MarketplaceService:GetProductInfoAsync(ProductId, Enum.InfoType.Product)
	end)

	if not Success or typeof(ProductInfo) ~= "table" then
		return "\u{E002} --"
	end

	return string.format("\u{E002} %s", Format.Number(ProductInfo.PriceInRobux or 0))
end

local function UpgradeRow(Props)
	local Maxed = Props.NextValue > Props.Maximum

	return React.createElement(ReactUi.Panel, {
		BackgroundColor3 = Color3.fromRGB(26, 29, 38),
		LayoutOrder = Props.LayoutOrder,
		Size = UDim2.new(1, -8, 0, 96),
		StrokeColor = Props.Colour,
	}, {
		Title = React.createElement(ReactUi.Text, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(18, 30),
			Size = UDim2.new(0.34, 0, 0, 32),
			Text = Props.Title,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Value = React.createElement(ReactUi.Text, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(18, 64),
			Size = UDim2.new(0.34, 0, 0, 26),
			Text = Maxed and "MAX" or string.format("%s -> %s", Format.Number(Props.CurrentValue), Format.Number(Props.NextValue)),
			TextColor3 = ReactUi.Colours.Muted,
			TextScaled = true,
			TextStrokeTransparency = 0.8,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Money = React.createElement(ReactUi.Button, {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = ReactUi.Colours.Green,
			Disabled = Maxed,
			MaxTextSize = 22,
			OnActivated = Props.OnMoney,
			Position = UDim2.new(1, -180, 0.5, 0),
			Size = UDim2.fromOffset(142, 44),
			Text = Maxed and "MAX" or string.format("$%s", Format.Number(Props.MoneyCost)),
		}),
		Robux = React.createElement(ReactUi.Button, {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = ReactUi.Colours.Accent,
			Disabled = Maxed,
			MaxTextSize = 22,
			OnActivated = Props.OnRobux,
			Position = UDim2.new(1, -24, 0.5, 0),
			Size = UDim2.fromOffset(142, 44),
			Text = Maxed and "MAX" or Props.RobuxText,
		}),
	})
end

local function UpgradesApp()
	local Open, SetOpen = React.useState(false)
	local Speed = useStat("Speed", GameConfigurations.Defaults.Speed)
	local Carry = useStat("Carry", GameConfigurations.Defaults.Carry)
	local PriceTexts, SetPriceTexts = React.useState({})

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

	React.useEffect(function()
		local Upgrades = workspace:WaitForChild("Upgrades", 10)
		local Toggle = Upgrades and Upgrades:WaitForChild("Toggle", 10)
		local UpgradesZone = nil
		local EnteredConnection = nil
		local ExitedConnection = nil

		if Toggle then
			UpgradesZone = ZonePlus.CreatePresenceZone(Toggle)
			EnteredConnection = UpgradesZone.localPlayerEntered:Connect(function()
				SetOpen(true)
			end)
			ExitedConnection = UpgradesZone.localPlayerExited:Connect(function()
				SetOpen(false)
			end)

			if UpgradesZone:findLocalPlayer() then
				SetOpen(true)
			end
		else
			warn("Missing upgrades zone: Workspace.Upgrades.Toggle")
		end

		return function()
			if EnteredConnection then
				EnteredConnection:Disconnect()
			end
			if ExitedConnection then
				ExitedConnection:Disconnect()
			end
			if UpgradesZone then
				UpgradesZone:destroy()
			end
		end
	end, {})

	local Speed1Cost = math.round(UpgradesConfigurations.Speed1.Money * UpgradesConfigurations.Speed1.IncrementMultiplier ^ Speed)
	local Speed5Cost = math.round(UpgradesConfigurations.Speed1.Money * UpgradesConfigurations.Speed1.IncrementMultiplier ^ (Speed + 4))
	local Speed10Cost = math.round(UpgradesConfigurations.Speed1.Money * UpgradesConfigurations.Speed1.IncrementMultiplier ^ (Speed + 9))
	local CarryCost = math.round(UpgradesConfigurations.Carry1.Money * UpgradesConfigurations.Carry1.IncrementMultiplier ^ Carry)

	return React.createElement(ReactUi.Panel, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromScale(0.58, 0.64),
		StrokeColor = ReactUi.Colours.Accent,
		StrokeThickness = 3,
		Visible = Open,
	}, {
		Header = React.createElement(ReactUi.Header, {
			OnClose = function()
				SetOpen(false)
			end,
			Title = "Upgrades",
		}),
		List = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 76),
			Size = UDim2.new(1, -36, 1, -94),
		}, {
			Layout = React.createElement("UIListLayout", {
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Speed1 = React.createElement(UpgradeRow, {
				Colour = ReactUi.Colours.Blue,
				CurrentValue = Speed,
				LayoutOrder = 1,
				Maximum = GameConfigurations.Maximums.Speed,
				MoneyCost = Speed1Cost,
				NextValue = Speed + 1,
				OnMoney = function()
					RequestController.IncrementSpeed(1)
				end,
				OnRobux = function()
					MarketplaceService:PromptProductPurchase(Player, UpgradesConfigurations.Speed1.ProductId)
				end,
				RobuxText = PriceTexts.Speed1 or "\u{E002} --",
				Title = "Speed +1",
			}),
			Speed5 = React.createElement(UpgradeRow, {
				Colour = ReactUi.Colours.Blue,
				CurrentValue = Speed,
				LayoutOrder = 2,
				Maximum = GameConfigurations.Maximums.Speed,
				MoneyCost = Speed5Cost,
				NextValue = Speed + 5,
				OnMoney = function()
					RequestController.IncrementSpeed(5)
				end,
				OnRobux = function()
					MarketplaceService:PromptProductPurchase(Player, UpgradesConfigurations.Speed5.ProductId)
				end,
				RobuxText = PriceTexts.Speed5 or "\u{E002} --",
				Title = "Speed +5",
			}),
			Speed10 = React.createElement(UpgradeRow, {
				Colour = ReactUi.Colours.Blue,
				CurrentValue = Speed,
				LayoutOrder = 3,
				Maximum = GameConfigurations.Maximums.Speed,
				MoneyCost = Speed10Cost,
				NextValue = Speed + 10,
				OnMoney = function()
					RequestController.IncrementSpeed(10)
				end,
				OnRobux = function()
					MarketplaceService:PromptProductPurchase(Player, UpgradesConfigurations.Speed10.ProductId)
				end,
				RobuxText = PriceTexts.Speed10 or "\u{E002} --",
				Title = "Speed +10",
			}),
			Carry1 = React.createElement(UpgradeRow, {
				Colour = ReactUi.Colours.Green,
				CurrentValue = Carry,
				LayoutOrder = 4,
				Maximum = GameConfigurations.Maximums.Carry,
				MoneyCost = CarryCost,
				NextValue = Carry + 1,
				OnMoney = function()
					RequestController.IncrementCarry(1)
				end,
				OnRobux = function()
					MarketplaceService:PromptProductPurchase(Player, UpgradesConfigurations.Carry1.ProductId)
				end,
				RobuxText = PriceTexts.Carry1 or "\u{E002} --",
				Title = "Carry +1",
			}),
		}),
	})
end

return UpgradesApp

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local ZonePlus = require(ReplicatedStorage.Shared.Packages:WaitForChild("ZonePlus"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local Animations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("Animations"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local UpgradesConfigurations = require(ReplicatedStorage.Features.Shop.Shared:WaitForChild("UpgradesConfigurations"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
RequestController.Start()
StatsController.Start()

local Player = Players.LocalPlayer
local Upgrades = workspace:WaitForChild("Upgrades")
local UpgradesGui = script.Parent
local UpgradesFrame = UpgradesGui:WaitForChild("UpgradesFrame")
local DataGui = UpgradesGui.Parent:WaitForChild("DataGui")
local DataFrame = DataGui:WaitForChild("DataFrame")
local ScriptTrove = Trove.new()
local WarnedProductInfo = {}

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

ScriptTrove:Connect(UpgradesFrame.Header.Close.Activated, function()
	Animations.ToggleFrame(UpgradesFrame)
end)

ScriptTrove:Connect(DataFrame.Upgrades.Activated, function()
	Animations.ToggleFrame(UpgradesFrame)
end)

local Toggle = Upgrades:WaitForChild("Toggle")

local function getRobuxPriceText(ProductId)
	if not ProductId then
		return "\u{E002} --"
	end

	local Success, ProductInfo = pcall(function()
		return MarketplaceService:GetProductInfo(ProductId, Enum.InfoType.Product)
	end)

	if not Success and MarketplaceService.GetProductInfoAsync then
		Success, ProductInfo = pcall(function()
			return MarketplaceService:GetProductInfoAsync(ProductId, Enum.InfoType.Product)
		end)
	end

	if not Success or typeof(ProductInfo) ~= "table" then
		if not WarnedProductInfo[ProductId] then
			WarnedProductInfo[ProductId] = true
			warn(string.format("%s could not fetch product info for %s: %s", script:GetFullName(), tostring(ProductId), tostring(ProductInfo)))
		end

		return "\u{E002} --"
	end

	return string.format("\u{E002} %s", Format.Number(ProductInfo.PriceInRobux or 0))
end

local UpgradesZone = ZonePlus.CreatePresenceZone(Toggle)
ScriptTrove:Add(UpgradesZone, "destroy")

ZonePlus.ConnectSignal(ScriptTrove, UpgradesZone.localPlayerEntered, function()
	if UpgradesFrame.Visible then return end

	Animations.ToggleFrame(UpgradesFrame)
end)

ZonePlus.ConnectSignal(ScriptTrove, UpgradesZone.localPlayerExited, function()
	if not UpgradesFrame.Visible then return end

	Animations.ToggleFrame(UpgradesFrame)
end)

if UpgradesZone:findLocalPlayer() and not UpgradesFrame.Visible then
	Animations.ToggleFrame(UpgradesFrame)
end

local function RefreshSpeed(Speed)
	Speed = tonumber(Speed) or 0

	UpgradesFrame.Speed1.Speed.Text = Speed
	UpgradesFrame.Speed1.Speed1.Text = Speed + 1
	UpgradesFrame.Speed1.Money.Text = Format.Number(math.round(UpgradesConfigurations["Speed1"].Money * UpgradesConfigurations["Speed1"].IncrementMultiplier ^ Speed))
	UpgradesFrame.Speed1.Robux.Text = getRobuxPriceText(UpgradesConfigurations["Speed1"].ProductId)

	UpgradesFrame.Speed5.Speed.Text = Speed
	UpgradesFrame.Speed5.Speed5.Text = Speed + 5
	UpgradesFrame.Speed5.Money.Text = Format.Number(math.round(UpgradesConfigurations["Speed1"].Money * UpgradesConfigurations["Speed1"].IncrementMultiplier ^ (Speed + 4)))
	UpgradesFrame.Speed5.Robux.Text = getRobuxPriceText(UpgradesConfigurations["Speed5"].ProductId)

	UpgradesFrame.Speed10.Speed.Text = Speed
	UpgradesFrame.Speed10.Speed10.Text = Speed + 10
	UpgradesFrame.Speed10.Money.Text = Format.Number(math.round(UpgradesConfigurations["Speed1"].Money * UpgradesConfigurations["Speed1"].IncrementMultiplier ^ (Speed + 9)))
	UpgradesFrame.Speed10.Robux.Text = getRobuxPriceText(UpgradesConfigurations["Speed10"].ProductId)

	UpgradesFrame.Speed1.MoneyBackground.Visible = true
	UpgradesFrame.Speed1.RobuxBackground.Visible = true
	UpgradesFrame.Speed1.Money.Visible = true
	UpgradesFrame.Speed1.Robux.Visible = true
	UpgradesFrame.Speed5.MoneyBackground.Visible = true
	UpgradesFrame.Speed5.RobuxBackground.Visible = true
	UpgradesFrame.Speed5.Money.Visible = true
	UpgradesFrame.Speed5.Robux.Visible = true
	UpgradesFrame.Speed10.MoneyBackground.Visible = true
	UpgradesFrame.Speed10.RobuxBackground.Visible = true
	UpgradesFrame.Speed10.Money.Visible = true
	UpgradesFrame.Speed10.Robux.Visible = true

	if Speed + 1 > GameConfigurations.Maximums.Speed then
		UpgradesFrame.Speed1.MoneyBackground.Visible = false
		UpgradesFrame.Speed1.RobuxBackground.Visible = false
		UpgradesFrame.Speed1.Money.Visible = false
		UpgradesFrame.Speed1.Robux.Visible = false
		UpgradesFrame.Speed1.Speed1.Text = "MAX"
	end

	if Speed + 5 > GameConfigurations.Maximums.Speed then
		UpgradesFrame.Speed5.MoneyBackground.Visible = false
		UpgradesFrame.Speed5.RobuxBackground.Visible = false
		UpgradesFrame.Speed5.Money.Visible = false
		UpgradesFrame.Speed5.Robux.Visible = false
		UpgradesFrame.Speed5.Speed5.Text = "MAX"
	end

	if Speed + 10 > GameConfigurations.Maximums.Speed then
		UpgradesFrame.Speed10.MoneyBackground.Visible = false
		UpgradesFrame.Speed10.RobuxBackground.Visible = false
		UpgradesFrame.Speed10.Money.Visible = false
		UpgradesFrame.Speed10.Robux.Visible = false
		UpgradesFrame.Speed10.Speed10.Text = "MAX"
	end
end

local function RefreshCarry(Carry)
	Carry = tonumber(Carry) or 0

	UpgradesFrame.Carry1.Carry.Text = Carry
	UpgradesFrame.Carry1.Carry1.Text = Carry + 1
	UpgradesFrame.Carry1.Money.Text = Format.Number(math.round(UpgradesConfigurations["Carry1"].Money * UpgradesConfigurations["Carry1"].IncrementMultiplier ^ Carry))
	UpgradesFrame.Carry1.Robux.Text = getRobuxPriceText(UpgradesConfigurations["Carry1"].ProductId)
	UpgradesFrame.Carry1.MoneyBackground.Visible = true
	UpgradesFrame.Carry1.RobuxBackground.Visible = true
	UpgradesFrame.Carry1.Money.Visible = true
	UpgradesFrame.Carry1.Robux.Visible = true

	if Carry + 1 > GameConfigurations.Maximums.Carry then
		UpgradesFrame.Carry1.MoneyBackground.Visible = false
		UpgradesFrame.Carry1.RobuxBackground.Visible = false
		UpgradesFrame.Carry1.Money.Visible = false
		UpgradesFrame.Carry1.Robux.Visible = false
		UpgradesFrame.Carry1.Carry1.Text = "MAX"
	end
end

ScriptTrove:Connect(StatsController.Changed, function(Name, Value)
	if Name == "Speed" then
		RefreshSpeed(Value)
	elseif Name == "Carry" then
		RefreshCarry(Value)
	end
end)

ScriptTrove:Connect(UpgradesFrame.Speed1.Money.Activated, function()
	if tonumber(UpgradesFrame.Speed1.Speed1.Text) > GameConfigurations.Maximums.Speed then return end
	RequestController.IncrementSpeed(1)
end)

ScriptTrove:Connect(UpgradesFrame.Speed5.Money.Activated, function()
	if tonumber(UpgradesFrame.Speed5.Speed5.Text) > GameConfigurations.Maximums.Speed then return end
	RequestController.IncrementSpeed(5)
end)

ScriptTrove:Connect(UpgradesFrame.Speed10.Money.Activated, function()
	if tonumber(UpgradesFrame.Speed10.Speed10.Text) > GameConfigurations.Maximums.Speed then return end
	RequestController.IncrementSpeed(10)
end)

ScriptTrove:Connect(UpgradesFrame.Carry1.Money.Activated, function()
	if tonumber(UpgradesFrame.Carry1.Carry1.Text) > GameConfigurations.Maximums.Carry then return end
	RequestController.IncrementCarry(1)
end)

ScriptTrove:Connect(UpgradesFrame.Speed1.Robux.Activated, function()
	if tonumber(UpgradesFrame.Speed1.Speed1.Text) > GameConfigurations.Maximums.Speed then return end

	local ProductId = UpgradesConfigurations["Speed1"].ProductId
	if not ProductId then return end

	MarketplaceService:PromptProductPurchase(Player, ProductId)
end)

ScriptTrove:Connect(UpgradesFrame.Speed5.Robux.Activated, function()
	if tonumber(UpgradesFrame.Speed5.Speed5.Text) > GameConfigurations.Maximums.Speed then return end

	local ProductId = UpgradesConfigurations["Speed5"].ProductId
	if not ProductId then return end

	MarketplaceService:PromptProductPurchase(Player, ProductId)
end)

ScriptTrove:Connect(UpgradesFrame.Speed10.Robux.Activated, function()
	if tonumber(UpgradesFrame.Speed10.Speed10.Text) > GameConfigurations.Maximums.Speed then return end

	local ProductId = UpgradesConfigurations["Speed10"].ProductId
	if not ProductId then return end

	MarketplaceService:PromptProductPurchase(Player, ProductId)
end)

ScriptTrove:Connect(UpgradesFrame.Carry1.Robux.Activated, function()
	if tonumber(UpgradesFrame.Carry1.Carry1.Text) > GameConfigurations.Maximums.Carry then return end

	local ProductId = UpgradesConfigurations["Carry1"].ProductId
	if not ProductId then return end

	MarketplaceService:PromptProductPurchase(Player, ProductId)
end)

Animations.Frame(UpgradesFrame)
Animations.Button(DataFrame.Upgrades, DataFrame.Upgrades)
RefreshSpeed(StatsController.Get("Speed"))
RefreshCarry(StatsController.Get("Carry"))

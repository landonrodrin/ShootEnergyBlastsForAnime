local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Animations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("Animations"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))

local Player = Players.LocalPlayer
local ShopGui = script.Parent
local ShopFrame = ShopGui:WaitForChild("ShopFrame")
local ShopButton = ShopGui:WaitForChild("ShopButton")

ShopFrame.Header.Close.Activated:Connect(function()
	Animations.ToggleFrame(ShopFrame)
end)

ShopButton.Button.Activated:Connect(function()
	Animations.ToggleFrame(ShopFrame)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, GamepassId, WasPurchased)
	if not WasPurchased then return end

	if GamepassId == GameConfigurations.PassesIds.Vip then
		ShopFrame.Shop.Vip.PurchaseButton.Purchase.Text = "Owned"
	elseif GamepassId == GameConfigurations.PassesIds.VipPlus then
		ShopFrame.Shop.VipPlus.PurchaseButton.Purchase.Text = "Owned"
	end
end)

Animations.Frame(ShopFrame)
Animations.Button(ShopButton, ShopButton.Button)

local VipId = GameConfigurations.PassesIds.Vip
local VipPlusId = GameConfigurations.PassesIds.VipPlus

local OwnsVip = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, VipId)
local VipInfo = MarketplaceService:GetProductInfoAsync(VipId, Enum.InfoType.GamePass)

ShopFrame.Shop.Vip.PurchaseButton.Purchase.Text = OwnsVip and "Owned" or string.format("\u{E002} %s", Format.Number(VipInfo.PriceInRobux))

if not OwnsVip then
	ShopFrame.Shop.Vip.PurchaseButton.Purchase.Activated:Connect(function()
		local OwnsVipNow = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, VipId)
		if OwnsVipNow then return end

		MarketplaceService:PromptGamePassPurchase(Player, VipId)
	end)
end

local OwnsVipPlus = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, VipPlusId)
local VipPlusInfo = MarketplaceService:GetProductInfoAsync(VipPlusId, Enum.InfoType.GamePass)

ShopFrame.Shop.VipPlus.PurchaseButton.Purchase.Text = OwnsVipPlus and "Owned" or string.format("\u{E002} %s", Format.Number(VipPlusInfo.PriceInRobux))

if not OwnsVipPlus then
	ShopFrame.Shop.VipPlus.PurchaseButton.Purchase.Activated:Connect(function()
		local OwnsVipPlusNow = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, VipPlusId)
		if OwnsVipPlusNow then return end

		MarketplaceService:PromptGamePassPurchase(Player, VipPlusId)
	end)
end

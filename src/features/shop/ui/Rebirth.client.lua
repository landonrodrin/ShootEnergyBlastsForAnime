local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local Animations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("Animations"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Features.Shop.Shared:WaitForChild("RebirthsConfigurations"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
RequestController.Start()
StatsController.Start()

local Player = Players.LocalPlayer
local RebirthGui = script.Parent
local RebirthFrame = RebirthGui:WaitForChild("RebirthFrame")
local RebirthButton = RebirthGui:WaitForChild("RebirthButton")
local ScriptTrove = Trove.new()
local CurrentRebirths = StatsController.Get("Rebirths") or 0
local CurrentSpeed = StatsController.Get("Speed") or 0

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

ScriptTrove:Connect(RebirthFrame.Header.Close.Activated, function()
	Animations.ToggleFrame(RebirthFrame)
end)

ScriptTrove:Connect(RebirthButton.Button.Activated, function()
	Animations.ToggleFrame(RebirthFrame)
end)

local function Refresh()
	RebirthButton.Rebirths.Text = string.format("Rebirth %s", CurrentRebirths)
	RebirthFrame.CurrentRebirths.Text = string.format("Rebirth %s", CurrentRebirths)
	RebirthFrame.Multiplier.Text = string.format("%sx Money", RebirthsConfigurations[CurrentRebirths] and RebirthsConfigurations[CurrentRebirths].Multiplier or 1)

	if RebirthsConfigurations[CurrentRebirths + 1] then
		local NextConfiguration = RebirthsConfigurations[CurrentRebirths + 1]

		RebirthFrame.NextRebirths.Text = string.format("Rebirth %s", CurrentRebirths + 1)
		RebirthFrame.NextMultiplier.Text = string.format("%sx Money", NextConfiguration.Multiplier)
		RebirthFrame.Speed.Speed.Speed.Text = string.format("Speed %s / %s", CurrentSpeed, NextConfiguration.Speed)
		RebirthFrame.Speed.Speed.Percentage.Size = UDim2.fromScale(math.clamp(CurrentSpeed / NextConfiguration.Speed, 0, 1), 1)
		RebirthFrame.Rebirth.Visible = true
		RebirthFrame.SkipRebirth.Visible = true
		RebirthFrame.RebirthBackground.Visible = true
		RebirthFrame.SkipRebirthBackground.Visible = true
	else
		RebirthFrame.NextRebirths.Text = "MAX"
		RebirthFrame.NextMultiplier.Text = "MAX"
		RebirthFrame.Speed.Speed.Speed.Text = "MAX"
		RebirthFrame.Speed.Speed.Percentage.Size = UDim2.fromScale(1, 1)
		RebirthFrame.Rebirth.Visible = false
		RebirthFrame.SkipRebirth.Visible = false
		RebirthFrame.RebirthBackground.Visible = false
		RebirthFrame.SkipRebirthBackground.Visible = false
	end
end

ScriptTrove:Connect(StatsController.Changed, function(Name)
	if Name == "Rebirths" then
		CurrentRebirths = StatsController.Get("Rebirths") or 0
	elseif Name == "Speed" then
		CurrentSpeed = StatsController.Get("Speed") or CurrentSpeed
	else
		return
	end

	Refresh()
end)

ScriptTrove:Connect(RebirthFrame.Rebirth.Activated, function()
	RequestController.Rebirth()
end)

ScriptTrove:Connect(RebirthFrame.SkipRebirth.Activated, function()
	MarketplaceService:PromptProductPurchase(Player, GameConfigurations.ProductsIds.SkipRebirth)
end)

Animations.Frame(RebirthFrame)
Animations.Button(RebirthButton, RebirthButton.Button)
Refresh()

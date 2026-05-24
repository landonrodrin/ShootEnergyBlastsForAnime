local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Network:WaitForChild("Packets"))
local Animations = require(ReplicatedStorage.Modules:WaitForChild("Animations"))
local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("RebirthsConfigurations"))
local UiClientUtil = require(script.Parent.Parent:WaitForChild("UiClientUtil"))

script:SetAttribute("ByteNetUiScript", true)
UiClientUtil.PurgeDuplicateSiblingScripts(script)

local Player = Players.LocalPlayer
local RebirthGui = script.Parent
local RebirthFrame = RebirthGui:WaitForChild("RebirthFrame")
local RebirthButton = RebirthGui:WaitForChild("RebirthButton")
local ScriptTrove = Trove.new()
local CurrentRebirths = 0
local CurrentSpeed = 0

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
		RebirthFrame.Speed.Speed.Percentage.Size = UDim2.new(math.clamp(CurrentSpeed / NextConfiguration.Speed, 0, 1), 0, 1, 0)
		RebirthFrame.Rebirth.Visible = true
		RebirthFrame.SkipRebirth.Visible = true
		RebirthFrame.RebirthBackground.Visible = true
		RebirthFrame.SkipRebirthBackground.Visible = true
	else
		RebirthFrame.NextRebirths.Text = "MAX"
		RebirthFrame.NextMultiplier.Text = "MAX"
		RebirthFrame.Speed.Speed.Speed.Text = "MAX"
		RebirthFrame.Speed.Speed.Percentage.Size = UDim2.new(1, 0, 1, 0)
		RebirthFrame.Rebirth.Visible = false
		RebirthFrame.SkipRebirth.Visible = false
		RebirthFrame.RebirthBackground.Visible = false
		RebirthFrame.SkipRebirthBackground.Visible = false
	end
end

Packets.Listen(Packets.rebirth, function(Data)
	CurrentRebirths = Data and Data.Rebirths or 0
	CurrentSpeed = Data and Data.Speed or CurrentSpeed

	Refresh()
end, ScriptTrove)

Packets.Listen(Packets.speed, function(Speed)
	CurrentSpeed = tonumber(Speed) or CurrentSpeed

	Refresh()
end, ScriptTrove)

ScriptTrove:Connect(RebirthFrame.Rebirth.Activated, function()
	Packets.rebirthRequest.send(nil)
end)

ScriptTrove:Connect(RebirthFrame.SkipRebirth.Activated, function()
	MarketplaceService:PromptProductPurchase(Player, GameConfigurations.ProductsIds.SkipRebirth)
end)

Animations.Frame(RebirthFrame)
Animations.Button(RebirthButton, RebirthButton.Button)
Refresh()

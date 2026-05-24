local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Network:WaitForChild("Packets"))
local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local UiClientUtil = require(script.Parent.Parent:WaitForChild("UiClientUtil"))

script:SetAttribute("ByteNetUiScript", true)
UiClientUtil.PurgeDuplicateSiblingScripts(script)

local DataGui = script.Parent
local DataFrame = DataGui:WaitForChild("DataFrame")
local ScriptTrove = Trove.new()
local SavedSpeed = GameConfigurations.Defaults.Speed
local UseNormalSpeed = false

local function RefreshSpeed()
	local ActiveSpeed = UseNormalSpeed and 16 or SavedSpeed
	DataFrame.Speed.Text = string.format("Speed: %s", Format.Number(ActiveSpeed))
end

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

Packets.Listen(Packets.money, function(Money)
	DataFrame.Money.Text = string.format("$%s", Format.Number(Money))
end, ScriptTrove)

Packets.Listen(Packets.speed, function(Speed)
	SavedSpeed = tonumber(Speed) or SavedSpeed
	RefreshSpeed()
end, ScriptTrove)

Packets.Listen(Packets.toggleSpeed, function(UseNormal)
	UseNormalSpeed = UseNormal == true
	RefreshSpeed()
end, ScriptTrove)

RefreshSpeed()

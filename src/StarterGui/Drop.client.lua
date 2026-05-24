local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Network:WaitForChild("Packets"))

local Player = Players.LocalPlayer
local DropGui = script.Parent
local DropFrame = DropGui:WaitForChild("DropFrame")
local ScriptTrove = Trove.new()

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

ScriptTrove:Connect(Player.CharacterRemoving, function()
	DropFrame.Visible = false
end)

Packets.Listen(Packets.dropState, function(Data)
	DropFrame.Visible = Data and Data.CanDrop == true
end, ScriptTrove)

ScriptTrove:Connect(DropFrame.Drop.Activated, function()
	Packets.dropRequest.send(nil)
end)

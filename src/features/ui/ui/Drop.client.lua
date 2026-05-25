local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))

local Controllers = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Controllers")
local InventoryController = require(Controllers:WaitForChild("InventoryController"))
InventoryController.Start()

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

ScriptTrove:Connect(InventoryController.Changed, function(Name, Value)
	if Name ~= "CanDrop" then return end

	DropFrame.Visible = Value == true
end)

ScriptTrove:Connect(DropFrame.Drop.Activated, function()
	InventoryController.Drop()
end)

DropFrame.Visible = InventoryController.CanDrop()

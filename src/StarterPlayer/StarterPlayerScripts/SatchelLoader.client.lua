local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")
local Satchel = require(Vendor:WaitForChild("Satchel"))

Satchel:SetBackpackEnabled(true)

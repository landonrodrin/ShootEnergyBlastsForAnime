local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Index = Packages:WaitForChild("_Index")

return require(Index:WaitForChild("1foreverhd_topbarplus@3.4.0"):WaitForChild("topbarplus"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))

local Controllers = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Controllers")
local StatsController = require(Controllers:WaitForChild("StatsController"))
StatsController.Start()

local DataGui = script.Parent
local DataFrame = DataGui:WaitForChild("DataFrame")
local ScriptTrove = Trove.new()

local function RefreshSpeed()
	local SavedSpeed = StatsController.Get("Speed") or 0
	local UseNormalSpeed = StatsController.Get("UseNormalSpeed") == true
	local ActiveSpeed = UseNormalSpeed and 16 or SavedSpeed
	DataFrame.Speed.Text = string.format("Speed: %s", Format.Number(ActiveSpeed))
end

local function RefreshMoney()
	DataFrame.Money.Text = string.format("$%s", Format.Number(StatsController.Get("Money") or 0))
end

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

ScriptTrove:Connect(StatsController.Changed, function(Name)
	if Name == "Money" then
		RefreshMoney()
	elseif Name == "Speed" or Name == "UseNormalSpeed" then
		RefreshSpeed()
	end
end)

RefreshMoney()
RefreshSpeed()

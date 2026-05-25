local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))

local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
StatsController.Start()

local DataGui = script.Parent
local DataFrame = DataGui:WaitForChild("DataFrame")
local ScriptTrove = Trove.new()

local function RefreshSpeed()
	local SavedSpeed = StatsController.Get("Speed") or 0
	DataFrame.Speed.Text = string.format("Speed: %s", Format.Number(SavedSpeed))
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
	elseif Name == "Speed" then
		RefreshSpeed()
	end
end)

RefreshMoney()
RefreshSpeed()

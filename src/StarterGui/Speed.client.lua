local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))

local Controllers = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Controllers")
local RequestController = require(Controllers:WaitForChild("RequestController"))
local StatsController = require(Controllers:WaitForChild("StatsController"))
RequestController.Start()
StatsController.Start()

local SpeedGui = script.Parent
local SpeedButton = SpeedGui:WaitForChild("SpeedButton")
local UseNormalSpeed = StatsController.Get("UseNormalSpeed") == true
local ScriptTrove = Trove.new()

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

local function ApplySpeedToggle()
	SpeedButton.Speed.Text = string.format("%s [T]", UseNormalSpeed and "Normal" or "Slow")
	SpeedButton.UIGradient.Color = UseNormalSpeed
		and ColorSequence.new(Color3.fromRGB(242, 255, 0), Color3.fromRGB(77, 209, 0))
		or ColorSequence.new(Color3.fromRGB(232, 232, 232), Color3.fromRGB(145, 145, 145))
end

ScriptTrove:Connect(StatsController.Changed, function(Name, Value)
	if Name ~= "UseNormalSpeed" then return end

	UseNormalSpeed = Value == true
	ApplySpeedToggle()
end)

local function ToggleSpeed()
	local NextUseNormalSpeed = not UseNormalSpeed
	if not RequestController.ToggleSpeed(NextUseNormalSpeed) then return end

	UseNormalSpeed = NextUseNormalSpeed
	ApplySpeedToggle()
end

ScriptTrove:Connect(SpeedButton.Speed.Activated, ToggleSpeed)

ScriptTrove:Connect(UserInputService.InputBegan, function(Input, Processed)
	if Processed then return end
	if Input.KeyCode ~= Enum.KeyCode.T then return end

	ToggleSpeed()
end)

ApplySpeedToggle()

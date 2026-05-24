local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Network:WaitForChild("Packets"))
local UiClientUtil = require(script.Parent.Parent:WaitForChild("UiClientUtil"))

script:SetAttribute("ByteNetUiScript", true)
UiClientUtil.PurgeDuplicateSiblingScripts(script)

local SpeedGui = script.Parent
local SpeedButton = SpeedGui:WaitForChild("SpeedButton")
local UseNormalSpeed = false
local ScriptTrove = Trove.new()

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

local function ApplySpeedToggle(SendToServer)
	if SendToServer then
		Packets.toggleSpeed.send(UseNormalSpeed)
	end

	SpeedButton.Speed.Text = string.format("%s [T]", UseNormalSpeed and "Normal" or "Slow")
	SpeedButton.UIGradient.Color = UseNormalSpeed
		and ColorSequence.new(Color3.fromRGB(242, 255, 0), Color3.fromRGB(77, 209, 0))
		or ColorSequence.new(Color3.fromRGB(232, 232, 232), Color3.fromRGB(145, 145, 145))
end

Packets.Listen(Packets.toggleSpeed, function(UseNormal)
	UseNormalSpeed = UseNormal == true
	ApplySpeedToggle(false)
end, ScriptTrove)

ScriptTrove:Connect(SpeedButton.Speed.Activated, function()
	UseNormalSpeed = not UseNormalSpeed
	ApplySpeedToggle(true)
end)

ScriptTrove:Connect(UserInputService.InputBegan, function(Input, Processed)
	if Processed then return end
	if Input.KeyCode ~= Enum.KeyCode.T then return end

	UseNormalSpeed = not UseNormalSpeed
	ApplySpeedToggle(true)
end)

ApplySpeedToggle(false)

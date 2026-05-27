local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Shared.Packages:WaitForChild("ReactRoblox"))
local ZonePlus = require(ReplicatedStorage.Shared.Packages:WaitForChild("ZonePlus"))
local PlayerUiController = require(script.Parent:WaitForChild("PlayerUiController"))

local UiController = {}

local Started = false
local Root = nil

function UiController.Init() end

function UiController.Start()
	if Started then return end
	Started = true

	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local Gui = PlayerGui:FindFirstChild("FeatureReactGui")
	if not Gui then
		Gui = Instance.new("ScreenGui")
		Gui.Name = "FeatureReactGui"
		Gui.IgnoreGuiInset = true
		Gui.ResetOnSpawn = false
		Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		Gui.Parent = PlayerGui
	end

	Root = ReactRoblox.createRoot(Gui)
	Root:render(React.createElement(PlayerUiController))

	Gui.Destroying:Connect(function()
		if Root then
			Root:unmount()
			Root = nil
		end
	end)
end

function UiController.BindZoneFrame(OwnerTrove, ZoneContainer, Frame, SetOpen)
	local Zone = ZonePlus.CreatePresenceZone(ZoneContainer)
	OwnerTrove:Add(Zone, "destroy")

	local function applyOpen(Open)
		if SetOpen then
			SetOpen(Open)
		else
			Frame.Visible = Open
		end
	end

	ZonePlus.ConnectSignal(OwnerTrove, Zone.localPlayerEntered, function()
		applyOpen(true)
	end)

	ZonePlus.ConnectSignal(OwnerTrove, Zone.localPlayerExited, function()
		applyOpen(false)
	end)

	if Zone:findLocalPlayer() then
		applyOpen(true)
	end

	return Zone
end

return UiController

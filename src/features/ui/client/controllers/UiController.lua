local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Shared.Packages:WaitForChild("ReactRoblox"))
local ZonePlus = require(ReplicatedStorage.Shared.Packages:WaitForChild("ZonePlus"))
local AnnouncementController = require(script.Parent:WaitForChild("AnnouncementController"))
local PlayerUiController = require(script.Parent:WaitForChild("PlayerUiController"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))

local UiController = {}

local ANNOUNCEMENTS = UiTuning.Announcements

local Started = false
local Root = nil
local AnnouncementRoot = nil

local function unmountRoot(RootHandle)
	if RootHandle then
		RootHandle:unmount()
	end
end

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

	local AnnouncementGui = PlayerGui:FindFirstChild("FeatureAnnouncementGui")
	if not AnnouncementGui then
		AnnouncementGui = Instance.new("ScreenGui")
		AnnouncementGui.Name = "FeatureAnnouncementGui"
		AnnouncementGui.Parent = PlayerGui
	end
	AnnouncementGui.DisplayOrder = ANNOUNCEMENTS.DisplayOrder
	AnnouncementGui.IgnoreGuiInset = true
	AnnouncementGui.ResetOnSpawn = false
	AnnouncementGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	Root = ReactRoblox.createRoot(Gui)
	Root:render(React.createElement(PlayerUiController))

	AnnouncementRoot = ReactRoblox.createRoot(AnnouncementGui)
	AnnouncementRoot:render(React.createElement(AnnouncementController))

	Gui.Destroying:Connect(function()
		unmountRoot(Root)
		Root = nil
	end)

	AnnouncementGui.Destroying:Connect(function()
		unmountRoot(AnnouncementRoot)
		AnnouncementRoot = nil
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

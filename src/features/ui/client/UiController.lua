local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZonePlus = require(ReplicatedStorage.Shared:WaitForChild("ZonePlus"))

local UiController = {}

local Started = false

function UiController.Init() end

function UiController.Start()
	if Started then return end
	Started = true
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

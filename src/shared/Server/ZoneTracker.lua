local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local ZonePlus = require(ReplicatedStorage.Shared.Packages:WaitForChild("ZonePlus"))

local ZoneTracker = {}

local Zones = {}
local PlayerZoneCounts = {}
local ZoneTroves = {}

local function disconnectZone(Name)
	local ZoneTrove = ZoneTroves[Name]
	if ZoneTrove then
		ZoneTrove:Destroy()
		ZoneTroves[Name] = nil
	end
end

local function getPlayerZoneCounts(Player)
	PlayerZoneCounts[Player] = PlayerZoneCounts[Player] or {}
	return PlayerZoneCounts[Player]
end

local function clearZoneCounts(Name)
	for _, Counts in pairs(PlayerZoneCounts) do
		Counts[Name] = nil
	end
end

function ZoneTracker.RegisterZone(Name, Container, DetectionMode, AccuracyMode)
	assert(typeof(Name) == "string" and Name ~= "", "Zone name must be a non-empty string")
	assert(typeof(Container) == "Instance", "Zone container must be an Instance")

	disconnectZone(Name)
	clearZoneCounts(Name)

	Zones[Name] = Container

	local ZoneTrove = Trove.new()
	local Zone = ZonePlus.CreatePresenceZone(Container, DetectionMode, AccuracyMode)
	ZoneTrove:Add(Zone, "destroy")

	ZonePlus.ConnectSignal(ZoneTrove, Zone.playerEntered, function(Player)
		local Counts = getPlayerZoneCounts(Player)
		Counts[Name] = 1
	end)

	ZonePlus.ConnectSignal(ZoneTrove, Zone.playerExited, function(Player)
		local Counts = PlayerZoneCounts[Player]
		if Counts then
			Counts[Name] = nil
		end
	end)

	for _, Player in ipairs(Players:GetPlayers()) do
		if Zone:findPlayer(Player) then
			local Counts = getPlayerZoneCounts(Player)
			Counts[Name] = 1
		end
	end

	ZoneTroves[Name] = ZoneTrove

	return Container
end

function ZoneTracker.IsInZone(Player, Name)
	local Counts = PlayerZoneCounts[Player]
	return Counts and (Counts[Name] or 0) > 0 or false
end

function ZoneTracker.GetZonePart(Name)
	return Zones[Name]
end

function ZoneTracker.ClearPlayer(Player)
	PlayerZoneCounts[Player] = nil
end

Players.PlayerRemoving:Connect(ZoneTracker.ClearPlayer)

return ZoneTracker

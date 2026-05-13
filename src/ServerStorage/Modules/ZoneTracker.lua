local Players = game:GetService("Players")

local ZoneTracker = {}

local Zones = {}
local PlayerZoneCounts = {}
local ZoneConnections = {}

local function getPlayerFromHit(Hit)
	if not Hit then return end

	local Character = Hit:FindFirstAncestorOfClass("Model")
	if not Character then return end

	return Players:GetPlayerFromCharacter(Character)
end

local function disconnectZone(Name)
	local Connections = ZoneConnections[Name]
	if not Connections then return end

	for _, Connection in ipairs(Connections) do
		Connection:Disconnect()
	end

	ZoneConnections[Name] = nil
end

local function getPlayerZoneCounts(Player)
	PlayerZoneCounts[Player] = PlayerZoneCounts[Player] or {}
	return PlayerZoneCounts[Player]
end

function ZoneTracker.RegisterZone(Name, Part)
	assert(typeof(Name) == "string" and Name ~= "", "Zone name must be a non-empty string")
	assert(typeof(Part) == "Instance" and Part:IsA("BasePart"), "Zone part must be a BasePart")

	disconnectZone(Name)

	Zones[Name] = Part

	local Connections = {}

	table.insert(Connections, Part.Touched:Connect(function(Hit)
		local Player = getPlayerFromHit(Hit)
		if not Player then return end

		local Counts = getPlayerZoneCounts(Player)
		Counts[Name] = (Counts[Name] or 0) + 1
	end))

	table.insert(Connections, Part.TouchEnded:Connect(function(Hit)
		local Player = getPlayerFromHit(Hit)
		if not Player then return end

		local Counts = PlayerZoneCounts[Player]
		if not Counts or not Counts[Name] then return end

		Counts[Name] -= 1
		if Counts[Name] <= 0 then
			Counts[Name] = nil
		end
	end))

	ZoneConnections[Name] = Connections

	return Part
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

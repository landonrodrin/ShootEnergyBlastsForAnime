local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LadderNudge = {}

local TAG_NAME = "LadderNudge"
local CENTER_PART_NAME_ATTRIBUTE = "LadderCenterPartName"
local CENTER_PART_OBJECT_NAME = "LadderCenterPart"
local NUDGE_SPEED = 24
local MAX_SIDEWAYS_SPEED = 36
local NUDGE_ACCELERATION = 180

local player = Players.LocalPlayer
local started = false
local character = nil
local humanoid = nil
local rootPart = nil
local activeZones = {}
local touchingParts = {}
local zoneConnections = {}

local function flatten(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

local function unitOrNil(vector)
	local flat = flatten(vector)
	if flat.Magnitude <= 0.001 then
		return nil
	end

	return flat.Unit
end

local function findCenterPart(zone)
	local centerObject = zone:FindFirstChild(CENTER_PART_OBJECT_NAME)
	if centerObject and centerObject:IsA("ObjectValue") and centerObject.Value and centerObject.Value:IsA("BasePart") then
		return centerObject.Value
	end

	local centerName = zone:GetAttribute(CENTER_PART_NAME_ATTRIBUTE)
	if typeof(centerName) ~= "string" or centerName == "" then
		return nil
	end

	local parentMatch = zone.Parent and zone.Parent:FindFirstChild(centerName, true)
	if parentMatch and parentMatch:IsA("BasePart") then
		return parentMatch
	end

	local workspaceMatch = workspace:FindFirstChild(centerName, true)
	if workspaceMatch and workspaceMatch:IsA("BasePart") then
		return workspaceMatch
	end
end

local function getNudgeDirection(zone)
	if not rootPart then
		return nil
	end

	local centerPart = findCenterPart(zone)
	if centerPart then
		return unitOrNil(centerPart.Position - rootPart.Position)
	end
end

local function isCharacterPart(part)
	return character and part and part:IsDescendantOf(character)
end

local function disconnectZone(zone)
	local connections = zoneConnections[zone]
	if not connections then
		return
	end

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	zoneConnections[zone] = nil
	activeZones[zone] = nil
	touchingParts[zone] = nil
end

local function connectZone(zone)
	if not zone:IsA("BasePart") or zoneConnections[zone] then
		return
	end

	zoneConnections[zone] = {
		zone.Touched:Connect(function(hit)
			if not isCharacterPart(hit) then
				return
			end

			touchingParts[zone] = touchingParts[zone] or {}
			touchingParts[zone][hit] = true
			activeZones[zone] = true
		end),

		zone.TouchEnded:Connect(function(hit)
			if not isCharacterPart(hit) then
				return
			end

			if touchingParts[zone] then
				touchingParts[zone][hit] = nil
				activeZones[zone] = next(touchingParts[zone]) ~= nil or nil
			else
				activeZones[zone] = nil
			end
		end),

		zone.AncestryChanged:Connect(function(_, parent)
			if parent then
				return
			end

			disconnectZone(zone)
		end)
	}
end

local function setCharacter(nextCharacter)
	character = nextCharacter
	humanoid = nil
	rootPart = nil
	activeZones = {}
	touchingParts = {}

	if not character then
		return
	end

	humanoid = character:WaitForChild("Humanoid", 10)
	rootPart = character:WaitForChild("HumanoidRootPart", 10)
end

local function applyNudge(deltaTime)
	if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	local directionSum = Vector3.zero

	for zone in pairs(activeZones) do
		if not zone.Parent then
			activeZones[zone] = nil
			touchingParts[zone] = nil
			continue
		end

		local direction = getNudgeDirection(zone)
		if direction then
			directionSum += direction
		end
	end

	local direction = unitOrNil(directionSum)
	if not direction then
		return
	end

	local velocity = rootPart.AssemblyLinearVelocity
	local sideSpeed = velocity:Dot(direction)
	local targetSideSpeed = math.min(NUDGE_SPEED, MAX_SIDEWAYS_SPEED)

	if sideSpeed >= targetSideSpeed then
		return
	end

	local nextSideSpeed = math.min(targetSideSpeed, sideSpeed + NUDGE_ACCELERATION * deltaTime)
	rootPart.AssemblyLinearVelocity = velocity + direction * (nextSideSpeed - sideSpeed)
end

function LadderNudge.Start()
	if started then
		return
	end

	started = true

	setCharacter(player.Character or player.CharacterAdded:Wait())
	player.CharacterAdded:Connect(setCharacter)

	for _, zone in ipairs(CollectionService:GetTagged(TAG_NAME)) do
		connectZone(zone)
	end

	CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(connectZone)
	CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(disconnectZone)

	RunService.Heartbeat:Connect(applyNudge)
end

return LadderNudge

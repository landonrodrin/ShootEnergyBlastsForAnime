local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WallConfig = require(ReplicatedStorage.Features.Walls.Shared:WaitForChild("WallConfig"))
local WallEffects = require(script.Parent:WaitForChild("WallEffects"))
local WallRegistry = require(script.Parent:WaitForChild("WallRegistry"))

local WallDamage = {}

local lastShotAt = {}
local shotParamsByPlayer = {}

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getPartPosition(character, names)
	for _, name in ipairs(names) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part.Position
		end
	end

	return nil
end

local function getHandOrigin(character)
	local leftPosition = getPartPosition(character, { "LeftHand", "Left Arm", "LeftLowerArm", "LeftUpperArm" })
	local rightPosition = getPartPosition(character, { "RightHand", "Right Arm", "RightLowerArm", "RightUpperArm" })

	if leftPosition and rightPosition then
		return (leftPosition + rightPosition) * 0.5
	end

	return rightPosition or leftPosition
end

local function getShotOrigin(player)
	local character = player.Character
	if not character then
		return nil
	end

	local handOrigin = getHandOrigin(character)
	if handOrigin then
		return handOrigin
	end

	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")
	return head and head.Position or root and root.Position or nil
end

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function isFiniteVector3(value)
	return typeof(value) == "Vector3"
		and isFiniteNumber(value.X)
		and isFiniteNumber(value.Y)
		and isFiniteNumber(value.Z)
end

local function canShoot(player, origin)
	local now = os.clock()
	local previous = lastShotAt[player]
	if previous and now - previous < 1 / WallConfig.FireRate then
		return false
	end
	lastShotAt[player] = now

	local root = getCharacterRoot(player)
	if not root then
		return false
	end

	if (origin - root.Position).Magnitude > WallConfig.OriginTolerance then
		return false
	end

	return true
end

local function getShotParams(player, character)
	local cached = shotParamsByPlayer[player]
	if cached and cached.character == character then
		return cached.raycastParams, cached.overlapParams
	end

	local filterDescendants = character and { character } or {}
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = filterDescendants
	raycastParams.IgnoreWater = true

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = filterDescendants

	shotParamsByPlayer[player] = {
		character = character,
		raycastParams = raycastParams,
		overlapParams = overlapParams,
	}

	return raycastParams, overlapParams
end

local function getDistanceAlongShot(origin, directionUnit, position)
	return math.clamp((position - origin):Dot(directionUnit), 0, WallConfig.MaxRange)
end

local function findWideShotWall(player, origin, directionUnit, character)
	local raycastParams, overlapParams = getShotParams(player, character)
	local exactResult = workspace:Raycast(origin, directionUnit * WallConfig.MaxRange, raycastParams)
	if exactResult then
		local exactState = WallRegistry.GetWallFromHit(exactResult.Instance)
		if exactState and not exactState.destroyed then
			return exactState, exactResult.Position
		end
	end

	local shotRadius = WallConfig.ShotRadius or 0
	if shotRadius <= 0 then
		return nil, exactResult and "not_wall" or "miss"
	end

	local shotLength = WallConfig.MaxRange
	local shotCenter = origin + directionUnit * (shotLength * 0.5)
	local shotCFrame = CFrame.lookAt(shotCenter, shotCenter + directionUnit)
	local shotSize = Vector3.new(shotRadius * 2, shotRadius * 2, shotLength)
	local parts = workspace:GetPartBoundsInBox(shotCFrame, shotSize, overlapParams)

	local blockingDistance = exactResult and (exactResult.Position - origin).Magnitude or nil
	local bestState = nil
	local bestDistance = math.huge
	local seenStates = {}

	for _, part in ipairs(parts) do
		local state = WallRegistry.GetWallFromHit(part)
		if state and not state.destroyed and not seenStates[state] then
			seenStates[state] = true

			local distance = getDistanceAlongShot(origin, directionUnit, state.wall.Position)
			if distance < bestDistance then
				bestDistance = distance
				bestState = state
			end
		end
	end

	if bestState and (not blockingDistance or bestDistance <= blockingDistance + shotRadius) then
		return bestState, origin + directionUnit * bestDistance
	end

	return nil, exactResult and "not_wall" or "miss"
end

local function breakWall(state, hitPosition)
	if state.destroyed then
		return
	end

	state.destroyed = true
	WallRegistry.SetHp(state, 0)
	WallRegistry.SetWallActive(state, false)
	WallEffects.PlayDebris(state, hitPosition)
end

function WallDamage.OnShoot(player, data)
	local targetPoint = data and data.TargetPoint
	if not isFiniteVector3(targetPoint) then
		return false, "bad_target"
	end

	local origin = getShotOrigin(player)
	if not origin or not canShoot(player, origin) then
		return false, "not_ready"
	end

	local direction = targetPoint - origin
	if direction.Magnitude < 0.1 then
		return false, "too_close"
	end

	local character = player.Character
	local state, hitPositionOrReason = findWideShotWall(player, origin, direction.Unit, character)
	if not state then
		return false, hitPositionOrReason
	end

	WallRegistry.SetHp(state, state.hp - WallConfig.DamagePerShot)

	if state.hp <= 0 then
		breakWall(state, hitPositionOrReason)
	end

	return true
end

function WallDamage.ClearPlayer(player)
	lastShotAt[player] = nil
	shotParamsByPlayer[player] = nil
end

return WallDamage

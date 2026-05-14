local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WallConfig = require(shared:WaitForChild("WallConfig"))
local PathUtils = require(shared:WaitForChild("PathUtils"))
local FinishBarrier = require(ServerStorage.Modules:WaitForChild("FinishBarrier"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shootRemote = remotes:WaitForChild("ShootWall")
local wallDebrisRemote = remotes:WaitForChild("WallDebris")

local WallGameplay = {}

local started = false
local wallStates = {}
local wallsByPart = {}
local lastShotAt = {}
local PLAYER_COLLISION_GROUP = "Players"
local LOCAL_DEBRIS_COLLISION_GROUP = "LocalWallDebris"

local function ensureCollisionGroup(name)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

local function setupCollisionGroups()
	ensureCollisionGroup(PLAYER_COLLISION_GROUP)
	ensureCollisionGroup(LOCAL_DEBRIS_COLLISION_GROUP)

	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(LOCAL_DEBRIS_COLLISION_GROUP, PLAYER_COLLISION_GROUP, false)
	end)
end

local function setPartCollisionGroup(part, groupName)
	pcall(function()
		part.CollisionGroup = groupName
	end)
end

local function assignCharacterCollisionGroup(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			setPartCollisionGroup(descendant, PLAYER_COLLISION_GROUP)
		end
	end

	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			setPartCollisionGroup(descendant, PLAYER_COLLISION_GROUP)
		end
	end)
end

local function setupPlayerCollision(player)
	if player.Character then
		assignCharacterCollisionGroup(player.Character)
	end

	player.CharacterAdded:Connect(assignCharacterCollisionGroup)
end

local function warnAndRepairWallUi(wall, missingName)
	warn(string.format("Missing %s on %s; repairing wall HP UI.", missingName, wall:GetFullName()))
end

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

local function ensureHpLabel(wall)
	local gui = wall:FindFirstChild("WallHPText")
	if not gui then
		warnAndRepairWallUi(wall, "WallHPText")
		gui = Instance.new("SurfaceGui")
		gui.Name = "WallHPText"
		gui.Face = Enum.NormalId.Back
		gui.AlwaysOnTop = false
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.Parent = wall
	end

	gui.Enabled = true
	gui.Parent = wall

	local label = gui:FindFirstChild("HPLabel")
	if not label then
		warnAndRepairWallUi(wall, "HPLabel")
		label = Instance.new("TextLabel")
		label.Name = "HPLabel"
		label.Parent = gui

		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.Position = UDim2.fromScale(0.5, 0.27)
		label.Size = UDim2.fromScale(0.9, 0.26)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0
	end

	local barBackground = gui:FindFirstChild("HPBarBackground")
	if not barBackground then
		warnAndRepairWallUi(wall, "HPBarBackground")
		barBackground = Instance.new("Frame")
		barBackground.Name = "HPBarBackground"
		barBackground.AnchorPoint = Vector2.new(0.5, 0.5)
		barBackground.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		barBackground.BackgroundTransparency = 0.2
		barBackground.BorderSizePixel = 0
		barBackground.Position = UDim2.fromScale(0.5, 0.78)
		barBackground.Size = UDim2.fromScale(0.7, 0.09)
		barBackground.Parent = gui
	end

	local barFill = barBackground:FindFirstChild("HPBarFill")
	if not barFill then
		warnAndRepairWallUi(wall, "HPBarFill")
		barFill = Instance.new("Frame")
		barFill.Name = "HPBarFill"
		barFill.AnchorPoint = Vector2.new(0, 0.5)
		barFill.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
		barFill.BorderSizePixel = 0
		barFill.Position = UDim2.fromScale(0, 0.5)
		barFill.Size = UDim2.fromScale(1, 1)
		barFill.Parent = barBackground
	end

	return label, barFill
end

local function getHpBarColor(hpPercent)
	if hpPercent > 0.5 then
		return Color3.fromRGB(255, 220, 0):Lerp(Color3.fromRGB(0, 220, 80), (hpPercent - 0.5) * 2)
	end

	return Color3.fromRGB(220, 35, 35):Lerp(Color3.fromRGB(255, 220, 0), hpPercent * 2)
end

local function updateHpLabel(state)
	local label, barFill = ensureHpLabel(state.wall)
	local hpPercent = math.clamp(state.hp / state.maxHP, 0, 1)

	label.Text = string.format("%d/%d", state.hp, state.maxHP)
	barFill.Size = UDim2.fromScale(hpPercent, 1)
	barFill.BackgroundColor3 = getHpBarColor(hpPercent)
end

local function setWallActive(state, active)
	local wall = state.wall
	wall.Transparency = active and state.originalTransparency or 1
	wall.CanCollide = active and state.originalCanCollide or false
	wall.CanQuery = active and state.originalCanQuery or false
	wall.CanTouch = active and state.originalCanTouch or false
	wall.Anchored = true
	wall:SetAttribute("Destroyed", not active)

	local gui = wall:FindFirstChild("WallHPText")
	if gui then
		gui.Enabled = active
	end
end

local function getNumberAttribute(instance, attributeName)
	local value = instance:GetAttribute(attributeName)
	if typeof(value) == "number" and value > 0 then
		return value
	end

	return nil
end

local function getStringAttribute(instance, attributeName)
	local value = instance:GetAttribute(attributeName)
	if typeof(value) == "string" and value ~= "" then
		return value
	end

	return nil
end

local function buildWallState(wall, defaults)
	if wallsByPart[wall] then
		return wallsByPart[wall]
	end

	if not wall:IsA("BasePart") then
		warn("Damageable wall must be a BasePart:", wall:GetFullName())
		return nil
	end

	local maxHP = getNumberAttribute(wall, "MaxHP") or defaults and defaults.MaxHP
	if not maxHP then
		warn("Damageable wall is missing a positive MaxHP attribute:", wall:GetFullName())
		return nil
	end

	local displayName = getStringAttribute(wall, "DisplayName") or defaults and defaults.DisplayName or wall.Name
	local id = getStringAttribute(wall, "WallId") or defaults and defaults.Id or wall:GetFullName()

	local state = {
		id = id,
		displayName = displayName,
		wall = wall,
		maxHP = maxHP,
		hp = maxHP,
		originalTransparency = wall.Transparency,
		originalCanCollide = wall.CanCollide,
		originalCanQuery = wall.CanQuery,
		originalCanTouch = wall.CanTouch,
		originalColor = wall.Color,
		originalMaterial = wall.Material,
		originalSize = wall.Size,
		originalCFrame = wall.CFrame,
	}

	table.insert(wallStates, state)
	wallsByPart[wall] = state

	wall:SetAttribute("DamageableWall", true)
	wall:SetAttribute("MaxHP", state.maxHP)
	wall:SetAttribute("HP", state.hp)
	setWallActive(state, true)
	updateHpLabel(state)

	return state
end

local function seedConfiguredWallAttributes(config)
	local wall = PathUtils.FindByPath(workspace, config.Path)
	if not wall then
		warn("Missing configured damageable wall:", table.concat(config.Path, "."))
		return nil
	end

	if not wall:IsA("BasePart") then
		warn("Configured damageable wall must be a BasePart:", wall:GetFullName())
		return nil
	end

	if wall:GetAttribute("DamageableWall") ~= true then
		wall:SetAttribute("DamageableWall", true)
	end

	if not getNumberAttribute(wall, "MaxHP") then
		wall:SetAttribute("MaxHP", config.MaxHP)
	end

	if not getStringAttribute(wall, "DisplayName") then
		wall:SetAttribute("DisplayName", config.DisplayName)
	end

	return wall
end

local function registerDamageableWalls()
	for _, wallConfig in ipairs(WallConfig.Walls) do
		seedConfiguredWallAttributes(wallConfig)
	end

	local strips = workspace:FindFirstChild("Strips")
	if strips then
		for _, descendant in ipairs(strips:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("DamageableWall") == true then
				buildWallState(descendant)
			end
		end
	else
		warn("Workspace.Strips is missing; using configured damageable walls only.")
	end

	for _, wallConfig in ipairs(WallConfig.Walls) do
		local wall = PathUtils.FindByPath(workspace, wallConfig.Path)
		if wall and not wallsByPart[wall] then
			buildWallState(wall, wallConfig)
		end
	end
end

local function getWallFromHit(instance)
	local current = instance
	while current and current ~= workspace do
		local state = wallsByPart[current]
		if state then
			return state
		end
		current = current.Parent
	end

	return nil
end

local function getDebrisCount(state)
	local debrisConfig = WallConfig.ClientDebris or {}
	if state.maxHP <= 1 then
		return debrisConfig.VipCount or 18
	end

	return debrisConfig.NormalCount or 35
end

local function playDebris(state, hitPosition)
	wallDebrisRemote:FireAllClients({
		id = state.id,
		displayName = state.displayName,
		wallCFrame = state.originalCFrame,
		wallSize = state.originalSize,
		wall = state.wall,
		hitPosition = hitPosition,
		color = state.originalColor,
		material = state.originalMaterial,
		count = getDebrisCount(state),
	})
end

local function breakWall(state, hitPosition)
	if state.destroyed then
		return
	end

	state.destroyed = true
	state.hp = 0
	state.wall:SetAttribute("HP", 0)
	updateHpLabel(state)
	setWallActive(state, false)
	playDebris(state, hitPosition)
end

local function resetWall(state)
	state.destroyed = false
	state.hp = state.maxHP
	state.wall.CFrame = state.originalCFrame
	state.wall.Size = state.originalSize
	state.wall.Color = state.originalColor
	state.wall.Material = state.originalMaterial
	state.wall:SetAttribute("MaxHP", state.maxHP)
	state.wall:SetAttribute("HP", state.hp)
	setWallActive(state, true)
	updateHpLabel(state)
end

local function resetAllWalls()
	for _, state in pairs(wallStates) do
		resetWall(state)
	end
end

local function fireResult(player, result)
	shootRemote:FireClient(player, result)
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

local function getShotRaycastParams(character)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = character and { character } or {}
	raycastParams.IgnoreWater = true
	return raycastParams
end

local function getShotOverlapParams(character)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = character and { character } or {}
	return overlapParams
end

local function getDistanceAlongShot(origin, directionUnit, position)
	return math.clamp((position - origin):Dot(directionUnit), 0, WallConfig.MaxRange)
end

local function findWideShotWall(origin, directionUnit, character)
	local raycastParams = getShotRaycastParams(character)
	local exactResult = workspace:Raycast(origin, directionUnit * WallConfig.MaxRange, raycastParams)
	if exactResult then
		local exactState = getWallFromHit(exactResult.Instance)
		if exactState and not exactState.destroyed then
			return exactState, exactResult.Position
		end
	end

	local shotRadius = WallConfig.ShotRadius or 0
	if shotRadius <= 0 then
		return nil, exactResult and "not_wall" or "miss"
	end

	local overlapParams = getShotOverlapParams(character)
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
		local state = getWallFromHit(part)
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

local function onShoot(player, targetPoint)
	if typeof(targetPoint) ~= "Vector3" then
		fireResult(player, { hit = false, reason = "bad_target" })
		return
	end

	local origin = getShotOrigin(player)
	if not origin or not canShoot(player, origin) then
		fireResult(player, { hit = false, reason = "not_ready" })
		return
	end

	local direction = targetPoint - origin
	if direction.Magnitude < 0.1 then
		fireResult(player, { hit = false, reason = "too_close" })
		return
	end

	local character = player.Character
	local state, hitPositionOrReason = findWideShotWall(origin, direction.Unit, character)
	if not state then
		fireResult(player, { hit = false, reason = hitPositionOrReason })
		return
	end

	state.hp = math.clamp(state.hp - WallConfig.DamagePerShot, 0, state.maxHP)
	state.wall:SetAttribute("HP", state.hp)
	updateHpLabel(state)

	local destroyed = state.hp <= 0
	if destroyed then
		breakWall(state, hitPositionOrReason)
	end

	fireResult(player, {
		hit = true,
		wallName = state.displayName,
		hp = state.hp,
		maxHP = state.maxHP,
		destroyed = destroyed,
	})
end

function WallGameplay.Start()
	if started then
		return
	end
	started = true

	setupCollisionGroups()
	shootRemote.OnServerEvent:Connect(onShoot)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerCollision(player)
	end
	Players.PlayerAdded:Connect(setupPlayerCollision)

	Players.PlayerRemoving:Connect(function(player)
		lastShotAt[player] = nil
	end)

	registerDamageableWalls()

	FinishBarrier.OnReturn(WallGameplay.ResetForFinishBarrier)
	print("Wall shooting server ready")
end

function WallGameplay.ResetForFinishBarrier(player)
	resetAllWalls()
	fireResult(player, { hit = false, reason = "walls_reset" })
end

return WallGameplay

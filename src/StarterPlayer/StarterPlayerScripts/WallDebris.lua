local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WallConfig = require(shared:WaitForChild("WallConfig"))
local Trove = require(shared:WaitForChild("Trove"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local wallDebrisRemote = remotes:WaitForChild("WallDebris")

local WallDebris = {}
local ScriptTrove = Trove.new()

local LOCAL_DEBRIS_COLLISION_GROUP = "LocalWallDebris"

local started = false
local folder = nil
local pool = {}
local activeDebris = {}
local nextToken = 0

local debrisConfig = WallConfig.ClientDebris or {}

local function randomBetween(minValue, maxValue)
	return minValue + (maxValue - minValue) * math.random()
end

local function randomSigned()
	return math.random() < 0.5 and -1 or 1
end

local function randomVectorBetween(minVector, maxVector)
	return Vector3.new(
		randomBetween(minVector.X, maxVector.X),
		randomBetween(minVector.Y, maxVector.Y),
		randomBetween(minVector.Z, maxVector.Z)
	)
end

local function ensureFolder()
	if folder and folder.Parent then
		return folder
	end

	folder = workspace:FindFirstChild("LocalWallDebris")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "LocalWallDebris"
		folder.Parent = workspace
		ScriptTrove:Add(folder)
	end

	return folder
end

local function setCollisionGroup(part)
	pcall(function()
		part.CollisionGroup = LOCAL_DEBRIS_COLLISION_GROUP
	end)
end

local function resetPart(part)
	if part:GetAttribute("DebrisToken") then
		part:SetAttribute("DebrisToken", nil)
	end

	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
	part.CFrame = CFrame.new(0, -10000, 0)
	part.Parent = ensureFolder()
	setCollisionGroup(part)
end

local function createPart()
	local part = Instance.new("Part")
	part.Name = "Local Wall Debris"
	resetPart(part)
	return part
end

local function getPart()
	local part = table.remove(pool)
	if not part or not part.Parent then
		part = createPart()
	end

	part.Transparency = 0
	return part
end

local function releaseActiveIndex(index)
	local debris = activeDebris[index]
	if not debris then
		return
	end

	table.remove(activeDebris, index)

	if debris.trove then
		debris.trove:Destroy()
		debris.trove = nil
	else
		if debris.tween then
			debris.tween:Cancel()
		end

		resetPart(debris.part)
		table.insert(pool, debris.part)
	end
end

local function releaseByToken(token)
	for index = #activeDebris, 1, -1 do
		local debris = activeDebris[index]
		if debris.token == token then
			releaseActiveIndex(index)
			return
		end
	end
end

local function recycleOldestIfNeeded()
	local maxActive = debrisConfig.MaxActive or 200
	while #activeDebris >= maxActive do
		releaseActiveIndex(1)
	end
end

local function getOutwardDirection(spawnPosition, wallCenter)
	local horizontalAway = Vector3.new(spawnPosition.X - wallCenter.X, 0, spawnPosition.Z - wallCenter.Z)
	if horizontalAway.Magnitude < 0.1 then
		horizontalAway = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	end

	local sideJitter = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	local mixed = horizontalAway.Unit + sideJitter * (debrisConfig.SideJitter or 0.35)
	if mixed.Magnitude < 0.1 then
		return horizontalAway.Unit
	end

	return mixed.Unit
end

local function getWallFaceNormal(wallCFrame, hitLocal)
	local faceSign = hitLocal.Z >= 0 and 1 or -1
	return wallCFrame:VectorToWorldSpace(Vector3.new(0, 0, faceSign)).Unit
end

local function getAngularVelocity()
	local angularMin = debrisConfig.AngularSpeedMin or 2
	local angularMax = debrisConfig.AngularSpeedMax or 6
	return Vector3.new(
		randomBetween(angularMin, angularMax) * randomSigned(),
		randomBetween(angularMin, angularMax) * randomSigned(),
		randomBetween(angularMin, angularMax) * randomSigned()
	)
end

local function scheduleRelease(debris)
	local lifetime = debrisConfig.Lifetime or WallConfig.DebrisLifetime or 3
	local fadeDuration = debrisConfig.FadeDuration or 0.75
	local fadeDelay = math.max(lifetime - fadeDuration, 0)
	local shrinkScale = debrisConfig.ShrinkScale or 0.15
	local token = debris.token
	local part = debris.part

	debris.trove:Add(task.delay(fadeDelay, function()
		if part:GetAttribute("DebrisToken") ~= token then
			return
		end

		local tween = TweenService:Create(part, TweenInfo.new(fadeDuration), {
			Size = debris.originalSize * shrinkScale,
			Transparency = 1,
		})
		debris.tween = tween
		debris.trove:Add(tween)
		tween:Play()
	end))

	debris.trove:Add(task.delay(lifetime, function()
		if part:GetAttribute("DebrisToken") == token then
			releaseByToken(token)
		end
	end))
end

local function preparePhysicsPart(part, spawnCFrame)
	part.CFrame = spawnCFrame
	part.Anchored = false
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 0
	part.CustomPhysicalProperties = PhysicalProperties.new(
		debrisConfig.Density or 0.7,
		debrisConfig.Friction or 0.55,
		debrisConfig.Elasticity or 0.35,
		debrisConfig.FrictionWeight or 1,
		debrisConfig.ElasticityWeight or 1
	)
	setCollisionGroup(part)
end

local function spawnPiece(payload)
	local wallCFrame = payload.wallCFrame
	local wallSize = payload.wallSize
	local hitPosition = payload.hitPosition or wallCFrame.Position
	local wallCenter = wallCFrame.Position
	local hitLocal = wallCFrame:PointToObjectSpace(hitPosition)
	local spread = debrisConfig.SpawnSpread or 0.75

	local randomLocal = Vector3.new(
		(math.random() - 0.5) * wallSize.X * spread,
		(math.random() - 0.35) * wallSize.Y * spread,
		(math.random() - 0.5) * wallSize.Z * spread
	)
	local spawnLocal = hitLocal:Lerp(randomLocal, debrisConfig.SpawnRandomWeight or 0.75)
	local spawnPosition = wallCFrame:PointToWorldSpace(spawnLocal)
	local initialRotation = CFrame.Angles(
		math.rad(math.random(0, 360)),
		math.rad(math.random(0, 360)),
		math.rad(math.random(0, 360))
	)

	recycleOldestIfNeeded()

	local part = getPart()
	part.Name = tostring(payload.displayName or "Wall") .. " Local Debris"
	part.Size = randomVectorBetween(
		debrisConfig.MinSize or Vector3.new(2.8, 1.8, 2.8),
		debrisConfig.MaxSize or Vector3.new(5.2, 3.4, 5.2)
	)
	part.Color = payload.color or Color3.fromRGB(180, 180, 180)
	part.Material = payload.material or Enum.Material.Plastic
	spawnPosition += getWallFaceNormal(wallCFrame, hitLocal) * (part.Size.Z * 0.5 + (debrisConfig.SpawnForwardOffset or 1.5))

	nextToken += 1
	local token = nextToken
	part:SetAttribute("DebrisToken", token)
	preparePhysicsPart(part, CFrame.new(spawnPosition) * initialRotation)

	local outward = getOutwardDirection(spawnPosition, wallCenter)
	local linearSpeed = randomBetween(debrisConfig.LinearSpeedMin or 5, debrisConfig.LinearSpeedMax or 12)
	local upwardSpeed = randomBetween(debrisConfig.UpwardSpeedMin or 18, debrisConfig.UpwardSpeedMax or 28)
	part.AssemblyLinearVelocity = outward * linearSpeed + Vector3.new(0, upwardSpeed, 0)
	part.AssemblyAngularVelocity = getAngularVelocity()

	local debris = {
		part = part,
		token = token,
		tween = nil,
		originalSize = part.Size,
		trove = Trove.new(),
	}

	debris.trove:Add(function()
		if debris.tween then
			debris.tween:Cancel()
			debris.tween = nil
		end

		resetPart(part)
		table.insert(pool, part)
	end)

	table.insert(activeDebris, debris)
	scheduleRelease(debris)
end

local function onWallDebris(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if typeof(payload.wallCFrame) ~= "CFrame" or typeof(payload.wallSize) ~= "Vector3" then
		return
	end

	if payload.wall and payload.wall:IsA("BasePart") then
		payload.wall.CanCollide = false
	end

	local count = math.clamp(payload.count or debrisConfig.NormalCount or 35, 0, debrisConfig.MaxActive or 200)
	for _ = 1, count do
		spawnPiece(payload)
	end
end

function WallDebris.Start()
	if started then
		return
	end
	started = true

	ensureFolder()
	ScriptTrove:Connect(wallDebrisRemote.OnClientEvent, onWallDebris)
	print("Wall debris client ready")
end

return WallDebris

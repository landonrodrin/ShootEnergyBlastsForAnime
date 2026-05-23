return function(ctx)
	local ReplicatedStorage = ctx.ReplicatedStorage
	local PhysicsService = ctx.PhysicsService
	local ServerStorage = ctx.ServerStorage
	local Players = ctx.Players
	local PlayersModule = ctx.PlayersModule
	local SetProperties = ctx.SetProperties
	local Grounding = ctx.Grounding
	local FinishBarrier = ctx.FinishBarrier
	local PathUtils = ctx.PathUtils
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local AreasConfigurations = ctx.AreasConfigurations
	local ThingsConfigurations = ctx.ThingsConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RetrieveThingDataFunction = ctx.RetrieveThingDataFunction
	local CreateThingFunction = ctx.CreateThingFunction
	local AnimateThingEvent = ctx.AnimateThingEvent
	local DropEvent = ctx.DropEvent
	local Things = ctx.Things
	local ThingsData = ctx.ThingsData
	local FACING_TARGET_PATH = ctx.FACING_TARGET_PATH
	local DEFAULT_INITIAL_POPULATION = ctx.DEFAULT_INITIAL_POPULATION
	local DEFAULT_MAX_POPULATION = ctx.DEFAULT_MAX_POPULATION
	local DEFAULT_SPAWN_SPACING = ctx.DEFAULT_SPAWN_SPACING
	local DEFAULT_SPAWN_JITTER = ctx.DEFAULT_SPAWN_JITTER
	local DEFAULT_INITIAL_TIME_SCALE_MIN = ctx.DEFAULT_INITIAL_TIME_SCALE_MIN
	local DEFAULT_INITIAL_TIME_SCALE_MAX = ctx.DEFAULT_INITIAL_TIME_SCALE_MAX
	local DEFAULT_SPAWN_TIME_SCALE_MIN = ctx.DEFAULT_SPAWN_TIME_SCALE_MIN
	local DEFAULT_SPAWN_TIME_SCALE_MAX = ctx.DEFAULT_SPAWN_TIME_SCALE_MAX
	local THING_GUI_MAX_DISTANCE = ctx.THING_GUI_MAX_DISTANCE
	local THING_CARRY_HOLD_DURATION = ctx.THING_CARRY_HOLD_DURATION
	local PICK_UP_PROMPT_TEXT = ctx.PICK_UP_PROMPT_TEXT
	local CARRIED_THING_WELD_NAME = ctx.CARRIED_THING_WELD_NAME
	local CARRIED_FORWARD_OFFSET = ctx.CARRIED_FORWARD_OFFSET
	local CARRIED_BASE_VERTICAL_OFFSET = ctx.CARRIED_BASE_VERTICAL_OFFSET
	local CARRIED_STACK_PADDING = ctx.CARRIED_STACK_PADDING
	local CARRIED_PHYSICS_ATTRIBUTE_PREFIX = ctx.CARRIED_PHYSICS_ATTRIBUTE_PREFIX
	local getSpawnZone = ctx.getSpawnZone
	local getFacingTarget = ctx.getFacingTarget
	local getAreaThingConfiguration = ctx.getAreaThingConfiguration
	local getAreaThings = ctx.getAreaThings
	local getAreaThingCount = ctx.getAreaThingCount
	local canSpawnInArea = ctx.canSpawnInArea
	local getThingGui = ctx.getThingGui
	local refreshCarriedThingPositions = ctx.refreshCarriedThingPositions
	local getGridSpawnPosition = ctx.getGridSpawnPosition
	local getSpawnCFrame = ctx.getSpawnCFrame
local function getCandidateSpacing(AreaConfiguration, ThingConfiguration)
	return math.max(
		AreaConfiguration.SpawnSpacing or DEFAULT_SPAWN_SPACING,
		(ThingConfiguration.Distance or 0) * 3
	)
end

local function scoreSpawnCandidate(Area, AreaConfiguration, ThingConfiguration, Candidate)
	local Spacing = getCandidateSpacing(AreaConfiguration, ThingConfiguration)
	local RequiredSpacing = Spacing * 0.75
	local NearbyCount = 0
	local NearestDistance = math.huge

	for _, OtherThing in ipairs(getAreaThings(Area)) do
		local OtherConfiguration = getAreaThingConfiguration(OtherThing)
		if not OtherConfiguration then continue end

		local RequiredDistance = math.max(
			RequiredSpacing,
			(ThingConfiguration.Distance or 0) + (OtherConfiguration.Distance or 0)
		)
		local Delta = OtherThing.PrimaryPart.Position - Candidate
		local Distance = Vector2.new(Delta.X, Delta.Z).Magnitude

		if Distance < RequiredDistance then
			return nil
		end

		if Distance < Spacing * 1.5 then
			NearbyCount += 1
		end

		if Distance < NearestDistance then
			NearestDistance = Distance
		end
	end

	return NearbyCount * 1000 - NearestDistance
end

local function getGridSpawnPosition(Area, AreaConfiguration, ThingConfiguration, SpawnZone)
	local AreaCFrame = SpawnZone.CFrame
	local AreaSize = SpawnZone.Size
	local Spacing = getCandidateSpacing(AreaConfiguration, ThingConfiguration)
	local Jitter = math.min(AreaConfiguration.SpawnJitter or DEFAULT_SPAWN_JITTER, Spacing * 0.35)

	local Padding = math.max(ThingConfiguration.Distance or 0, 2)
	local HalfX = (AreaSize.X / 2) - Padding
	local HalfZ = (AreaSize.Z / 2) - Padding
	if HalfX <= 0 or HalfZ <= 0 then return end

	local Columns = math.max(1, math.floor((HalfX * 2) / Spacing))
	local Rows = math.max(1, math.floor((HalfZ * 2) / Spacing))

	local BestPosition
	local BestScore

	for Column = 1, Columns do
		for Row = 1, Rows do
			local LocalX = -HalfX + ((Column - 0.5) / Columns) * (HalfX * 2)
			local LocalZ = -HalfZ + ((Row - 0.5) / Rows) * (HalfZ * 2)

			LocalX += (math.random() - 0.5) * 2 * Jitter
			LocalZ += (math.random() - 0.5) * 2 * Jitter

			LocalX = math.clamp(LocalX, -HalfX, HalfX)
			LocalZ = math.clamp(LocalZ, -HalfZ, HalfZ)

			local Candidate = AreaCFrame:PointToWorldSpace(Vector3.new(LocalX, AreaSize.Y / 2, LocalZ))
			local Score = scoreSpawnCandidate(Area, AreaConfiguration, ThingConfiguration, Candidate)
			if Score and (not BestScore or Score < BestScore) then
				BestPosition = Candidate
				BestScore = Score
			end
		end
	end

	return BestPosition
end

local function getSpawnCFrame(Position, ThingConfiguration, SpawnZone)
	local SpawnPosition = Position
	local FacingTarget = getFacingTarget()

	if not FacingTarget then
		return CFrame.new(SpawnPosition)
	end

	local TargetPosition = Vector3.new(FacingTarget.Position.X, SpawnPosition.Y, FacingTarget.Position.Z)
	if (TargetPosition - SpawnPosition).Magnitude < 0.1 then
		return CFrame.new(SpawnPosition)
	end

	return CFrame.lookAt(SpawnPosition, TargetPosition)
end
	ctx.getCandidateSpacing = getCandidateSpacing
	ctx.scoreSpawnCandidate = scoreSpawnCandidate
	ctx.getGridSpawnPosition = getGridSpawnPosition
	ctx.getSpawnCFrame = getSpawnCFrame
end

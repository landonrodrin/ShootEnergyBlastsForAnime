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
function Things.Retrieve(Thing, Name)
	if not ThingsData[Thing] then return end

	if Name then
		return ThingsData[Thing][Name]
	else
		return ThingsData[Thing]
	end
end
end

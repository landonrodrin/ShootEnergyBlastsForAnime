local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local PlayersModule = require(ServerStorage.Modules:WaitForChild("Players"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local Grounding = require(ServerStorage.Modules:WaitForChild("Grounding"))
local FinishBarrier = require(ServerStorage.Modules:WaitForChild("FinishBarrier"))

local shared = ReplicatedStorage:WaitForChild("Shared")
local PathUtils = require(shared:WaitForChild("PathUtils"))

local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))

local ctx = {
	ReplicatedStorage = ReplicatedStorage,
	PhysicsService = PhysicsService,
	ServerStorage = ServerStorage,
	Players = Players,
	PlayersModule = PlayersModule,
	SetProperties = SetProperties,
	Grounding = Grounding,
	FinishBarrier = FinishBarrier,
	PathUtils = PathUtils,
	Format = Format,
	GameConfigurations = GameConfigurations,
	AreasConfigurations = AreasConfigurations,
	ThingsConfigurations = ThingsConfigurations,
	MutationsConfigurations = MutationsConfigurations,
	RetrieveThingDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveThingData"),
	CreateThingFunction = ServerStorage.Network.BindableFunctions:WaitForChild("CreateThing"),
	AnimateThingEvent = ServerStorage.Network.BindableEvents:WaitForChild("AnimateThing"),
	DropEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Drop"),
	Resources = script:WaitForChild("Resources"),
	Things = {},
	ThingsData = {},
	FACING_TARGET_PATH = {"Map", "Main Floor"},
	DEFAULT_INITIAL_POPULATION = 0,
	DEFAULT_MAX_POPULATION = math.huge,
	DEFAULT_SPAWN_SPACING = 18,
	DEFAULT_SPAWN_JITTER = 5,
	DEFAULT_INITIAL_TIME_SCALE_MIN = 0.3,
	DEFAULT_INITIAL_TIME_SCALE_MAX = 1,
	DEFAULT_SPAWN_TIME_SCALE_MIN = 0.3,
	DEFAULT_SPAWN_TIME_SCALE_MAX = 1,
	THING_GUI_MAX_DISTANCE = 50,
	THING_CARRY_HOLD_DURATION = 0.5,
	PICK_UP_PROMPT_TEXT = "Pick Up",
	CARRIED_THING_WELD_NAME = "CarriedThingWeld",
	CARRIED_FORWARD_OFFSET = 0,
	CARRIED_BASE_VERTICAL_OFFSET = 6,
	CARRIED_STACK_PADDING = 2.75,
	CARRIED_PHYSICS_ATTRIBUTE_PREFIX = "CarriedOriginal"
}

require(script:WaitForChild("State"))(ctx)
require(script:WaitForChild("AreaSpawning"))(ctx)
require(script:WaitForChild("Animation"))(ctx)
require(script:WaitForChild("Carry"))(ctx)
require(script:WaitForChild("Factory"))(ctx)
require(script:WaitForChild("Placement"))(ctx)
require(script:WaitForChild("SpawnedThing"))(ctx)

return ctx.Things
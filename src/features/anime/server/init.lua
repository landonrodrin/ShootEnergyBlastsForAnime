local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local PlayersModule = require(ServerStorage.Features.Players:WaitForChild("Server"))
local SharedModules = ServerStorage:WaitForChild("Shared")
local ServerNetwork = SharedModules:WaitForChild("Network")
local SetProperties = require(SharedModules:WaitForChild("SetProperties"))
local Grounding = require(SharedModules:WaitForChild("Grounding"))
local FinishBarrier = require(SharedModules:WaitForChild("FinishBarrier"))
local RequestGuard = require(SharedModules:WaitForChild("RequestGuard"))
local RequestPolicy = require(SharedModules:WaitForChild("RequestPolicy"))

local PathUtils = require(ReplicatedStorage.Shared.Util:WaitForChild("PathUtils"))
local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))

local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))
local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))

local ctx = {
	ReplicatedStorage = ReplicatedStorage,
	PhysicsService = PhysicsService,
	ServerStorage = ServerStorage,
	Players = Players,
	PlayersModule = PlayersModule,
	SetProperties = SetProperties,
	Grounding = Grounding,
	FinishBarrier = FinishBarrier,
	RequestGuard = RequestGuard,
	RequestPolicy = RequestPolicy,
	PathUtils = PathUtils,
	Trove = Trove,
	Format = Format,
	GameConfigurations = GameConfigurations,
	AreasConfigurations = AreasConfigurations,
	AnimeConfigurations = AnimeConfigurations,
	MutationsConfigurations = MutationsConfigurations,
	RetrieveAnimeDataFunction = ServerNetwork.BindableFunctions:WaitForChild("RetrieveAnimeData"),
	CreateAnimeFunction = ServerNetwork.BindableFunctions:WaitForChild("CreateAnime"),
	AnimateAnimeEvent = ServerNetwork.BindableEvents:WaitForChild("AnimateAnime"),
	Packets = Packets,
	Resources = script:WaitForChild("Resources"),
	Anime = {},
	AnimeData = {},
	SetupTrove = Trove.new(),
	FACING_TARGET_PATH = {"Map", "Main Floor"},
	DEFAULT_INITIAL_POPULATION = 0,
	DEFAULT_MAX_POPULATION = math.huge,
	DEFAULT_SPAWN_SPACING = 18,
	DEFAULT_SPAWN_JITTER = 5,
	DEFAULT_INITIAL_TIME_SCALE_MIN = 0.3,
	DEFAULT_INITIAL_TIME_SCALE_MAX = 1,
	DEFAULT_SPAWN_TIME_SCALE_MIN = 0.3,
	DEFAULT_SPAWN_TIME_SCALE_MAX = 1,
	ANIME_GUI_MAX_DISTANCE = 50,
	ANIME_CARRY_HOLD_DURATION = 0.5,
	PICK_UP_PROMPT_TEXT = "Pick Up",
	CARRIED_ANIME_WELD_NAME = "CarriedAnimeWeld",
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
require(script:WaitForChild("SpawnedAnime"))(ctx)

return ctx.Anime

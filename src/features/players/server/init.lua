local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local TextChatService = game:GetService("TextChatService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Bases = require(ServerStorage.Features.Bases:WaitForChild("Server"))
local SharedModules = ServerStorage:WaitForChild("Shared")
local ServerNetwork = SharedModules:WaitForChild("Network")
local SetProperties = require(SharedModules:WaitForChild("SetProperties"))
local ZoneTracker = require(SharedModules:WaitForChild("ZoneTracker"))
local RequestGuard = require(SharedModules:WaitForChild("RequestGuard"))
local RequestPolicy = require(SharedModules:WaitForChild("RequestPolicy"))
local PreviewTemplates = require(SharedModules:WaitForChild("PreviewTemplates"))
local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local ZonePlus = require(ReplicatedStorage.Shared.Packages:WaitForChild("ZonePlus"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))

local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local BaseConfigurations = require(ReplicatedStorage.Features.Bases.Shared:WaitForChild("BaseConfigurations"))
local UpgradesConfigurations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UpgradesConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("RebirthsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))

local ctx = {
	MarketplaceService = MarketplaceService,
	ReplicatedStorage = ReplicatedStorage,
	DataStoreService = DataStoreService,
	PhysicsService = PhysicsService,
	TextChatService = TextChatService,
	ServerStorage = ServerStorage,
	HttpService = HttpService,
	Players = Players,
	Bases = Bases,
	SetProperties = SetProperties,
	ZoneTracker = ZoneTracker,
	RequestGuard = RequestGuard,
	RequestPolicy = RequestPolicy,
	PreviewTemplates = PreviewTemplates,
	Trove = Trove,
	ZonePlus = ZonePlus,
	Format = Format,
	GameConfigurations = GameConfigurations,
	AnimeConfigurations = AnimeConfigurations,
	BaseConfigurations = BaseConfigurations,
	UpgradesConfigurations = UpgradesConfigurations,
	AreasConfigurations = AreasConfigurations,
	RebirthsConfigurations = RebirthsConfigurations,
	MutationsConfigurations = MutationsConfigurations,
	MoneyDataStore = DataStoreService:GetOrderedDataStore("Money"),
	SpeedDataStore = DataStoreService:GetOrderedDataStore("Speed"),
	PlayerDataStore = DataStoreService:GetDataStore("Player"),
	RetrieveAnimeDataFunction = ServerNetwork.BindableFunctions:WaitForChild("RetrieveAnimeData"),
	RetrievePlayerDataFunction = ServerNetwork.BindableFunctions:WaitForChild("RetrievePlayerData"),
	ReplacePlayerDataEvent = ServerNetwork.BindableEvents:WaitForChild("ReplacePlayerData"),
	CreateToolEvent = ServerNetwork.BindableEvents:WaitForChild("CreateTool"),
	Packets = Packets,
	Resources = script:WaitForChild("Resources"),
	PlayersData = {},
	PlayersModule = {},
	MoneyPerSecondLeaderstatUpdates = {},
	AdminCommandDebounces = {},
	FriendBonusPercents = {},
	FRIEND_BONUS_PER_FRIEND = 10,
	FRIEND_BONUS_MAX_PERCENT = 50,
	SELL_STATION_DISTANCE = 18,
	HOTBAR_MAX_SLOTS = 10,
	HELD_ANIME_GUI_MAX_DISTANCE = 50,
	PLAYER_SPAWN_BASE_NAME = "1",
	PLAYER_SPAWN_PART_NAME = "PlayerSpawn",
	PLAYER_SPAWN_VERTICAL_OFFSET = 4,
	HELD_ANIME_WELD_NAME = "HeldAnimeWeld",
	HELD_ANIME_SIDE_OFFSET = 1,
	HELD_ANIME_FORWARD_OFFSET = -1.55,
	HELD_ANIME_VERTICAL_OFFSET = 3.1,
	ADMIN_RICH_MONEY = 1000000000000000,
	ADMIN_FAST_SPEED = 250,
	BASE_PROGRESSION_VERSION = 3,
	LEGACY_BASE_LEVEL_TO_CURRENT = {
		[1] = 2,
		[2] = 4,
		[3] = 6,
		[4] = 8,
		[5] = 10
	}
}

require(script:WaitForChild("Inventory"))(ctx)
require(script:WaitForChild("AdminCommands"))(ctx)
require(script:WaitForChild("Stats"))(ctx)
require(script:WaitForChild("Persistence"))(ctx)
require(script:WaitForChild("Tools"))(ctx)
require(script:WaitForChild("Purchases"))(ctx)
require(script:WaitForChild("Lifecycle"))(ctx)

return ctx.PlayersModule

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local TextChatService = game:GetService("TextChatService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Bases = require(ServerStorage.Modules:WaitForChild("Bases"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local ZoneTracker = require(ServerStorage.Modules:WaitForChild("ZoneTracker"))
local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))

local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local BaseConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("BaseConfigurations"))
local UpgradesConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("UpgradesConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("RebirthsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))
local CommandsConfigurations = require(ServerStorage.Configurations.Modules:WaitForChild("CommandsConfigurations"))

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
	Format = Format,
	GameConfigurations = GameConfigurations,
	ThingsConfigurations = ThingsConfigurations,
	BaseConfigurations = BaseConfigurations,
	UpgradesConfigurations = UpgradesConfigurations,
	AreasConfigurations = AreasConfigurations,
	RebirthsConfigurations = RebirthsConfigurations,
	MutationsConfigurations = MutationsConfigurations,
	CommandsConfigurations = CommandsConfigurations,
	MoneyDataStore = DataStoreService:GetOrderedDataStore("Money"),
	SpeedDataStore = DataStoreService:GetOrderedDataStore("Speed"),
	PlayerDataStore = DataStoreService:GetDataStore("Player"),
	RetrieveThingDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveThingData"),
	RetrievePlayerDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrievePlayerData"),
	ReplacePlayerDataEvent = ServerStorage.Network.BindableEvents:WaitForChild("ReplacePlayerData"),
	CreateToolEvent = ServerStorage.Network.BindableEvents:WaitForChild("CreateTool"),
	MoneyEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Money"),
	SpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Speed"),
	CarryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Carry"),
	RebirthEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Rebirth"),
	AdminCommandEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("AdminCommand"),
	IncrementSpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("IncrementSpeed"),
	IncrementCarryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("IncrementCarry"),
	AnnouncementEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Announcement"),
	ToggleSpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("ToggleSpeed"),
	IndexEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Index"),
	AnimeUnlockedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("AnimeUnlocked"),
	InventorySyncEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("InventorySync"),
	SellInventoryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("SellInventory"),
	EquipInventoryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("EquipInventory"),
	UpdateHotbarSlotEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("UpdateHotbarSlot"),
	Resources = script:WaitForChild("Resources"),
	PlayersData = {},
	PlayersModule = {},
	HeldModels = {},
	HeldInventoryCarry = {},
	AdminCommandDebounces = {},
	SELL_STATION_DISTANCE = 18,
	HOTBAR_MAX_SLOTS = 10,
	HELD_THING_GUI_MAX_DISTANCE = 50,
	PLAYER_SPAWN_BASE_NAME = "1",
	PLAYER_SPAWN_PART_NAME = "PlayerSpawn",
	PLAYER_SPAWN_VERTICAL_OFFSET = 4,
	HELD_ANIME_WELD_NAME = "HeldAnimeWeld",
	HELD_ANIME_SIDE_OFFSET = 1,
	HELD_ANIME_FORWARD_OFFSET = -1.55,
	HELD_ANIME_VERTICAL_OFFSET = 3.1,
	ADMIN_RICH_MONEY = 1000000000000000,
	ADMIN_FAST_SPEED = 250,
	RESET_COMMAND_NAME = "OwnerResetCommand",
	RICH_COMMAND_NAME = "OwnerRichCommand",
	FAST_COMMAND_NAME = "OwnerFastCommand",
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
require(script:WaitForChild("HeldPreview"))(ctx)
require(script:WaitForChild("AdminCommands"))(ctx)
require(script:WaitForChild("Stats"))(ctx)
require(script:WaitForChild("Persistence"))(ctx)
require(script:WaitForChild("Tools"))(ctx)
require(script:WaitForChild("Purchases"))(ctx)
require(script:WaitForChild("Lifecycle"))(ctx)

return ctx.PlayersModule

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local Grounding = require(ServerStorage.Modules:WaitForChild("Grounding"))

local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local BaseConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("BaseConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("RebirthsConfigurations"))

local RetrieveThingDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveThingData")
local CreateThingFunction = ServerStorage.Network.BindableFunctions:WaitForChild("CreateThing")
local RetrievePlayerDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrievePlayerData")
local AnimateThingEvent = ServerStorage.Network.BindableEvents:WaitForChild("AnimateThing")
local ReplacePlayerDataEvent = ServerStorage.Network.BindableEvents:WaitForChild("ReplacePlayerData")
local CreateToolEvent = ServerStorage.Network.BindableEvents:WaitForChild("CreateTool")

local LevelEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Level")
local AnnouncementEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Announcement")

local ctx = {
	MarketplaceService = MarketplaceService,
	Players = Players,
	HttpService = HttpService,
	SetProperties = SetProperties,
	Grounding = Grounding,
	Format = Format,
	GameConfigurations = GameConfigurations,
	BaseConfigurations = BaseConfigurations,
	AreasConfigurations = AreasConfigurations,
	ThingsConfigurations = ThingsConfigurations,
	MutationsConfigurations = MutationsConfigurations,
	RebirthsConfigurations = RebirthsConfigurations,
	RetrieveThingDataFunction = RetrieveThingDataFunction,
	CreateThingFunction = CreateThingFunction,
	RetrievePlayerDataFunction = RetrievePlayerDataFunction,
	AnimateThingEvent = AnimateThingEvent,
	ReplacePlayerDataEvent = ReplacePlayerDataEvent,
	CreateToolEvent = CreateToolEvent,
	LevelEvent = LevelEvent,
	AnnouncementEvent = AnnouncementEvent,
	Resources = script:WaitForChild("Resources"),
	BASE_GUI_MAX_DISTANCE = 200,
	BASE_LEVEL_BIND_DELAY = 0.15,
	BASE_SLOT_PROMPT_HOLD_DURATION = 0.5,
	BASE_SLOT_PLACE_PROMPT_MAX_ACTIVATION_DISTANCE = 15,
	BASE_LEVEL_NAME = "BaseLevel",
	BASE_INFO_GUI_NAME = "BaseInfoGui",
	BASE_INFO_ANCHOR_NAME = "BaseInfoAnchor",
	FLOORS_FOLDER_NAME = "Floors",
	SLOTS_FOLDER_NAME = "Slots",
	SLOT_SPAWN_NAME = "Spawn",
	SLOT_LEVEL_NAME = "Level",
	SLOT_MONEY_NAME = "Money",
	PICK_UP_PROMPT_TEXT = "Pick Up",
	INSUFFICIENT_FUNDS_TEXT = "Insufficient Funds",
	INSUFFICIENT_FUNDS_COLOUR = Color3.fromRGB(255, 0, 0),
	BasesData = {},
	Bases = {}
}

require(script:WaitForChild("Slots"))(ctx)
require(script:WaitForChild("Economy"))(ctx)
require(script:WaitForChild("InfoGui"))(ctx)
require(script:WaitForChild("Leveling"))(ctx)
require(script:WaitForChild("State"))(ctx)
require(script:WaitForChild("SlotThings"))(ctx)
require(script:WaitForChild("SlotPrompts"))(ctx)

return ctx.Bases
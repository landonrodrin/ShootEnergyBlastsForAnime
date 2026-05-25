local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SharedModules = ServerStorage:WaitForChild("Shared")
local SetProperties = require(SharedModules:WaitForChild("SetProperties"))
local Grounding = require(SharedModules:WaitForChild("Grounding"))
local RequestGuard = require(SharedModules:WaitForChild("RequestGuard"))
local RequestPolicy = require(SharedModules:WaitForChild("RequestPolicy"))

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local BaseConfigurations = require(ReplicatedStorage.Features.Bases.Shared:WaitForChild("BaseConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))
local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Features.Shop.Shared:WaitForChild("RebirthsConfigurations"))

local RetrieveAnimeDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveAnimeData")
local CreateAnimeFunction = ServerStorage.Network.BindableFunctions:WaitForChild("CreateAnime")
local RetrievePlayerDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrievePlayerData")
local AnimateAnimeEvent = ServerStorage.Network.BindableEvents:WaitForChild("AnimateAnime")
local ReplacePlayerDataEvent = ServerStorage.Network.BindableEvents:WaitForChild("ReplacePlayerData")
local CreateToolEvent = ServerStorage.Network.BindableEvents:WaitForChild("CreateTool")

local ctx = {
	MarketplaceService = MarketplaceService,
	Players = Players,
	HttpService = HttpService,
	SetProperties = SetProperties,
	Grounding = Grounding,
	RequestGuard = RequestGuard,
	RequestPolicy = RequestPolicy,
	Trove = Trove,
	Packets = Packets,
	Format = Format,
	GameConfigurations = GameConfigurations,
	BaseConfigurations = BaseConfigurations,
	AreasConfigurations = AreasConfigurations,
	AnimeConfigurations = AnimeConfigurations,
	MutationsConfigurations = MutationsConfigurations,
	RebirthsConfigurations = RebirthsConfigurations,
	RetrieveAnimeDataFunction = RetrieveAnimeDataFunction,
	CreateAnimeFunction = CreateAnimeFunction,
	RetrievePlayerDataFunction = RetrievePlayerDataFunction,
	AnimateAnimeEvent = AnimateAnimeEvent,
	ReplacePlayerDataEvent = ReplacePlayerDataEvent,
	CreateToolEvent = CreateToolEvent,
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
	Bases = {},
	LevelRequestHandlers = {}
}

local function registerLevelRequest(Identifier, OwnerTrove, Callback)
	if not Identifier or not Callback then return end

	ctx.LevelRequestHandlers[Identifier] = Callback

	if OwnerTrove then
		OwnerTrove:Add(function()
			if ctx.LevelRequestHandlers[Identifier] == Callback then
				ctx.LevelRequestHandlers[Identifier] = nil
			end
		end)
	end
end

Packets.levelRequest.listen(function(Data, Player)
	local Identifier = Data and Data.Identifier
	if type(Identifier) ~= "string" then return end

	local Callback = Identifier and ctx.LevelRequestHandlers[Identifier]
	if not Callback then return end
	if not RequestGuard.Allow(Player, "levelRequest", RequestPolicy.Cooldowns.Level) then return end

	Callback(Player)
end)

ctx.registerLevelRequest = registerLevelRequest

require(script:WaitForChild("Slots"))(ctx)
require(script:WaitForChild("Economy"))(ctx)
require(script:WaitForChild("InfoGui"))(ctx)
require(script:WaitForChild("Leveling"))(ctx)
require(script:WaitForChild("State"))(ctx)
require(script:WaitForChild("SlotAnime"))(ctx)
require(script:WaitForChild("SlotPrompts"))(ctx)

return ctx.Bases

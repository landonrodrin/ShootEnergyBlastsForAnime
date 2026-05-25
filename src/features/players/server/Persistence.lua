return function(ctx)
	local MarketplaceService = ctx.MarketplaceService
	local ReplicatedStorage = ctx.ReplicatedStorage
	local DataStoreService = ctx.DataStoreService
	local PhysicsService = ctx.PhysicsService
	local TextChatService = ctx.TextChatService
	local ServerStorage = ctx.ServerStorage
	local HttpService = ctx.HttpService
	local Players = ctx.Players
	local Bases = ctx.Bases
	local SetProperties = ctx.SetProperties
	local ZoneTracker = ctx.ZoneTracker
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local AnimeConfigurations = ctx.AnimeConfigurations
	local BaseConfigurations = ctx.BaseConfigurations
	local UpgradesConfigurations = ctx.UpgradesConfigurations
	local AreasConfigurations = ctx.AreasConfigurations
	local RebirthsConfigurations = ctx.RebirthsConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local MoneyDataStore = ctx.MoneyDataStore
	local SpeedDataStore = ctx.SpeedDataStore
	local PlayerDataStore = ctx.PlayerDataStore
	local RetrieveAnimeDataFunction = ctx.RetrieveAnimeDataFunction
	local RetrievePlayerDataFunction = ctx.RetrievePlayerDataFunction
	local ReplacePlayerDataEvent = ctx.ReplacePlayerDataEvent
	local CreateToolEvent = ctx.CreateToolEvent
	local MoneyEvent = ctx.MoneyEvent
	local SpeedEvent = ctx.SpeedEvent
	local CarryEvent = ctx.CarryEvent
	local RebirthEvent = ctx.RebirthEvent
	local IncrementSpeedEvent = ctx.IncrementSpeedEvent
	local IncrementCarryEvent = ctx.IncrementCarryEvent
	local AnnouncementEvent = ctx.AnnouncementEvent
	local IndexEvent = ctx.IndexEvent
	local AnimeUnlockedEvent = ctx.AnimeUnlockedEvent
	local InventorySyncEvent = ctx.InventorySyncEvent
	local SellInventoryEvent = ctx.SellInventoryEvent
	local EquipInventoryEvent = ctx.EquipInventoryEvent
	local UpdateHotbarSlotEvent = ctx.UpdateHotbarSlotEvent
	local Packets = ctx.Packets
	local PlayersData = ctx.PlayersData
	local PlayersModule = ctx.PlayersModule
	local AdminCommandDebounces = ctx.AdminCommandDebounces
	local SELL_STATION_DISTANCE = ctx.SELL_STATION_DISTANCE
	local HOTBAR_MAX_SLOTS = ctx.HOTBAR_MAX_SLOTS
	local HELD_ANIME_GUI_MAX_DISTANCE = ctx.HELD_ANIME_GUI_MAX_DISTANCE
	local PLAYER_SPAWN_BASE_NAME = ctx.PLAYER_SPAWN_BASE_NAME
	local PLAYER_SPAWN_PART_NAME = ctx.PLAYER_SPAWN_PART_NAME
	local PLAYER_SPAWN_VERTICAL_OFFSET = ctx.PLAYER_SPAWN_VERTICAL_OFFSET
	local HELD_ANIME_WELD_NAME = ctx.HELD_ANIME_WELD_NAME
	local HELD_ANIME_SIDE_OFFSET = ctx.HELD_ANIME_SIDE_OFFSET
	local HELD_ANIME_FORWARD_OFFSET = ctx.HELD_ANIME_FORWARD_OFFSET
	local HELD_ANIME_VERTICAL_OFFSET = ctx.HELD_ANIME_VERTICAL_OFFSET
	local ADMIN_RICH_MONEY = ctx.ADMIN_RICH_MONEY
	local ADMIN_FAST_SPEED = ctx.ADMIN_FAST_SPEED
	local BASE_PROGRESSION_VERSION = ctx.BASE_PROGRESSION_VERSION
	local LEGACY_BASE_LEVEL_TO_CURRENT = ctx.LEGACY_BASE_LEVEL_TO_CURRENT
	local makeInventoryId = ctx.makeInventoryId
	local getRebirthMultiplier = ctx.getRebirthMultiplier
	local getToolSellValue = ctx.getToolSellValue
	local normalizeHotbarOrder = ctx.normalizeHotbarOrder
	local setHotbarSlot = ctx.setHotbarSlot
	local migrateBaseProgression = ctx.migrateBaseProgression
	local getBaseSlotCount = ctx.getBaseSlotCount
	local equipInventoryTool = ctx.equipInventoryTool
	local getInventorySnapshot = ctx.getInventorySnapshot
	local syncInventory = ctx.syncInventory
	local findToolDataById = ctx.findToolDataById
	local removeToolData = ctx.removeToolData
	local cleanupToolData = ctx.cleanupToolData
	local reconcileIndex = ctx.reconcileIndex
	local Promise = require(ReplicatedStorage.Shared.Packages:WaitForChild("Promise"))
	local PLAYER_DATA_SCHEMA_VERSION = 2
	local DATASTORE_MAX_ATTEMPTS = 4
	local DATASTORE_BASE_BACKOFF = 0.5
	local DATASTORE_MAX_BACKOFF = 4

	local function getMaxBaseLevel()
		local MaxLevel = 1
		for Level in pairs(BaseConfigurations) do
			if type(Level) == "number" then
				MaxLevel = math.max(MaxLevel, Level)
			end
		end

		return MaxLevel
	end

	local MAX_BASE_LEVEL = getMaxBaseLevel()

	local function clampNumber(Value, Default, Minimum, Maximum)
		Value = tonumber(Value)
		if not Value or Value ~= Value then
			return Default
		end

		if Minimum then
			Value = math.max(Value, Minimum)
		end

		if Maximum then
			Value = math.min(Value, Maximum)
		end

		return Value
	end

	local function clampInteger(Value, Default, Minimum, Maximum)
		return math.floor(clampNumber(Value, Default, Minimum, Maximum))
	end

	local function normalizeMutation(Mutation)
		if type(Mutation) == "string" and MutationsConfigurations[Mutation] then
			return Mutation
		end

		return "Default"
	end

	local function normalizeLevel(Name, Level)
		local AnimeConfiguration = AnimeConfigurations[Name]
		local Levels = AnimeConfiguration and AnimeConfiguration.Levels
		local MaxLevel = Levels and #Levels or 1

		return clampInteger(Level, 1, 1, math.max(MaxLevel, 1))
	end

	local function normalizeSlot(Slot)
		local SlotNumber = tonumber(Slot)
		if not SlotNumber or SlotNumber < 1 or SlotNumber % 1 ~= 0 then return end

		local MaxSlots = getBaseSlotCount(MAX_BASE_LEVEL)
		if SlotNumber > MaxSlots then return end

		return tostring(SlotNumber)
	end

	local function normalizeAnimeEntry(AnimeEntry)
		if type(AnimeEntry) ~= "table" then return end
		if type(AnimeEntry.Name) ~= "string" or not AnimeConfigurations[AnimeEntry.Name] then return end

		local Slot = normalizeSlot(AnimeEntry.Slot)
		if not Slot then return end

		return {
			Name = AnimeEntry.Name,
			Mutation = normalizeMutation(AnimeEntry.Mutation),
			Level = normalizeLevel(AnimeEntry.Name, AnimeEntry.Level),
			Slot = Slot
		}
	end

	local function normalizeToolEntry(ToolEntry, UsedIds)
		if type(ToolEntry) ~= "table" then return end
		if type(ToolEntry.Name) ~= "string" or not AnimeConfigurations[ToolEntry.Name] then return end

		local Id = type(ToolEntry.Id) == "string" and ToolEntry.Id ~= "" and ToolEntry.Id or nil
		if not Id or (UsedIds and UsedIds[Id]) then
			Id = makeInventoryId()
		end

		if UsedIds then
			UsedIds[Id] = true
		end

		return {
			Id = Id,
			Name = ToolEntry.Name,
			Mutation = normalizeMutation(ToolEntry.Mutation),
			Level = normalizeLevel(ToolEntry.Name, ToolEntry.Level)
		}
	end

	local function migrateBaseProgression(PlayerData, HasLoadedData)
		local SavedVersion = PlayerData.BaseProgressionVersion
		if not SavedVersion then
			SavedVersion = HasLoadedData and 1 or BASE_PROGRESSION_VERSION
		end

		if SavedVersion < 2 then
			PlayerData.Level = LEGACY_BASE_LEVEL_TO_CURRENT[PlayerData.Level] or PlayerData.Level or 1
		end

		if (PlayerData.Level or 0) < 1 then
			PlayerData.Level = 1
		end

		PlayerData.BaseProgressionVersion = BASE_PROGRESSION_VERSION
	end

	local function normalizePlayerData(PlayerData, HasLoadedData)
		PlayerData.Money = clampNumber(PlayerData.Money, GameConfigurations.Defaults.Money, 0)
		PlayerData.Speed = clampNumber(PlayerData.Speed, GameConfigurations.Defaults.Speed, 0, GameConfigurations.Maximums.Speed)
		PlayerData.Carry = clampInteger(PlayerData.Carry, GameConfigurations.Defaults.Carry, 1, GameConfigurations.Maximums.Carry)
		PlayerData.Level = clampInteger(PlayerData.Level, 1, 1, MAX_BASE_LEVEL)
		PlayerData.Steals = clampInteger(PlayerData.Steals, 0, 0)
		PlayerData.Rebirths = clampInteger(PlayerData.Rebirths, 0, 0)
		PlayerData.MoneyPerSecond = 0

		migrateBaseProgression(PlayerData, HasLoadedData)
		PlayerData.Level = clampInteger(PlayerData.Level, 1, 1, MAX_BASE_LEVEL)

		local Tools = {}
		local UsedToolIds = {}
		for _, ToolEntry in ipairs(type(PlayerData.Tools) == "table" and PlayerData.Tools or {}) do
			local NormalizedTool = normalizeToolEntry(ToolEntry, UsedToolIds)
			if NormalizedTool then
				table.insert(Tools, NormalizedTool)
			end
		end
		PlayerData.Tools = Tools

		local Anime = {}
		for _, AnimeEntry in ipairs(type(PlayerData.Anime) == "table" and PlayerData.Anime or {}) do
			local NormalizedAnime = normalizeAnimeEntry(AnimeEntry)
			if NormalizedAnime then
				table.insert(Anime, NormalizedAnime)
			end
		end
		PlayerData.Anime = Anime

		PlayerData.HotbarOrder = typeof(PlayerData.HotbarOrder) == "table" and PlayerData.HotbarOrder or {}
		normalizeHotbarOrder(PlayerData)
		PlayerData.Index = reconcileIndex(PlayerData.Index)
		PlayerData.SchemaVersion = PLAYER_DATA_SCHEMA_VERSION
	end

	local function datastoreBackoff(Attempt)
		local Delay = math.min(DATASTORE_BASE_BACKOFF * 2 ^ (Attempt - 1), DATASTORE_MAX_BACKOFF)
		return Delay + math.random() * 0.2
	end

	local function readDataStore(DataStore, UserId, Label)
		return Promise.try(function()
			local LastError
			for Attempt = 1, DATASTORE_MAX_ATTEMPTS do
				local Success, ValueOrError = pcall(function()
					return DataStore:GetAsync(UserId)
				end)

				if Success then
					return {
						Success = true,
						Value = ValueOrError
					}
				end

				LastError = ValueOrError
				if Attempt < DATASTORE_MAX_ATTEMPTS then
					task.wait(datastoreBackoff(Attempt))
				end
			end

			warn(string.format("Failed to load %s for user %s after %s attempts: %s", Label, tostring(UserId), DATASTORE_MAX_ATTEMPTS, tostring(LastError)))

			return {
				Success = false,
				Value = nil,
				Error = LastError
			}
		end)
	end

	local function writeDataStore(DataStore, UserId, Value, Label)
		return Promise.try(function()
			local LastError
			for Attempt = 1, DATASTORE_MAX_ATTEMPTS do
				local Success, Error = pcall(function()
					DataStore:SetAsync(UserId, Value)
				end)

				if Success then
					return true
				end

				LastError = Error
				if Attempt < DATASTORE_MAX_ATTEMPTS then
					task.wait(datastoreBackoff(Attempt))
				end
			end

			warn(string.format("Failed to save %s for user %s after %s attempts: %s", Label, tostring(UserId), DATASTORE_MAX_ATTEMPTS, tostring(LastError)))

			return false
		end)
	end

	local function serializeTools(PlayerData)
		local Tools = {}
		local UsedToolIds = {}
		for _, ToolData in ipairs(PlayerData.Tools or {}) do
			local NormalizedTool = normalizeToolEntry(ToolData, UsedToolIds)
			if NormalizedTool then
				table.insert(Tools, NormalizedTool)
			end
		end
		return Tools
	end

	local function serializeAnime(PlayerData)
		local Anime = {}
		for _, AnimeData in ipairs(PlayerData.Anime or {}) do
			local NormalizedAnime = normalizeAnimeEntry(AnimeData)
			if NormalizedAnime then
				table.insert(Anime, NormalizedAnime)
			end
		end
		return Anime
	end

	local function serializePlayerData(PlayerData)
		local Snapshot = {
			SchemaVersion = PLAYER_DATA_SCHEMA_VERSION,
			Carry = clampInteger(PlayerData.Carry, GameConfigurations.Defaults.Carry, 1, GameConfigurations.Maximums.Carry),
			Tools = serializeTools(PlayerData),
			Level = clampInteger(PlayerData.Level, 1, 1, MAX_BASE_LEVEL),
			Anime = serializeAnime(PlayerData),
			Steals = clampInteger(PlayerData.Steals, 0, 0),
			Rebirths = clampInteger(PlayerData.Rebirths, 0, 0),
			Index = reconcileIndex(PlayerData.Index),
			HotbarOrder = {},
			BaseProgressionVersion = PlayerData.BaseProgressionVersion or BASE_PROGRESSION_VERSION
		}

		Snapshot.HotbarOrder = normalizeHotbarOrder({
			Tools = Snapshot.Tools,
			HotbarOrder = PlayerData.HotbarOrder
		})

		return Snapshot
	end

	local function delayForPlayer(Player, Delay, Callback)
		Promise.delay(Delay):andThen(function()
			local PlayerData = PlayersData[Player]
			if not PlayerData then return end

			Callback(PlayerData)
		end):catch(function(Error)
			warn(string.format("Delayed player sync failed for %s: %s", Player.Name, tostring(Error)))
		end)
	end

	local function scheduleStartupSyncs(Player)
		delayForPlayer(Player, 1, function(PlayerData)
			Packets.money.sendTo(PlayerData.Money, Player)
		end)

		delayForPlayer(Player, 5, function(PlayerData)
			Packets.money.sendTo(PlayerData.Money, Player)
		end)

		delayForPlayer(Player, 1, function(PlayerData)
			Packets.speed.sendTo(PlayerData.Speed, Player)
		end)

		delayForPlayer(Player, 5, function(PlayerData)
			Packets.speed.sendTo(PlayerData.Speed, Player)
		end)

		delayForPlayer(Player, 1, function(PlayerData)
			Packets.rebirth.sendTo({
				Rebirths = PlayerData.Rebirths,
				Speed = PlayerData.Speed,
			}, Player)
		end)

		delayForPlayer(Player, 5, function(PlayerData)
			Packets.rebirth.sendTo({
				Rebirths = PlayerData.Rebirths,
				Speed = PlayerData.Speed,
			}, Player)
		end)

		delayForPlayer(Player, 1, function(PlayerData)
			Packets.carry.sendTo(PlayerData.Carry, Player)
		end)

		delayForPlayer(Player, 5, function(PlayerData)
			Packets.carry.sendTo(PlayerData.Carry, Player)
		end)

		delayForPlayer(Player, 1, function()
			syncInventory(Player)
		end)

		delayForPlayer(Player, 5, function()
			syncInventory(Player)
		end)
	end

	local function isInventoryTool(Tool)
		return Tool:IsA("Tool") and (Tool:GetAttribute("InventoryId") or AnimeConfigurations[Tool.Name])
	end

	local function destroyInventoryTools(Container)
		if not Container then return end

		for _, Child in ipairs(Container:GetChildren()) do
			if isInventoryTool(Child) then
				Child:Destroy()
			end
		end
	end

	local function prepareInventoryTools(Player)
		return Promise.try(function()
			local PlayerData = PlayersData[Player]
			if not PlayerData then return {} end

			local Backpack = Player:WaitForChild("Backpack")
			local Character = Player.Character

			Player:SetAttribute("HoldState", nil)

			destroyInventoryTools(Backpack)
			destroyInventoryTools(Character)

			PlayerData.Tools = PlayerData.Tools or {}

			for Index = #PlayerData.Tools, 1, -1 do
				local ToolData = PlayerData.Tools[Index]
				local Anime = type(ToolData) == "table" and ToolData.Name or nil

				if not Anime or not AnimeConfigurations[Anime] then
					cleanupToolData(ToolData)
					table.remove(PlayerData.Tools, Index)
				else
					cleanupToolData(ToolData)
					ToolData.Id = ToolData.Id or makeInventoryId()
					ToolData.Tool = nil
					ToolData.HeldModel = nil
					ToolData.Trove = nil
					PlayerData.Tools[Index] = ToolData
				end
			end

			normalizeHotbarOrder(PlayerData)

			local RecreationPromises = {}
			for Index, ToolData in ipairs(PlayerData.Tools) do
				table.insert(RecreationPromises, Promise.try(function()
					local Anime = ToolData.Name
					local AnimeConfiguration = AnimeConfigurations[Anime]

					PlayersModule.Tool(Player, Anime, AnimeConfiguration, ToolData.Mutation, ToolData.Level, Index, ToolData, nil, true)
				end):catch(function(Error)
					warn(string.format("Failed to recreate inventory tool for %s: %s", Player.Name, tostring(Error)))
				end))
			end

			return Promise.all(RecreationPromises)
		end):andThen(function()
			if PlayersData[Player] then
				normalizeHotbarOrder(PlayersData[Player])
				syncInventory(Player)
			end
		end)
	end

	local function setupToolRecreation(Player)
		Promise.try(function()
			local PlayerData = PlayersData[Player]
			if not PlayerData then return end
			local PlayerTrove = PlayerData.Trove
			if not PlayerTrove then return end

			PlayerTrove:Connect(Player.CharacterAdded, function()
				task.wait()

				local CurrentPlayerData = PlayersData[Player]
				if not CurrentPlayerData then return end

				prepareInventoryTools(Player):catch(function(Error)
					warn(string.format("Failed to prepare respawn inventory for %s: %s", Player.Name, tostring(Error)))
				end)
			end)

			PlayerTrove:Connect(Player.CharacterRemoving, function()
				Player:SetAttribute("HoldState", nil)
				task.defer(syncInventory, Player)
			end)
		end):catch(function(Error)
			warn(string.format("Failed to set up inventory tools for %s: %s", Player.Name, tostring(Error)))
		end)
	end

	function PlayersModule:Load()
		local Player = self.Player
		local UserId = Player.UserId

		local _, Results = Promise.all({
			readDataStore(MoneyDataStore, UserId, "Money"),
			readDataStore(SpeedDataStore, UserId, "Speed"),
			readDataStore(PlayerDataStore, UserId, "PlayerData")
		}):await()

		local MoneyResult = Results and Results[1] or {}
		local SpeedResult = Results and Results[2] or {}
		local PlayerDataResult = Results and Results[3] or {}
		self.UnsafeSaveStores = {}

		if MoneyResult.Success and MoneyResult.Value then
			self.Money = MoneyResult.Value
		else
			self.Money = GameConfigurations.Defaults.Money
			self.UnsafeSaveStores.Money = MoneyResult.Success == false
		end

		if SpeedResult.Success and SpeedResult.Value then
			self.Speed = SpeedResult.Value
		else
			self.Speed = GameConfigurations.Defaults.Speed
			self.UnsafeSaveStores.Speed = SpeedResult.Success == false
		end

		if PlayerDataResult.Success and PlayerDataResult.Value then
			for Name, Value in pairs(PlayerDataResult.Value) do
				self[Name] = Value
			end
		elseif PlayerDataResult.Success == false then
			self.UnsafeSaveStores.PlayerData = true
		end

		normalizePlayerData(self, PlayerDataResult.Success and PlayerDataResult.Value ~= nil)
		PlayersData[Player] = self

		local Prepared, PrepareError = prepareInventoryTools(Player):await()
		if not Prepared then
			warn(string.format("Failed to prepare inventory tools for %s: %s", Player.Name, tostring(PrepareError)))
		end

		scheduleStartupSyncs(Player)
		setupToolRecreation(Player)

		if UpgradesConfigurations.Speed1.ProductId ~= 3525676618 and math.random() > 0.5 then
			UpgradesConfigurations.Speed1.ProductId = 3525676618
		end

		if UpgradesConfigurations.Speed10.ProductId ~= 3525677009 and math.random() > 0.5 then
			UpgradesConfigurations.Speed10.ProductId = 3525677009
		end

		if UpgradesConfigurations.Carry1.ProductId ~= 3525677349 and math.random() > 0.5 then
			UpgradesConfigurations.Carry1.ProductId = 3525677349
		end
	end

	function PlayersModule:Save()
		return self:QueueSave("direct")
	end

	function PlayersModule:QueueSave(Reason)
		if self.SaveRunning then
			self.SaveQueued = true
			self.SaveReasons = self.SaveReasons or {}
			table.insert(self.SaveReasons, Reason or "queued")

			while self.SaveRunning do
				task.wait()
			end

			return self.LastSaveSuccess == true
		end

		self.SaveRunning = true
		self.SaveQueued = true
		self.LastSaveSuccess = false

		local OverallSuccess = true
		while self.SaveQueued do
			self.SaveQueued = false
			self.SaveReasons = {}

			local Ok, SuccessOrError = pcall(function()
				return self:PerformSave()
			end)
			local Success = Ok and SuccessOrError == true
			if not Ok then
				warn(string.format("Failed to save player data for user %s: %s", tostring(self.Player and self.Player.UserId), tostring(SuccessOrError)))
			end

			OverallSuccess = OverallSuccess and Success
			self.LastSaveSuccess = Success
		end

		self.SaveRunning = false
		return OverallSuccess
	end

	function PlayersModule:PerformSave()
		local Player = self.Player
		local UserId = Player.UserId
		local UnsafeSaveStores = self.UnsafeSaveStores or {}
		local PlayerSnapshot = serializePlayerData(self)
		local Writes = {}

		if not UnsafeSaveStores.Money then
			table.insert(Writes, writeDataStore(MoneyDataStore, UserId, clampNumber(self.Money, GameConfigurations.Defaults.Money, 0), "Money"))
		end

		if not UnsafeSaveStores.Speed then
			table.insert(Writes, writeDataStore(SpeedDataStore, UserId, clampNumber(self.Speed, GameConfigurations.Defaults.Speed, 0, GameConfigurations.Maximums.Speed), "Speed"))
		end

		if not UnsafeSaveStores.PlayerData then
			table.insert(Writes, writeDataStore(PlayerDataStore, UserId, PlayerSnapshot, "PlayerData"))
		end

		if #Writes == 0 then
			warn(string.format("Skipped saving all stores for user %s because every store was unsafe this session.", tostring(UserId)))
			return false
		end

		local AwaitSuccess, Results = Promise.all(Writes):await()
		if not AwaitSuccess then
			warn(string.format("Failed to save player data for user %s: %s", tostring(UserId), tostring(Results)))
			return false
		end

		local Success = true
		for _, Result in ipairs(Results or {}) do
			if Result ~= true then
				Success = false
			end
		end

		return Success
	end

	function PlayersModule:DestroySession()
		if self.SessionDestroyed then return end
		self.SessionDestroyed = true

		local Player = self.Player

		for _, ToolData in ipairs(self.Tools or {}) do
			cleanupToolData(ToolData)
		end

		if PlayersData[Player] and PlayersData[Player].Base then
			Bases.Destroy(PlayersData[Player].Base)
		end

		if self.Trove then
			self.Trove:Destroy()
			self.Trove = nil
		end

		PlayersData[Player] = nil
	end

	ctx.migrateBaseProgression = migrateBaseProgression
	ctx.normalizePlayerData = normalizePlayerData
	ctx.serializePlayerData = serializePlayerData
end

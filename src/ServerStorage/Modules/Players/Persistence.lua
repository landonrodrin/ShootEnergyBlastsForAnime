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
	local CommandsConfigurations = ctx.CommandsConfigurations
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
	local ToggleSpeedEvent = ctx.ToggleSpeedEvent
	local IndexEvent = ctx.IndexEvent
	local AnimeUnlockedEvent = ctx.AnimeUnlockedEvent
	local InventorySyncEvent = ctx.InventorySyncEvent
	local SellInventoryEvent = ctx.SellInventoryEvent
	local EquipInventoryEvent = ctx.EquipInventoryEvent
	local UpdateHotbarSlotEvent = ctx.UpdateHotbarSlotEvent
	local Packets = ctx.Packets
	local PlayersData = ctx.PlayersData
	local PlayersModule = ctx.PlayersModule
	local HeldModels = ctx.HeldModels
	local HeldInventoryCarry = ctx.HeldInventoryCarry
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
	local createHeldModel = ctx.createHeldModel
	local removeHeldModel = ctx.removeHeldModel
	local equipInventoryTool = ctx.equipInventoryTool
	local getInventorySnapshot = ctx.getInventorySnapshot
	local syncInventory = ctx.syncInventory
	local findToolDataById = ctx.findToolDataById
	local removeToolData = ctx.removeToolData
	local cleanupToolData = ctx.cleanupToolData
	local reconcileIndex = ctx.reconcileIndex
	local Promise = require(ReplicatedStorage.Shared:WaitForChild("Promise"))

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

	local function readDataStore(DataStore, UserId, Label)
		return Promise.try(function()
			return DataStore:GetAsync(UserId)
		end):andThen(function(Value)
			return {
				Success = true,
				Value = Value
			}
		end):catch(function(Error)
			warn(string.format("Failed to load %s for user %s: %s", Label, tostring(UserId), tostring(Error)))

			return {
				Success = false,
				Value = nil
			}
		end)
	end

	local function writeDataStore(DataStore, UserId, Value, Label)
		return Promise.try(function()
			DataStore:SetAsync(UserId, Value)
		end):andThen(function()
			return true
		end):catch(function(Error)
			warn(string.format("Failed to save %s for user %s: %s", Label, tostring(UserId), tostring(Error)))

			return false
		end)
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

			if ctx.removeHeldModel then
				ctx.removeHeldModel(Player)
			end

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
				if ctx.removeHeldModel then
					ctx.removeHeldModel(Player)
				end
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

		if MoneyResult.Success and MoneyResult.Value then
			self.Money = MoneyResult.Value
		else
			self.Money = GameConfigurations.Defaults.Money
		end

		if SpeedResult.Success and SpeedResult.Value then
			self.Speed = SpeedResult.Value
		else
			self.Speed = GameConfigurations.Defaults.Speed
		end

		if PlayerDataResult.Success and PlayerDataResult.Value then
			for Name, Value in pairs(PlayerDataResult.Value) do
				self[Name] = Value
			end
		end

		self.MoneyPerSecond = 0

		if not self.Carry then self.Carry = GameConfigurations.Defaults.Carry end
		if not self.Tools then self.Tools = {} end
		if not self.Level then self.Level = 1 end
		if not self.Anime then self.Anime = {} end
		if not self.Steals then self.Steals = 0 end
		if not self.Rebirths then self.Rebirths = 0 end
		if not self.HotbarOrder then self.HotbarOrder = {} end

		migrateBaseProgression(self, PlayerDataResult.Success and PlayerDataResult.Value ~= nil)

		for Index = #self.Tools, 1, -1 do
			local ToolConfiguration = self.Tools[Index]
			if AnimeConfigurations[ToolConfiguration.Name] then
				ToolConfiguration.Id = ToolConfiguration.Id or makeInventoryId()
				self.Tools[Index] = ToolConfiguration
			else
				table.remove(self.Tools, Index)
			end
		end

		normalizeHotbarOrder(self)

		for Index = #self.Anime, 1, -1 do
			local AnimeConfiguration = self.Anime[Index]
			if AnimeConfigurations[AnimeConfiguration.Name] then continue end

			table.remove(self.Anime, Index)
		end

		self.Index = reconcileIndex(self.Index)
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
		local Player = self.Player
		local UserId = Player.UserId

		for Index, ToolData in ipairs(self.Tools) do
			if type(ToolData) == "table" then
				cleanupToolData(ToolData)
				ToolData.Id = ToolData.Id or makeInventoryId()
				ToolData.Tool = nil
				ToolData.HeldModel = nil
				ToolData.Trove = nil

				self.Tools[Index] = ToolData
			end
		end

		normalizeHotbarOrder(self)

		local Data = {
			Carry = self.Carry,
			Tools = self.Tools,
			Level = self.Level,
			Anime = self.Anime,
			Steals = self.Steals,
			Rebirths = self.Rebirths,
			Index = self.Index,
			HotbarOrder = self.HotbarOrder,
			BaseProgressionVersion = self.BaseProgressionVersion
		}

		Promise.all({
			writeDataStore(MoneyDataStore, UserId, self.Money, "Money"),
			writeDataStore(SpeedDataStore, UserId, self.Speed, "Speed"),
			writeDataStore(PlayerDataStore, UserId, Data, "PlayerData")
		}):await()

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
end

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
	local reconcileIndex = ctx.reconcileIndex
	local PendingInventorySync = {}
local function makeInventoryId()
	return HttpService:GenerateGUID(false)
end
local function getRebirthMultiplier(Rebirths)
	local RebirthConfiguration = RebirthsConfigurations[Rebirths]
	return RebirthConfiguration and RebirthConfiguration.Multiplier or 1
end

local function getToolSellValue(Name, Mutation, Level, Rebirths)
	local AnimeConfiguration = AnimeConfigurations[Name]
	if not AnimeConfiguration then return 0 end

	local LevelConfiguration = AnimeConfiguration.Levels[Level or 1]
	if not LevelConfiguration then return 0 end

	local MutationConfiguration = MutationsConfigurations[Mutation] or {}
	local Multiplier = MutationConfiguration.Multiplier or 1
	local RebirthMultiplier = getRebirthMultiplier(Rebirths)

	return math.round(((LevelConfiguration.Money or 0) * Multiplier * RebirthMultiplier) / 2)
end

local function normalizeHotbarOrder(PlayerData)
	if not PlayerData then return {} end

	local Tools = PlayerData.Tools or {}
	local OwnedIds = {}

	for _, ToolData in ipairs(Tools) do
		if AnimeConfigurations[ToolData.Name] then
			ToolData.Id = ToolData.Id or makeInventoryId()
			OwnedIds[ToolData.Id] = true
		end
	end

	local ExistingOrder = typeof(PlayerData.HotbarOrder) == "table" and PlayerData.HotbarOrder or {}
	local UsedIds = {}
	local Order = table.create(HOTBAR_MAX_SLOTS)

	for Slot = 1, HOTBAR_MAX_SLOTS do
		local Id = ExistingOrder[Slot]
		if Id and OwnedIds[Id] and not UsedIds[Id] then
			Order[Slot] = Id
			UsedIds[Id] = true
		end
	end

	for _, ToolData in ipairs(Tools) do
		local Id = ToolData.Id
		if not Id or UsedIds[Id] or not OwnedIds[Id] then continue end

		for Slot = 1, HOTBAR_MAX_SLOTS do
			if Order[Slot] then continue end

			Order[Slot] = Id
			UsedIds[Id] = true
			break
		end
	end

	PlayerData.HotbarOrder = Order

	return Order
end

local function setHotbarSlot(PlayerData, Slot, Id)
	if not PlayerData then return false end

	Slot = tonumber(Slot)
	if not Slot or Slot < 1 or Slot > HOTBAR_MAX_SLOTS or Slot % 1 ~= 0 then return false end

	local Owned = false
	if Id then
		for _, ToolData in ipairs(PlayerData.Tools or {}) do
			if ToolData.Id ~= Id then continue end

			Owned = true
			break
		end

		if not Owned then return false end
	end

	local Order = normalizeHotbarOrder(PlayerData)
	local ReplacedId = Order[Slot]

	for Index = 1, HOTBAR_MAX_SLOTS do
		if Order[Index] == Id or (Id == nil and Index == Slot) then
			Order[Index] = nil
		end
	end

	Order[Slot] = Id

	if Id and ReplacedId and ReplacedId ~= Id then
		for Index = 1, HOTBAR_MAX_SLOTS do
			if Order[Index] then continue end

			Order[Index] = ReplacedId
			break
		end
	end

	PlayerData.HotbarOrder = Order

	return true
end
local function getBaseSlotCount(Level)
	local Configuration = BaseConfigurations[Level] or BaseConfigurations[1] or {}
	return Configuration.Slots or 0
end
local function equipInventoryTool(Player, ToolData)
	if not ToolData or not ToolData.Tool then return false end

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return false end

	ToolData.Tool.Parent = Player:WaitForChild("Backpack")
	Humanoid:EquipTool(ToolData.Tool)

	return true
end

local function cleanupToolData(ToolData)
	if type(ToolData) ~= "table" then return end

	local Tool = ToolData.Tool
	local ToolTrove = ToolData.Trove
	if type(ToolTrove) == "table" and type(ToolTrove.Destroy) == "function" then
		ToolTrove:Destroy()
	end

	if typeof(Tool) == "Instance" then
		Tool:Destroy()
	end

	ToolData.Trove = nil
	ToolData.Tool = nil
	ToolData.HeldModel = nil
end

local function getInventorySnapshot(Player)
	local PlayerData = PlayersData[Player]
	local Snapshot = {
		Items = {},
		EquippedId = nil,
		HotbarOrder = {},
		MaxHotbarSlots = HOTBAR_MAX_SLOTS
	}

	if not PlayerData then return Snapshot end

	Snapshot.HotbarOrder = normalizeHotbarOrder(PlayerData)

	local Character = Player.Character
	local EquippedTool = Character and Character:FindFirstChildOfClass("Tool")

	for _, ToolData in ipairs(PlayerData.Tools or {}) do
		if not AnimeConfigurations[ToolData.Name] then continue end

		if not ToolData.Id then
			ToolData.Id = makeInventoryId()
		end

		if EquippedTool and ToolData.Tool == EquippedTool then
			Snapshot.EquippedId = ToolData.Id
		end

		table.insert(Snapshot.Items, {
			Id = ToolData.Id,
			Name = ToolData.Name,
			Mutation = ToolData.Mutation,
			Level = ToolData.Level or 1,
			Sell = getToolSellValue(ToolData.Name, ToolData.Mutation, ToolData.Level or 1, PlayerData.Rebirths)
		})
	end

	return Snapshot
end

local function syncInventory(Player)
	if not PlayersData[Player] then return end

	Packets.inventorySync.sendTo(Packets.EncodeInventorySnapshot(getInventorySnapshot(Player)), Player)
end

local function queueInventorySync(Player)
	if not PlayersData[Player] or PendingInventorySync[Player] then return end

	PendingInventorySync[Player] = true
	task.defer(function()
		PendingInventorySync[Player] = nil
		syncInventory(Player)
	end)
end

local function getEquippedInventoryTool(Player)
	local Character = Player.Character
	local Tool = Character and Character:FindFirstChildOfClass("Tool")
	if not Tool then return end
	if not Tool:GetAttribute("InventoryId") and not AnimeConfigurations[Tool.Name] then return end

	return Tool
end

local function clearEquippedInventoryTool(Player)
	local Tool = getEquippedInventoryTool(Player)
	if Tool then
		local Character = Player.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid:UnequipTools()
		else
			local Backpack = Player:FindFirstChildOfClass("Backpack")
			if Backpack then
				Tool.Parent = Backpack
			end
		end
	end

	if Player:GetAttribute("HoldState") == "Inventory" then
		Player:SetAttribute("HoldState", nil)
	end

	queueInventorySync(Player)
end

local function findToolDataById(Player, Id)
	local PlayerData = PlayersData[Player]
	if not PlayerData or not Id then return end

	for Index, ToolData in ipairs(PlayerData.Tools or {}) do
		if ToolData.Id == Id then
			return Index, ToolData
		end
	end
end

local function removeToolData(Player, Index, ToolData, SkipSync)
	local Character = Player.Character
	if ToolData and typeof(ToolData.Tool) == "Instance" and ToolData.Tool.Parent == Character then
		clearEquippedInventoryTool(Player)
	end

	cleanupToolData(ToolData)

	local PlayerData = PlayersData[Player]
	if not PlayerData then return end

	table.remove(PlayerData.Tools, Index)
	normalizeHotbarOrder(PlayerData)

	if not SkipSync then
		syncInventory(Player)
	end
end

local function reconcileIndex(ExistingIndex)
	local Index = {}

	for Mutation in pairs(MutationsConfigurations) do
		Index[Mutation] = {}

		for Anime in pairs(AnimeConfigurations) do
			Index[Mutation][Anime] = ExistingIndex
				and ExistingIndex[Mutation]
				and ExistingIndex[Mutation][Anime] == true
				or false
		end
	end

	return Index
end
	ctx.makeInventoryId = makeInventoryId
	ctx.getRebirthMultiplier = getRebirthMultiplier
	ctx.getToolSellValue = getToolSellValue
	ctx.normalizeHotbarOrder = normalizeHotbarOrder
	ctx.setHotbarSlot = setHotbarSlot
	ctx.getBaseSlotCount = getBaseSlotCount
	ctx.equipInventoryTool = equipInventoryTool
	ctx.cleanupToolData = cleanupToolData
	ctx.getInventorySnapshot = getInventorySnapshot
	ctx.syncInventory = syncInventory
	ctx.queueInventorySync = queueInventorySync
	ctx.clearEquippedInventoryTool = clearEquippedInventoryTool
	PlayersModule.ClearEquippedInventoryTool = clearEquippedInventoryTool
	ctx.findToolDataById = findToolDataById
	ctx.removeToolData = removeToolData
	ctx.reconcileIndex = reconcileIndex
end

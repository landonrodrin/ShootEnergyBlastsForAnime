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
	local AdminCommandEvent = ctx.AdminCommandEvent
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
	local RESET_COMMAND_NAME = ctx.RESET_COMMAND_NAME
	local RICH_COMMAND_NAME = ctx.RICH_COMMAND_NAME
	local FAST_COMMAND_NAME = ctx.FAST_COMMAND_NAME
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
	local reconcileIndex = ctx.reconcileIndex
	local handlePlayerCommand = ctx.handlePlayerCommand
	local setupOwnerTextChatCommands = ctx.setupOwnerTextChatCommands
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
function PlayersModule:Load()
	local Player = self.Player
	local UserId = Player.UserId

	local Success, Money = pcall(function()
		return MoneyDataStore:GetAsync(UserId)
	end)

	if Success and Money then
		self.Money = Money
	else
		self.Money = GameConfigurations.Defaults.Money
	end

	task.delay(1, function()
		if not PlayersData[Player] then return end

		MoneyEvent:FireClient(Player, self.Money)
	end)

	task.delay(5, function()
		if not PlayersData[Player] then return end

		MoneyEvent:FireClient(Player, PlayersData[Player].Money)
	end)

	local Success, Speed = pcall(function()
		return SpeedDataStore:GetAsync(UserId)
	end)

	if Success and Speed then
		self.Speed = Speed
	else
		self.Speed = GameConfigurations.Defaults.Speed
	end

	task.delay(1, function()
		if not PlayersData[Player] then return end

		SpeedEvent:FireClient(Player, self.Speed)
	end)

	task.delay(5, function()
		if not PlayersData[Player] then return end

		SpeedEvent:FireClient(Player, PlayersData[Player].Speed)
	end)

	local Success, Data = pcall(function()
		return PlayerDataStore:GetAsync(UserId)
	end)

	if Success and Data then
		for Name, Value in pairs(Data) do
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

	migrateBaseProgression(self, Success and Data ~= nil)

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

	task.delay(1, function()
		if not PlayersData[Player] then return end

		RebirthEvent:FireClient(Player, self.Rebirths, self.Speed)
	end)

	task.delay(5, function()
		if not PlayersData[Player] then return end

		RebirthEvent:FireClient(Player, self.Rebirths, self.Speed)
	end)

	task.delay(1, function()
		if not PlayersData[Player] then return end

		CarryEvent:FireClient(Player, self.Carry)
	end)

	task.delay(5, function()
		if not PlayersData[Player] then return end

		CarryEvent:FireClient(Player, PlayersData[Player].Carry)
	end)

	task.delay(1, function()
		syncInventory(Player)
	end)

	task.delay(5, function()
		syncInventory(Player)
	end)

	PlayersData[Player] = self

	task.spawn(function()
		for _, Tool in ipairs(Player.Backpack:GetChildren()) do
			if Tool:IsA("Tool") then
				Tool:Destroy()
			end
		end

		for Index, ToolData in ipairs(self.Tools) do
			task.spawn(function()
				local Anime = ToolData.Name
				local AnimeConfiguration = AnimeConfigurations[Anime]

				PlayersModule.Tool(Player, Anime, AnimeConfiguration, ToolData.Mutation, ToolData.Level, Index, ToolData)
			end)
		end

		task.defer(syncInventory, Player)

		Player.CharacterAdded:Connect(function()
			task.wait()

			local PlayerData = PlayersData[Player]
			if not PlayerData then return end

			for _, Tool in ipairs(Player.Backpack:GetChildren()) do
				if Tool:IsA("Tool") then
					Tool:Destroy()
				end
			end

			for Index, ToolData in ipairs(PlayerData.Tools or {}) do
				task.spawn(function()
					local Anime = ToolData.Name
					local AnimeConfiguration = AnimeConfigurations[Anime]

					PlayersModule.Tool(Player, Anime, AnimeConfiguration, ToolData.Mutation, ToolData.Level, Index, ToolData)
				end)
			end

			task.defer(syncInventory, Player)
		end)

		Player.CharacterRemoving:Connect(function()
			removeHeldModel(Player)
			task.defer(syncInventory, Player)
		end)
	end)

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

	pcall(function()
		MoneyDataStore:SetAsync(UserId, self.Money)
	end)

	pcall(function()
		SpeedDataStore:SetAsync(UserId, self.Speed)
	end)

	for Index, ToolData in ipairs(self.Tools) do
		if not ToolData.Tool then continue end

		ToolData.Id = ToolData.Id or makeInventoryId()
		ToolData.Tool = nil
		ToolData.HeldModel = nil

		self.Tools[Index] = ToolData
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

	pcall(function()
		PlayerDataStore:SetAsync(UserId, Data)
	end)

	if PlayersData[Player] and PlayersData[Player].Base then
		Bases.Destroy(PlayersData[Player].Base)
	end

	PlayersData[Player] = nil
end
	ctx.migrateBaseProgression = migrateBaseProgression
end

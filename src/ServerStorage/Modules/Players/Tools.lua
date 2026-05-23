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
	local cleanupToolData = ctx.cleanupToolData
	local reconcileIndex = ctx.reconcileIndex
	local handlePlayerCommand = ctx.handlePlayerCommand
	local setupOwnerTextChatCommands = ctx.setupOwnerTextChatCommands
function PlayersModule.Tool(Player, Name, AnimeConfiguration, Mutation, Level, ToolIndex, ToolData, AutoEquip, SuppressSync)
	if typeof(ToolIndex) == "boolean" and ToolData == nil and AutoEquip == nil then
		AutoEquip = ToolIndex
		ToolIndex = nil
	end

	if not AnimeConfiguration then return end

	if ToolData and ToolData.Trove then
		cleanupToolData(ToolData)
	end

	local Data = ToolData or {}
	Mutation = Mutation or "Default"

	local Tool = ctx.Resources:WaitForChild("Tool")

	Tool = Tool:Clone()

	local Id = ToolData and ToolData.Id or makeInventoryId()

	Data.Tool = Tool
	Data.Id = Id
	Data.Name = Name
	Data.Mutation = Mutation
	Data.Level = Level or 1
	local ToolTrove = ctx.Trove.new()
	Data.Trove = ToolTrove

	local IndexData = PlayersData[Player] and PlayersData[Player].Index
	if IndexData then
		IndexData[Mutation] = IndexData[Mutation] or {}
	end

	if IndexData and not IndexData[Mutation][Name] then
		IndexData[Mutation][Name] = true

		IndexEvent:FireClient(Player, IndexData)
		if not ToolData then
			task.defer(function()
				if not Player.Parent then return end

				AnimeUnlockedEvent:FireClient(Player, Name, Mutation)
			end)
		end
	end

	ToolTrove:Connect(Tool.Equipped, function()
		createHeldModel(Player, Name, Mutation, Data.Level)
		syncInventory(Player)

		local Base = PlayersData[Player] and PlayersData[Player].Base
		if not Base then return end

		local SlotsData = Bases.Retrieve(Base, "SlotsData")
		if not SlotsData then return end

		for _, Slot in ipairs(Bases.GetSlots(Base)) do
			task.spawn(function()
				local Attachment = Bases.GetSlotAttachment(Slot)
				if not Attachment then return end

				SetProperties.Client(Player, Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Attachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Attachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

				if getBaseSlotCount(PlayersData[Player].Level) < tonumber(Slot.Name) then return end

				if SlotsData[Slot.Name] and SlotsData[Slot.Name].Anime then
					SetProperties.Client(Player, Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = true})
				else
					SetProperties.Client(Player, Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = true})
				end
			end)
		end

		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if Player == OtherPlayer then return end

				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local ProximityPrompt = Character.PrimaryPart:FindFirstChild("ProximityPrompt")
				if not ProximityPrompt then return end

				SetProperties.Client(Player, ProximityPrompt, {Enabled = true})
			end)
		end
	end)

	ToolTrove:Connect(Tool.Unequipped, function()
		removeHeldModel(Player)
		syncInventory(Player)

		local Base = PlayersData[Player].Base
		if not Base then return end

		local SlotsData = Bases.Retrieve(Base, "SlotsData")
		if not SlotsData then return end

		for _, Slot in ipairs(Bases.GetSlots(Base)) do
			task.spawn(function()
				local Attachment = Bases.GetSlotAttachment(Slot)
				if not Attachment then return end

				SetProperties.Client(Player, Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Attachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Attachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

				if not (SlotsData[Slot.Name] and SlotsData[Slot.Name].Anime) then return end
				if getBaseSlotCount(PlayersData[Player].Level) < tonumber(Slot.Name) then return end

				SetProperties.Client(Player, Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = true})
				SetProperties.Client(Player, Attachment:WaitForChild("SellProximityPrompt"), {Enabled = true})
			end)
		end

		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if Player == OtherPlayer then return end

				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local ProximityPrompt = Character.PrimaryPart:FindFirstChild("ProximityPrompt")
				if not ProximityPrompt then return end

				SetProperties.Client(Player, ProximityPrompt, {Enabled = false})
			end)
		end
	end)

	Tool.Name = Name
	Tool.ToolTip = Name
	Tool.TextureId = AnimeConfiguration.Icons[Mutation]
	Tool.RequiresHandle = false
	Tool:SetAttribute("InventoryId", Id)
	Tool:SetAttribute("Mutation", Mutation)
	Tool:SetAttribute("Level", Data.Level)

	ToolTrove:Connect(Tool.Destroying, function()
		Data.Tool = nil
		if Data.Trove == ToolTrove then
			Data.Trove = nil
		end

		task.defer(function()
			ToolTrove:Destroy()
		end)
	end)

	if ToolIndex and ToolData then
		ToolData.Id = Id
		ToolData.Tool = Tool
		ToolData.Trove = ToolTrove

		PlayersData[Player].Tools[ToolIndex] = ToolData
	else
		local Tools = PlayersData[Player].Tools
		if not Tools then Tools = {} end

		table.insert(Tools, Data)

		PlayersData[Player].Tools = Tools
	end

	Tool.Parent = Player.Backpack
	normalizeHotbarOrder(PlayersData[Player])
	if AutoEquip and not ToolData then
		task.defer(function()
			if not Player.Parent then return end
			if not Tool.Parent then return end

			equipInventoryTool(Player, Data)
			syncInventory(Player)
		end)
	elseif not SuppressSync then
		task.defer(syncInventory, Player)
	end

	return Data
end
end

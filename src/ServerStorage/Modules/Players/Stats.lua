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
	local reconcileIndex = ctx.reconcileIndex
local function isHoldAnimation(AnimationId)
	return AnimationId == GameConfigurations.AnimationsIds.Carry
		or AnimationId == GameConfigurations.AnimationsIds.OwnedHold
end
function PlayersModule.Retrieve(Player, Name)
	if not PlayersData[Player] then return end

	if Name then
		return PlayersData[Player][Name]
	else
		return PlayersData[Player]
	end
end

function PlayersModule.Replace(Player, Name, Value)
	local PlayerData = PlayersData[Player]

	if not PlayerData then return end

	for OtherName, _ in pairs(PlayerData) do
		if OtherName:lower() ~= Name:lower() then continue end

		Name = OtherName

		break
	end

	PlayerData[Name] = Value

	if Name == "Money" then
		local Leaderstats = Player:WaitForChild("leaderstats")
		local Money = Leaderstats:WaitForChild("Money")

		Money.Value = Format.Number(Value)

		Packets.money.sendTo(Value, Player)
	elseif Name == "MoneyPerSecond" then
		local Leaderstats = Player:WaitForChild("leaderstats")
		local MoneyPerSecond = Leaderstats:WaitForChild("$/s")

		MoneyPerSecond.Value = string.format("%s/s", Format.Number(PlayerData.MoneyPerSecond))

		if PlayerData.Base then
			Bases.UpdateIncomeDisplay(PlayerData.Base, PlayerData.MoneyPerSecond)
		end
	elseif Name == "Speed" then
		Packets.speed.sendTo(Value, Player)
		Packets.rebirth.sendTo({
			Rebirths = PlayerData.Rebirths,
			Speed = Value,
		}, Player)

		Player:SetAttribute("UseNormalSpeed", false)

		local Character = Player.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid.WalkSpeed = Value
		end

		Packets.toggleSpeed.sendTo(nil, Player)
	elseif Name == "Carry" then
		Packets.carry.sendTo(Value, Player)
	elseif Name == "Rebirths" then
		Packets.rebirth.sendTo({
			Rebirths = Value,
			Speed = PlayerData.Speed,
		}, Player)

		local MoneyPerSecond = 0

		local SavedAnime = RetrievePlayerDataFunction:Invoke(Player, "Anime")
		for _, AnimeEntry in ipairs(SavedAnime) do
			local Name = AnimeEntry.Name
			local AnimeConfiguration = AnimeConfigurations[Name]
			local Mutation = AnimeEntry.Mutation
			local MutationConfiguration = MutationsConfigurations[Mutation]
			local Level = AnimeEntry.Level or 1

			local Multiplier = MutationConfiguration.Multiplier or 1

			MoneyPerSecond += AnimeConfiguration.Levels[Level].Money * Multiplier
		end

		local RebirthMutiplier = RebirthsConfigurations[Value] and RebirthsConfigurations[Value].Multiplier or 1

		MoneyPerSecond = MoneyPerSecond * RebirthMutiplier

		ReplacePlayerDataEvent:Fire(Player, "MoneyPerSecond", MoneyPerSecond)

		Bases.RefreshPlayerEconomyDisplays(Player)
		syncInventory(Player)
	elseif Name == "Level" then
		local Base = PlayerData.Base

		if Base then
			Bases.Level(PlayerData, Base)
		end
	elseif Name == "Index" then
		Packets.indexSync.sendTo({
			Index = Value,
		}, Player)
	elseif Name == "Tools" then
		removeHeldModel(Player)
		normalizeHotbarOrder(PlayerData)
		task.defer(syncInventory, Player)
	end

	PlayersData[Player] = PlayerData
end

function PlayersModule.Animate(Player, AnimationId, Bool)
	local PlayerData = PlayersData[Player]

	if not PlayerData then return end
	if not AnimationId or AnimationId == "" then return end

	local Character = Player.Character or Player.CharacterAdded:Wait()

	local Humanoid = Character:WaitForChild("Humanoid")

	PlayerData.AnimationTracks[Humanoid] = PlayerData.AnimationTracks[Humanoid] or {}

	local Tracks = PlayerData.AnimationTracks[Humanoid]

	local AnimationTrack = Tracks[AnimationId]

	if not AnimationTrack then
		local Animator = Humanoid:FindFirstChildOfClass("Animator")
		if not Animator then
			Animator = Instance.new("Animator")
			Animator.Parent = Humanoid
		end

		local Animation = Instance.new("Animation")
		Animation.AnimationId = AnimationId

		local Success, Result = pcall(function()
			return Animator:LoadAnimation(Animation)
		end)

		Animation:Destroy()

		if not Success then
			warn(string.format("Failed to load animation %s for %s: %s", tostring(AnimationId), Player.Name, tostring(Result)))
			return
		end

		AnimationTrack = Result

		if isHoldAnimation(AnimationId) then
			AnimationTrack.Looped = true
			AnimationTrack.Priority = Enum.AnimationPriority.Action4
		end

		Tracks[AnimationId] = AnimationTrack
	end

	if Bool then
		if isHoldAnimation(AnimationId) then
			AnimationTrack.Looped = true
			AnimationTrack.Priority = Enum.AnimationPriority.Action4
			AnimationTrack:Play(0.1, 1, 1)
		else
			AnimationTrack:Play()
		end
	else
		AnimationTrack:Stop(0.1)
	end

	return AnimationTrack
end
end

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
local function trim(Value)
	return (Value or ""):match("^%s*(.-)%s*$")
end

local function isWhitelistedCommandPlayer(Player)
	for _, UserId in ipairs(CommandsConfigurations.Whitelist or {}) do
		if Player.UserId == UserId then
			return true
		end
	end

	return false
end

local function isAdminCommandDebounced(Player, Command)
	local Now = os.clock()

	AdminCommandDebounces[Player] = AdminCommandDebounces[Player] or {}

	if AdminCommandDebounces[Player][Command] and Now - AdminCommandDebounces[Player][Command] < 1 then
		return true
	end

	AdminCommandDebounces[Player][Command] = Now

	return false
end

local function destroyPlayerTools(Player, PlayerData)
	for _, ToolData in ipairs(PlayerData.Tools or {}) do
		if ToolData.Tool then
			ToolData.Tool:Destroy()
			ToolData.Tool = nil
		end

		ToolData.HeldModel = nil
	end

	local Backpack = Player:FindFirstChildOfClass("Backpack")
	if Backpack then
		for _, Child in ipairs(Backpack:GetChildren()) do
			if Child:IsA("Tool") then
				Child:Destroy()
			end
		end
	end

	local Character = Player.Character
	if Character then
		for _, Child in ipairs(Character:GetChildren()) do
			if Child:IsA("Tool") then
				Child:Destroy()
			end
		end
	end
end

local function clearBaseProgress(PlayerData)
	local Base = PlayerData.Base
	if not Base then return end

	for _, Slot in ipairs(Bases.GetSlots(Base)) do
		Bases.Remove(Base, Slot, true)
	end

	local Level = Bases.GetBaseLevelPart(Base)
	if Level then
		for _, GuiName in ipairs({"BaseLevelGui", "BaseLevelGuiFront", "BaseLevelGuiBack"}) do
			local BaseLevelGui = Level:FindFirstChild(GuiName)
			if BaseLevelGui then
				BaseLevelGui:Destroy()
			end
		end

		local LevelGui = Level:FindFirstChild("LevelGui")
		if LevelGui then
			LevelGui:Destroy()
		end
	end
end

local function resetPlayerProgress(Player)
	local PlayerData = PlayersData[Player]
	if not PlayerData then return end

	if isAdminCommandDebounced(Player, "reset") then return end

	removeHeldModel(Player)
	destroyPlayerTools(Player, PlayerData)
	clearBaseProgress(PlayerData)

	PlayersModule.Replace(Player, "Anime", {})
	PlayersModule.Replace(Player, "Tools", {})
	PlayersModule.Replace(Player, "HotbarOrder", {})
	PlayersModule.Replace(Player, "Index", reconcileIndex(nil))
	PlayersModule.Replace(Player, "Steals", 0)
	PlayersModule.Replace(Player, "Money", GameConfigurations.Defaults.Money)
	PlayersModule.Replace(Player, "Speed", GameConfigurations.Defaults.Speed)
	PlayersModule.Replace(Player, "Carry", GameConfigurations.Defaults.Carry)
	PlayersModule.Replace(Player, "Rebirths", 0)
	PlayersModule.Replace(Player, "Level", 1)
	PlayersModule.Replace(Player, "MoneyPerSecond", 0)
	PlayerData.BaseProgressionVersion = BASE_PROGRESSION_VERSION

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		Humanoid.WalkSpeed = GameConfigurations.Defaults.Speed
	end

	print(string.format("Owner reset executed for %s (%d)", Player.Name, Player.UserId))
	AnnouncementEvent:FireClient(Player, "Testing progress reset.", Color3.fromRGB(0, 255, 0))
end

local function grantRichMoney(Player)
	local PlayerData = PlayersData[Player]
	if not PlayerData then return end
	if isAdminCommandDebounced(Player, "rich") then return end

	PlayersModule.Replace(Player, "Money", ADMIN_RICH_MONEY)

	print(string.format("Owner rich command executed for %s (%d)", Player.Name, Player.UserId))
	AnnouncementEvent:FireClient(Player, string.format("Money set to $%s.", Format.Number(ADMIN_RICH_MONEY)), Color3.fromRGB(0, 255, 0))
end

local function grantFastSpeed(Player)
	local PlayerData = PlayersData[Player]
	if not PlayerData then return end
	if isAdminCommandDebounced(Player, "fast") then return end

	PlayersModule.Replace(Player, "Speed", ADMIN_FAST_SPEED)

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		Humanoid.WalkSpeed = ADMIN_FAST_SPEED
	end

	print(string.format("Owner fast command executed for %s (%d)", Player.Name, Player.UserId))
	AnnouncementEvent:FireClient(Player, string.format("Speed set to %s.", ADMIN_FAST_SPEED), Color3.fromRGB(0, 255, 0))
end

local function handlePlayerCommand(Player, Message)
	local Prefix = CommandsConfigurations.Prefix or "/"
	local Command = string.lower(trim(Message))
	local ResetCommand = string.lower(Prefix .. "reset")
	local RichCommand = string.lower(Prefix .. "rich")
	local FastCommand = string.lower(Prefix .. "fast")

	if not isWhitelistedCommandPlayer(Player) then return end

	if Command == ResetCommand or Command == "reset" then
		resetPlayerProgress(Player)
	elseif Command == RichCommand or Command == "rich" then
		grantRichMoney(Player)
	elseif Command == FastCommand or Command == "fast" then
		grantFastSpeed(Player)
	end
end

local function setupOwnerTextChatCommand(CommandName, PrimaryAlias, SecondaryAlias)
	local CommandsFolder = TextChatService:WaitForChild("TextChatCommands", 5) or TextChatService

	local Command = CommandsFolder:FindFirstChild(CommandName) or TextChatService:FindFirstChild(CommandName)
	if not Command then
		Command = Instance.new("TextChatCommand")
		Command.Name = CommandName
	end

	Command.PrimaryAlias = PrimaryAlias
	Command.SecondaryAlias = SecondaryAlias or ""
	Command.AutocompleteVisible = false
	Command.Enabled = true
	Command.Parent = CommandsFolder
	print(string.format("Owner admin command registered as %s", PrimaryAlias))

	Command.Triggered:Connect(function(TextSource, UnfilteredText)
		local UserId = TextSource and TextSource.UserId
		local Player = UserId and Players:GetPlayerByUserId(UserId)
		if not Player then return end

		handlePlayerCommand(Player, UnfilteredText or PrimaryAlias)
	end)
end

local function setupOwnerTextChatCommands()
	local Prefix = CommandsConfigurations.Prefix or "/"

	setupOwnerTextChatCommand(RESET_COMMAND_NAME, Prefix .. "reset", "reset")
	setupOwnerTextChatCommand(RICH_COMMAND_NAME, Prefix .. "rich", "rich")
	setupOwnerTextChatCommand(FAST_COMMAND_NAME, Prefix .. "fast", "fast")
end
	ctx.handlePlayerCommand = handlePlayerCommand
	ctx.setupOwnerTextChatCommands = setupOwnerTextChatCommands
	ctx.destroyPlayerTools = destroyPlayerTools
	ctx.clearBaseProgress = clearBaseProgress
end

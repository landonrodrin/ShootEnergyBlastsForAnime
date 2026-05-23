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
local function registerCollisionGroup(Name)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(Name)
	end)
end

local function setGroupsCollidable(GroupA, GroupB, Collidable)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(GroupA, GroupB, Collidable)
	end)
end

local function isHoldAnimation(AnimationId)
	return AnimationId == GameConfigurations.AnimationsIds.Carry
		or AnimationId == GameConfigurations.AnimationsIds.OwnedHold
end

local function getSellStation()
	local Sell = workspace:FindFirstChild("Sell")
	return Sell and Sell:FindFirstChild("Toggle")
end

local function isNearSellStation(Player)
	if ZoneTracker.IsInZone(Player, "Sell") then
		return true
	end

	local Station = ZoneTracker.GetZonePart("Sell") or getSellStation()
	if not Station then return false end

	local Character = Player.Character
	local PrimaryPart = Character and Character.PrimaryPart
	if not PrimaryPart then return false end

	return (PrimaryPart.Position - Station.Position).Magnitude <= SELL_STATION_DISTANCE
end

local function getPlayerSpawnPart()
	local BasesFolder = workspace:FindFirstChild("Bases")
	local Base = BasesFolder and BasesFolder:FindFirstChild(PLAYER_SPAWN_BASE_NAME)
	local Spawn = Base and Base:FindFirstChild(PLAYER_SPAWN_PART_NAME)
		or Base and Base:FindFirstChild(PLAYER_SPAWN_PART_NAME, true)

	if Spawn and Spawn:IsA("BasePart") then
		return Spawn
	end
end

local function moveCharacterToPlayerSpawn(Character)
	local Spawn = getPlayerSpawnPart()
	if not Spawn then
		warn(string.format("Missing player spawn: Workspace.Bases.%s.%s", PLAYER_SPAWN_BASE_NAME, PLAYER_SPAWN_PART_NAME))
		return false
	end

	local Root = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart", 5)
	if not Root then return false end

	Character:PivotTo(Spawn.CFrame * CFrame.new(0, (Spawn.Size.Y / 2) + PLAYER_SPAWN_VERTICAL_OFFSET, 0))

	Root.AssemblyLinearVelocity = Vector3.zero
	Root.AssemblyAngularVelocity = Vector3.zero

	return true
end

local function scheduleCharacterSpawnMove(Character)
	task.defer(moveCharacterToPlayerSpawn, Character)
	task.delay(0.25, function()
		if Character.Parent then
			moveCharacterToPlayerSpawn(Character)
		end
	end)
end
function PlayersModule.Setup()
	setupOwnerTextChatCommands()

	registerCollisionGroup("Players")
	registerCollisionGroup("Anime")
	registerCollisionGroup("HeldPreviews")
	setGroupsCollidable("Players", "Anime", false)
	setGroupsCollidable("Players", "Players", false)
	setGroupsCollidable("HeldPreviews", "Default", false)
	setGroupsCollidable("HeldPreviews", "Players", false)
	setGroupsCollidable("HeldPreviews", "Anime", false)
	setGroupsCollidable("HeldPreviews", "HeldPreviews", false)

	local SellStation = getSellStation()
	if SellStation then
		ZoneTracker.RegisterZone("Sell", SellStation)
	else
		warn("Missing sell station zone: Workspace.Sell.Toggle")
	end

	local SettingUpPlayers = {}

	local function setupPlayer(Player)
		if PlayersData[Player] or SettingUpPlayers[Player] then return end

		SettingUpPlayers[Player] = true

		Player.Chatted:Connect(function(Message)
			handlePlayerCommand(Player, Message)
		end)

		local Success, Error = pcall(PlayersModule.Create, Player)
		SettingUpPlayers[Player] = nil

		if not Success then
			warn(string.format("Failed to set up player %s: %s", Player.Name, tostring(Error)))
		end
	end

	Players.PlayerAdded:Connect(setupPlayer)

	for _, Player in ipairs(Players:GetPlayers()) do
		task.spawn(setupPlayer, Player)
	end

	Players.PlayerRemoving:Connect(function(Player)
		local PlayerData = PlayersData[Player]

		if PlayerData then
			PlayerData:Save()
		end

		ZoneTracker.ClearPlayer(Player)
		removeHeldModel(Player)
		HeldInventoryCarry[Player] = nil
		AdminCommandDebounces[Player] = nil
	end)

	game:BindToClose(function()
		for Player, PlayerData in pairs(PlayersData) do
			PlayerData:Save()
		end
	end)

	RetrievePlayerDataFunction.OnInvoke = PlayersModule.Retrieve

	ReplacePlayerDataEvent.Event:Connect(PlayersModule.Replace)
	CreateToolEvent.Event:Connect(PlayersModule.Tool)
	AdminCommandEvent.OnServerEvent:Connect(function(Player, Message)
		handlePlayerCommand(Player, Message or "")
	end)

	IncrementSpeedEvent.OnServerEvent:Connect(function(Player, Speed)
		local Money = math.round(UpgradesConfigurations["Speed1"].Money * UpgradesConfigurations["Speed1"].IncrementMultiplier ^ (PlayersModule.Retrieve(Player, "Speed") + Speed - 1))

		if PlayersModule.Retrieve(Player, "Money") < Money then return end

		PlayersModule.Replace(Player, "Money", PlayersModule.Retrieve(Player, "Money") - Money)
		PlayersModule.Replace(Player, "Speed", PlayersModule.Retrieve(Player, "Speed") + Speed)
	end)

	IncrementCarryEvent.OnServerEvent:Connect(function(Player, Carry)
		local Money = math.round(UpgradesConfigurations["Carry1"].Money * UpgradesConfigurations["Carry1"].IncrementMultiplier ^ (PlayersModule.Retrieve(Player, "Carry") + Carry - 1))

		if PlayersModule.Retrieve(Player, "Money") < Money then return end

		PlayersModule.Replace(Player, "Money", PlayersModule.Retrieve(Player, "Money") - Money)
		PlayersModule.Replace(Player, "Carry", PlayersModule.Retrieve(Player, "Carry") + Carry)
	end)

	ctx.setupPurchaseProcessing()

	AnnouncementEvent.OnServerEvent:Connect(function(Player, Text, Colour)
		AnnouncementEvent:FireClient(Player, Text, Colour)
	end)

	ToggleSpeedEvent.OnServerEvent:Connect(function(Player, Toggle)
		local Speed = PlayersModule.Retrieve(Player, "Speed") or 16

		local Character = Player.Character or Player.CharacterAdded:Wait()

		local Humanoid = Character:WaitForChild("Humanoid")

		Humanoid.WalkSpeed = Toggle and 16 or Speed
	end)

	RebirthEvent.OnServerEvent:Connect(function(Player)
		local Rebirths = PlayersModule.Retrieve(Player, "Rebirths")
		local Speed = PlayersModule.Retrieve(Player, "Speed")

		if not RebirthsConfigurations[Rebirths + 1] or Speed < RebirthsConfigurations[Rebirths + 1].Speed then return end

		ReplacePlayerDataEvent:Fire(Player, "Rebirths", Rebirths + 1)
		ReplacePlayerDataEvent:Fire(Player, "Speed", GameConfigurations.Defaults.Speed)

		RebirthEvent:FireClient(Player, Rebirths + 1, GameConfigurations.Defaults.Speed)
	end)

	IndexEvent.OnServerEvent:Connect(function(Player, Mutation)
		local Index = PlayersModule.Retrieve(Player, "Index")

		IndexEvent:FireClient(Player, Index, Mutation)
	end)

	EquipInventoryEvent.OnServerEvent:Connect(function(Player, Id)
		local _, ToolData = findToolDataById(Player, Id)
		if not ToolData or not ToolData.Tool then return end

		local Character = Player.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if not Humanoid then return end

		if ToolData.Tool.Parent == Character then
			Humanoid:UnequipTools()
			removeHeldModel(Player)
		else
			equipInventoryTool(Player, ToolData)
		end

		task.defer(syncInventory, Player)
	end)

	SellInventoryEvent.OnServerEvent:Connect(function(Player, Mode, Id)
		if not isNearSellStation(Player) then return end

		local PlayerData = PlayersData[Player]
		if not PlayerData then return end

		local Total = 0

		if Mode == "Single" then
			local Index, ToolData = findToolDataById(Player, Id)
			if not Index or not ToolData then return end

			Total += getToolSellValue(ToolData.Name, ToolData.Mutation, ToolData.Level or 1, PlayerData.Rebirths)
			removeToolData(Player, Index, ToolData)
		elseif Mode == "All" then
			for Index = #PlayerData.Tools, 1, -1 do
				local ToolData = PlayerData.Tools[Index]
				if not ToolData or not AnimeConfigurations[ToolData.Name] then continue end

				Total += getToolSellValue(ToolData.Name, ToolData.Mutation, ToolData.Level or 1, PlayerData.Rebirths)
				removeToolData(Player, Index, ToolData)
			end
		end

		if Total <= 0 then
			syncInventory(Player)
			return
		end

		PlayersModule.Replace(Player, "Money", PlayersModule.Retrieve(Player, "Money") + Total)
		syncInventory(Player)
	end)

	UpdateHotbarSlotEvent.OnServerEvent:Connect(function(Player, Slot, Id)
		local PlayerData = PlayersData[Player]
		if not PlayerData then return end

		if setHotbarSlot(PlayerData, Slot, Id) then
			syncInventory(Player)
		end
	end)
end
function PlayersModule.Create(Player)
	local PlayerData = setmetatable({}, {__index = PlayersModule})

	PlayerData.Player = Player

	PlayerData.AnimationTracks = {}

	PlayerData:Load()

	local Leaderstats = Instance.new("Folder")
	Leaderstats.Name = "leaderstats"
	Leaderstats.Parent = Player

	local Money = Instance.new("StringValue")
	Money.Name = "Money"
	Money.Value = Format.Number(PlayerData.Money)
	Money.Parent = Leaderstats

	local MoneyPerSecond = Instance.new("StringValue")
	MoneyPerSecond.Name = "$/s"
	MoneyPerSecond.Value = string.format("%s/s", Format.Number(PlayerData.MoneyPerSecond))
	MoneyPerSecond.Parent = Leaderstats

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")

	Humanoid.WalkSpeed = PlayerData.Speed

	for _, Descendant in ipairs(Character:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		Descendant.CollisionGroup = "Players"
	end

	scheduleCharacterSpawnMove(Character)

	Player.CharacterAdded:Connect(function(Character)
		local Humanoid = Character:WaitForChild("Humanoid")

		Humanoid.WalkSpeed = PlayerData.Speed

		for _, Descendant in ipairs(Character:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end

			Descendant.CollisionGroup = "Players"
		end

		scheduleCharacterSpawnMove(Character)

		local Base = PlayersData[Player].Base
		if not Base then return end

		local ProximityPrompt = Instance.new("ProximityPrompt")
		ProximityPrompt.Enabled = false
		ProximityPrompt.ActionText = "Give"
		ProximityPrompt.HoldDuration = 1
		ProximityPrompt.ObjectText = ""
		ProximityPrompt.RequiresLineOfSight = false
		ProximityPrompt.Parent = Character.PrimaryPart

		ProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
			if Player == TriggeringPlayer then return end

			local Character = TriggeringPlayer.Character or TriggeringPlayer.CharacterAdded:Wait()

			local Tool = Character:FindFirstChildOfClass("Tool")
			if not Tool then return end

			local ToolsData = PlayersModule.Retrieve(TriggeringPlayer, "Tools")

			for Index, ToolData in pairs(ToolsData) do
				if ToolData.Tool ~= Tool then continue end

				local Name = ToolData.Name
				local Mutation = ToolData.Mutation
				local Level = ToolData.Level

				local AnimeConfiguration = AnimeConfigurations[Name]
				if not AnimeConfiguration then return end

				table.remove(ToolsData, Index)

				PlayersModule.Replace(TriggeringPlayer, "Tools", ToolsData)

				Tool:Destroy()

				PlayersModule.Tool(Player, Name, AnimeConfiguration, Mutation, Level)

				break
			end
		end)

		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if Player == OtherPlayer then return end

				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local Tool = Character:FindFirstChildOfClass("Tool")
				if not Tool then return end

				SetProperties.Client(OtherPlayer, ProximityPrompt, {Enabled = true})
			end)
		end
	end)

	task.spawn(function()
		local BaseData = Bases.Create(PlayerData)

		local Base = BaseData.Base

		PlayersData[Player].Base = Base

		if not Player.Character then return end

		local ProximityPrompt = Instance.new("ProximityPrompt")
		ProximityPrompt.Enabled = false
		ProximityPrompt.ActionText = "Give"
		ProximityPrompt.HoldDuration = 1
		ProximityPrompt.ObjectText = ""
		ProximityPrompt.RequiresLineOfSight = false
		ProximityPrompt.Parent = Character.PrimaryPart

		ProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
			if Player == TriggeringPlayer then return end

			local Character = TriggeringPlayer.Character or TriggeringPlayer.CharacterAdded:Wait()

			local Tool = Character:FindFirstChildOfClass("Tool")
			if not Tool then return end

			local ToolsData = PlayersModule.Retrieve(TriggeringPlayer, "Tools")

			for Index, ToolData in pairs(ToolsData) do
				if ToolData.Tool ~= Tool then continue end

				local Name = ToolData.Name
				local Mutation = ToolData.Mutation
				local Level = ToolData.Level

				local AnimeConfiguration = AnimeConfigurations[Name]
				if not AnimeConfiguration then return end

				table.remove(ToolsData, Index)

				PlayersModule.Replace(TriggeringPlayer, "Tools", ToolsData)

				Tool:Destroy()

				PlayersModule.Tool(Player, Name, AnimeConfiguration, Mutation, Level)

				break
			end
		end)

		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if Player == OtherPlayer then return end

				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local Tool = Character:FindFirstChildOfClass("Tool")
				if not Tool then return end

				SetProperties.Client(OtherPlayer, ProximityPrompt, {Enabled = true})
			end)
		end
	end)

	PlayersData[Player] = PlayerData

	return PlayerData
end
	ctx.registerCollisionGroup = registerCollisionGroup
	ctx.setGroupsCollidable = setGroupsCollidable
end

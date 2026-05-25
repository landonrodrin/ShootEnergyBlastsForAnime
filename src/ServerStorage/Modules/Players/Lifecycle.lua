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
	local Trove = ctx.Trove
	local ZonePlus = ctx.ZonePlus
	local RequestGuard = ctx.RequestGuard
	local RequestPolicy = ctx.RequestPolicy
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
	local PreviewTemplates = ctx.PreviewTemplates
	local MoneyPerSecondLeaderstatUpdates = ctx.MoneyPerSecondLeaderstatUpdates
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
	local SetupTrove = Trove.new()
	local NetworkListenersStarted = false
	local BIND_TO_CLOSE_SAVE_TIMEOUT = 25
	local PlayersInStrips = {}
	local RequestCooldowns = RequestPolicy.Cooldowns
	local AllowedSpeedIncrements = {
		[1] = true,
		[5] = true,
		[10] = true,
	}
local function registerCollisionGroup(Name)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(Name)
	end)
end

local function isLoadedPlayer(Player)
	return Player and PlayersData[Player] ~= nil
end

local function isPositiveInteger(Value)
	return type(Value) == "number" and Value > 0 and Value % 1 == 0
end

local function getCharacterHumanoid(Player)
	local Character = Player.Character
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function getActiveMovementSpeed(Player)
	local PlayerData = PlayersData[Player]
	if not PlayerData then
		return GameConfigurations.Defaults.Speed
	end

	if PlayersInStrips[Player] then
		return PlayerData.Speed or GameConfigurations.Defaults.Speed
	end

	return GameConfigurations.Defaults.Speed
end

local function applyPlayerMovementSpeed(Player)
	local Humanoid = getCharacterHumanoid(Player)
	if not Humanoid then return end

	Humanoid.WalkSpeed = getActiveMovementSpeed(Player)
end

local function bindSpeedZone(Name, Container, OnEntered, OnExited)
	if not Container then
		warn(string.format("Missing movement speed zone: %s", Name))
		return
	end

	local Zone = ZonePlus.CreatePresenceZone(Container)
	SetupTrove:Add(Zone, "destroy")

	ZonePlus.ConnectSignal(SetupTrove, Zone.playerEntered, OnEntered)
	ZonePlus.ConnectSignal(SetupTrove, Zone.playerExited, OnExited)

	for _, Player in ipairs(Players:GetPlayers()) do
		if Zone:findPlayer(Player) then
			OnEntered(Player)
		end
	end
end

local function setupMovementSpeedZones()
	table.clear(PlayersInStrips)

	local Strips = workspace:FindFirstChild("Strips") or workspace:WaitForChild("Strips", 10)
	bindSpeedZone("Workspace.Strips", Strips, function(Player)
		PlayersInStrips[Player] = true
		applyPlayerMovementSpeed(Player)
	end, function(Player)
		PlayersInStrips[Player] = nil
		applyPlayerMovementSpeed(Player)
	end)

	local Map = workspace:FindFirstChild("Map") or workspace:WaitForChild("Map", 10)
	local MainFloor = Map and (Map:FindFirstChild("Main Floor") or Map:WaitForChild("Main Floor", 10))
	bindSpeedZone("Workspace.Map.Main Floor", MainFloor, function(Player)
		applyPlayerMovementSpeed(Player)
	end, function(Player)
		applyPlayerMovementSpeed(Player)
	end)
end

local function setGroupsCollidable(GroupA, GroupB, Collidable)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(GroupA, GroupB, Collidable)
	end)
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
	local PrimaryPart = Character and (Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart"))
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

local function addOwnedDelay(OwnerTrove, Delay, Callback)
	local Thread = task.delay(Delay, Callback)
	if OwnerTrove then
		OwnerTrove:Add(Thread)
	end
	return Thread
end

local function scheduleCharacterSpawnMove(Character, OwnerTrove)
	local DeferredThread = task.defer(moveCharacterToPlayerSpawn, Character)
	if OwnerTrove then
		OwnerTrove:Add(DeferredThread)
	end

	addOwnedDelay(OwnerTrove, 0.25, function()
		if Character.Parent then
			moveCharacterToPlayerSpawn(Character)
		end
	end)
end

local SUCCESS_COLOUR = Color3.fromRGB(95, 255, 140)
local WARNING_COLOUR = Color3.fromRGB(255, 210, 90)
local INSUFFICIENT_FUNDS_TEXT = "Insufficient Funds"
local INSUFFICIENT_FUNDS_COLOUR = Color3.fromRGB(255, 0, 0)

local function announceSell(Player, Text, Colour)
	Packets.announcement.sendTo({
		Text = Text,
		Colour = Packets.EncodeColour(Colour or WARNING_COLOUR),
	}, Player)
end

local function sellInventory(Player, Mode, Id)
	local PlayerData = PlayersData[Player]
	if not PlayerData then
		announceSell(Player, "Inventory is still loading.")
		return
	end

	if not isNearSellStation(Player) then
		announceSell(Player, "Stand by the sell shop to sell anime.")
		return
	end

	local Total = 0
	local Sold = 0

	if Mode == "Single" then
		local Index, ToolData = findToolDataById(Player, Id)
		if not Index or not ToolData then
			syncInventory(Player)
			announceSell(Player, "That anime is no longer in your inventory.")
			return
		end

		local Value = getToolSellValue(ToolData.Name, ToolData.Mutation, ToolData.Level or 1, PlayerData.Rebirths)
		if Value <= 0 then
			syncInventory(Player)
			announceSell(Player, "That anime cannot be sold.")
			return
		end

		Total += Value
		Sold += 1
		removeToolData(Player, Index, ToolData, true)
	elseif Mode == "All" then
		for Index = #PlayerData.Tools, 1, -1 do
			local ToolData = PlayerData.Tools[Index]
			if not ToolData or not AnimeConfigurations[ToolData.Name] then continue end

			local Value = getToolSellValue(ToolData.Name, ToolData.Mutation, ToolData.Level or 1, PlayerData.Rebirths)
			if Value <= 0 then continue end

			Total += Value
			Sold += 1
			removeToolData(Player, Index, ToolData, true)
		end
	else
		syncInventory(Player)
		return
	end

	if Sold <= 0 or Total <= 0 then
		syncInventory(Player)
		announceSell(Player, "No sellable anime in your inventory.")
		return
	end

	PlayersModule.Replace(Player, "Money", (PlayersModule.Retrieve(Player, "Money") or 0) + Total)
	syncInventory(Player)

	if Sold == 1 then
		announceSell(Player, string.format("Sold anime for $%s.", Format.Number(Total)), SUCCESS_COLOUR)
	else
		announceSell(Player, string.format("Sold %s anime for $%s.", Sold, Format.Number(Total)), SUCCESS_COLOUR)
	end
end
function PlayersModule.Setup()
	SetupTrove:Clean()

	registerCollisionGroup("Players")
	registerCollisionGroup("Anime")
	setGroupsCollidable("Players", "Anime", false)
	setGroupsCollidable("Players", "Players", false)
	if PreviewTemplates then
		PreviewTemplates.ValidateAnimeTemplates()
	end
	setupMovementSpeedZones()

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

		local Success, PlayerDataOrError = pcall(PlayersModule.Create, Player)
		SettingUpPlayers[Player] = nil

		if not Success then
			warn(string.format("Failed to set up player %s: %s", Player.Name, tostring(PlayerDataOrError)))
			return
		end

		return PlayerDataOrError
	end

	SetupTrove:Connect(Players.PlayerAdded, setupPlayer)

	for _, Player in ipairs(Players:GetPlayers()) do
		SetupTrove:Add(task.spawn(setupPlayer, Player))
	end

	SetupTrove:Connect(Players.PlayerRemoving, function(Player)
		local PlayerData = PlayersData[Player]

		if PlayerData then
			PlayerData:QueueSave("PlayerRemoving")
			PlayerData:DestroySession()
		end

		ZoneTracker.ClearPlayer(Player)
		Player:SetAttribute("HoldState", nil)
		PlayersInStrips[Player] = nil
		MoneyPerSecondLeaderstatUpdates[Player] = nil
		AdminCommandDebounces[Player] = nil
	end)

	game:BindToClose(function()
		local ClosingPlayersData = {}
		for Player, PlayerData in pairs(PlayersData) do
			table.insert(ClosingPlayersData, {
				Player = Player,
				PlayerData = PlayerData
			})
		end

		local PendingSaves = #ClosingPlayersData
		if PendingSaves <= 0 then return end

		for _, Entry in ipairs(ClosingPlayersData) do
			task.spawn(function()
				local Success, Error = pcall(function()
					local PlayerData = Entry.PlayerData
					PlayerData:QueueSave("BindToClose")
					PlayerData:DestroySession()
				end)
				if not Success then
					warn(string.format("BindToClose player save task failed: %s", tostring(Error)))
				end

				PendingSaves -= 1
			end)
		end

		local Deadline = os.clock() + BIND_TO_CLOSE_SAVE_TIMEOUT
		while PendingSaves > 0 and os.clock() < Deadline do
			task.wait()
		end

		if PendingSaves > 0 then
			warn(string.format("BindToClose finished with %s player save(s) still pending.", PendingSaves))
		end
	end)

	RetrievePlayerDataFunction.OnInvoke = PlayersModule.Retrieve

	SetupTrove:Connect(ReplacePlayerDataEvent.Event, PlayersModule.Replace)
	SetupTrove:Connect(CreateToolEvent.Event, PlayersModule.Tool)

	if not NetworkListenersStarted then
		NetworkListenersStarted = true

		Packets.incrementSpeed.listen(function(Speed, Player)
			if not isLoadedPlayer(Player) then return end
			if not isPositiveInteger(Speed) or not AllowedSpeedIncrements[Speed] then return end
			if not RequestGuard.Allow(Player, "incrementSpeed", RequestCooldowns.IncrementSpeed) then return end

			local CurrentSpeed = PlayersModule.Retrieve(Player, "Speed") or 0
			if CurrentSpeed + Speed > GameConfigurations.Maximums.Speed then return end

			local Cost = math.round(UpgradesConfigurations["Speed1"].Money * UpgradesConfigurations["Speed1"].IncrementMultiplier ^ (CurrentSpeed + Speed - 1))

			if PlayersModule.Retrieve(Player, "Money") < Cost then
				announceSell(Player, INSUFFICIENT_FUNDS_TEXT, INSUFFICIENT_FUNDS_COLOUR)
				return
			end

			PlayersModule.Replace(Player, "Money", PlayersModule.Retrieve(Player, "Money") - Cost)
			PlayersModule.Replace(Player, "Speed", CurrentSpeed + Speed)
		end)

		Packets.incrementCarry.listen(function(Carry, Player)
			if not isLoadedPlayer(Player) then return end
			if Carry ~= 1 then return end
			if not RequestGuard.Allow(Player, "incrementCarry", RequestCooldowns.IncrementCarry) then return end

			local CurrentCarry = PlayersModule.Retrieve(Player, "Carry") or 0
			if CurrentCarry + Carry > GameConfigurations.Maximums.Carry then return end

			local Cost = math.round(UpgradesConfigurations["Carry1"].Money * UpgradesConfigurations["Carry1"].IncrementMultiplier ^ (CurrentCarry + Carry - 1))

			if PlayersModule.Retrieve(Player, "Money") < Cost then
				announceSell(Player, INSUFFICIENT_FUNDS_TEXT, INSUFFICIENT_FUNDS_COLOUR)
				return
			end

			PlayersModule.Replace(Player, "Money", PlayersModule.Retrieve(Player, "Money") - Cost)
			PlayersModule.Replace(Player, "Carry", CurrentCarry + Carry)
		end)

		Packets.rebirthRequest.listen(function(_, Player)
			if not isLoadedPlayer(Player) then return end
			if not RequestGuard.Allow(Player, "rebirthRequest", RequestCooldowns.Rebirth) then return end

			local Rebirths = PlayersModule.Retrieve(Player, "Rebirths") or 0
			local Speed = PlayersModule.Retrieve(Player, "Speed") or 0
			local NextRebirthConfiguration = RebirthsConfigurations[Rebirths + 1]

			if not NextRebirthConfiguration then
				announceSell(Player, "Max rebirth reached.")
				return
			end

			if Speed < NextRebirthConfiguration.Speed then
				announceSell(Player, string.format("Reach %s speed to rebirth.", Format.Number(NextRebirthConfiguration.Speed)))
				return
			end

			ReplacePlayerDataEvent:Fire(Player, "Rebirths", Rebirths + 1)
			ReplacePlayerDataEvent:Fire(Player, "Speed", GameConfigurations.Defaults.Speed)

			Packets.rebirth.sendTo({
				Rebirths = Rebirths + 1,
				Speed = GameConfigurations.Defaults.Speed,
			}, Player)
		end)

		Packets.indexRequest.listen(function(Data, Player)
			if not isLoadedPlayer(Player) then return end
			if not Data or type(Data.Mutation) ~= "string" then return end
			if Data.Mutation ~= "Default" and not MutationsConfigurations[Data.Mutation] then return end
			if not RequestGuard.Allow(Player, "indexRequest", RequestCooldowns.Index) then return end

			local Index = PlayersModule.Retrieve(Player, "Index")

			Packets.indexSync.sendTo({
				Index = Index,
				Mutation = Data.Mutation,
			}, Player)
		end)

		Packets.equipInventory.listen(function(Data, Player)
			if not isLoadedPlayer(Player) or not Data then return end
			local Id = Data.Id
			if type(Id) ~= "string" or Id == "" then return end

			local _, ToolData = findToolDataById(Player, Id)
			if not ToolData or not ToolData.Tool then return end
			if not RequestGuard.Allow(Player, "equipInventory", RequestCooldowns.EquipInventory) then return end

			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
			if not Humanoid then return end

			if ToolData.Tool.Parent == Character then
				Humanoid:UnequipTools()
				if Player:GetAttribute("HoldState") == "Inventory" then
					Player:SetAttribute("HoldState", nil)
				end
			else
				equipInventoryTool(Player, ToolData)
			end

			if ctx.queueInventorySync then
				ctx.queueInventorySync(Player)
			else
				task.defer(syncInventory, Player)
			end
		end)

		Packets.sellInventory.listen(function(Data, Player)
			if not isLoadedPlayer(Player) or not Data then return end
			if Data.Mode ~= "Single" and Data.Mode ~= "All" then return end
			if Data.Mode == "Single" and (type(Data.Id) ~= "string" or Data.Id == "") then return end
			if Data.Mode == "All" and Data.Id ~= nil then return end
			if Data.Mode == "Single" and not findToolDataById(Player, Data.Id) then return end
			if not RequestGuard.Allow(Player, "sellInventory", RequestCooldowns.SellInventory) then return end

			sellInventory(Player, Data.Mode, Data.Id)
		end)

		Packets.updateHotbarSlot.listen(function(Data, Player)
			if not isLoadedPlayer(Player) or not Data then return end
			local Slot = Data.Slot
			local Id = Data.Id
			if not isPositiveInteger(Slot) or Slot > HOTBAR_MAX_SLOTS then return end
			if Id ~= nil and (type(Id) ~= "string" or Id == "") then return end
			if Id ~= nil and not findToolDataById(Player, Id) then return end
			if not RequestGuard.Allow(Player, "updateHotbarSlot", RequestCooldowns.UpdateHotbarSlot) then return end

			local PlayerData = PlayersData[Player]
			if not PlayerData then return end

			if setHotbarSlot(PlayerData, Slot, Id) then
				syncInventory(Player)
			end
		end)
	end

	ctx.setupPurchaseProcessing()
end
function PlayersModule.Create(Player)
	local PlayerData = setmetatable({}, {__index = PlayersModule})

	PlayerData.Player = Player
	PlayerData.Trove = Trove.new()

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
	Character:WaitForChild("Humanoid")

	applyPlayerMovementSpeed(Player)

	for _, Descendant in ipairs(Character:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		Descendant.CollisionGroup = "Players"
	end

	scheduleCharacterSpawnMove(Character, PlayerData.Trove)

	PlayerData.Trove:Connect(Player.CharacterAdded, function(Character)
		Character:WaitForChild("Humanoid")

		applyPlayerMovementSpeed(Player)

		for _, Descendant in ipairs(Character:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end

			Descendant.CollisionGroup = "Players"
		end

		scheduleCharacterSpawnMove(Character, PlayerData.Trove)

		local Base = PlayersData[Player].Base
		if not Base then return end

		local ProximityPrompt = Instance.new("ProximityPrompt")
		ProximityPrompt.Enabled = false
		ProximityPrompt.ActionText = "Give"
		ProximityPrompt.HoldDuration = 1
		ProximityPrompt.ObjectText = ""
		ProximityPrompt.RequiresLineOfSight = false
		ProximityPrompt.Parent = Character.PrimaryPart
		local CharacterTrove = PlayerData.Trove:Extend()
		CharacterTrove:Add(ProximityPrompt)
		CharacterTrove:Connect(Character.Destroying, function()
			CharacterTrove:Destroy()
		end)

		CharacterTrove:Connect(ProximityPrompt.Triggered, function(TriggeringPlayer)
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
			CharacterTrove:Add(task.spawn(function()
				if Player == OtherPlayer then return end

				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local Tool = Character:FindFirstChildOfClass("Tool")
				if not Tool then return end

				SetProperties.Client(OtherPlayer, ProximityPrompt, {Enabled = true})
			end))
		end
	end)

	PlayerData.Trove:Add(task.spawn(function()
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
		local CharacterTrove = PlayerData.Trove:Extend()
		CharacterTrove:Add(ProximityPrompt)
		CharacterTrove:Connect(Character.Destroying, function()
			CharacterTrove:Destroy()
		end)

		CharacterTrove:Connect(ProximityPrompt.Triggered, function(TriggeringPlayer)
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
			CharacterTrove:Add(task.spawn(function()
				if Player == OtherPlayer then return end

				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local Tool = Character:FindFirstChildOfClass("Tool")
				if not Tool then return end

				SetProperties.Client(OtherPlayer, ProximityPrompt, {Enabled = true})
			end))
		end
	end))

	PlayersData[Player] = PlayerData

	return PlayerData
end
	ctx.registerCollisionGroup = registerCollisionGroup
	ctx.setGroupsCollidable = setGroupsCollidable
	ctx.getActiveMovementSpeed = getActiveMovementSpeed
	ctx.applyPlayerMovementSpeed = applyPlayerMovementSpeed
end

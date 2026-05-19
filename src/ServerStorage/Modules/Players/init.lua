local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local TextChatService = game:GetService("TextChatService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Bases = require(ServerStorage.Modules:WaitForChild("Bases"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local ZoneTracker = require(ServerStorage.Modules:WaitForChild("ZoneTracker"))
local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))

local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local BaseConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("BaseConfigurations"))
local UpgradesConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("UpgradesConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("RebirthsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))
local CommandsConfigurations = require(ServerStorage.Configurations.Modules:WaitForChild("CommandsConfigurations"))

local MoneyDataStore = DataStoreService:GetOrderedDataStore("Money")
local SpeedDataStore = DataStoreService:GetOrderedDataStore("Speed")
local PlayerDataStore = DataStoreService:GetDataStore("Player")

local RetrieveThingDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveThingData")
local RetrievePlayerDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrievePlayerData")
local ReplacePlayerDataEvent = ServerStorage.Network.BindableEvents:WaitForChild("ReplacePlayerData")
local CreateToolEvent = ServerStorage.Network.BindableEvents:WaitForChild("CreateTool")

local MoneyEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Money")
local SpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Speed")
local CarryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Carry")
local RebirthEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Rebirth")
local AdminCommandEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("AdminCommand")
local IncrementSpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("IncrementSpeed")
local IncrementCarryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("IncrementCarry")
local AnnouncementEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Announcement")
local ToggleSpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("ToggleSpeed")
local IndexEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Index")
local AnimeUnlockedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("AnimeUnlocked")
local InventorySyncEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("InventorySync")
local SellInventoryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("SellInventory")
local EquipInventoryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("EquipInventory")
local UpdateHotbarSlotEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("UpdateHotbarSlot")

local PlayersData = {}

local PlayersModule = {}

local HeldModels = {}
local HeldInventoryCarry = {}
local AdminCommandDebounces = {}

local SELL_STATION_DISTANCE = 18
local HOTBAR_MAX_SLOTS = 10
local HELD_THING_GUI_MAX_DISTANCE = 50
local HELD_ANIME_WELD_NAME = "HeldAnimeWeld"
local HELD_ANIME_SIDE_OFFSET = 1
local HELD_ANIME_FORWARD_OFFSET = -1.55
local HELD_ANIME_VERTICAL_OFFSET = 3.1
local ADMIN_RICH_MONEY = 1000000000000000
local ADMIN_FAST_SPEED = 250
local RESET_COMMAND_NAME = "OwnerResetCommand"
local RICH_COMMAND_NAME = "OwnerRichCommand"
local FAST_COMMAND_NAME = "OwnerFastCommand"
local BASE_PROGRESSION_VERSION = 2
local LEGACY_BASE_LEVEL_TO_CURRENT = {
	[1] = 2,
	[2] = 4,
	[3] = 6,
	[4] = 8,
	[5] = 10
}

local function makeInventoryId()
	return HttpService:GenerateGUID(false)
end

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

local function getRebirthMultiplier(Rebirths)
	local RebirthConfiguration = RebirthsConfigurations[Rebirths]
	return RebirthConfiguration and RebirthConfiguration.Multiplier or 1
end

local function getToolSellValue(Name, Mutation, Level, Rebirths)
	local ThingConfiguration = ThingsConfigurations[Name]
	if not ThingConfiguration then return 0 end

	local LevelConfiguration = ThingConfiguration.Levels[Level or 1]
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
		if ThingsConfigurations[ToolData.Name] then
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

local function migrateBaseProgression(PlayerData, HasLoadedData)
	local SavedVersion = PlayerData.BaseProgressionVersion
	if not SavedVersion then
		SavedVersion = HasLoadedData and 1 or BASE_PROGRESSION_VERSION
	end

	if SavedVersion < BASE_PROGRESSION_VERSION then
		PlayerData.Level = LEGACY_BASE_LEVEL_TO_CURRENT[PlayerData.Level] or PlayerData.Level or 0
	end

	PlayerData.BaseProgressionVersion = BASE_PROGRESSION_VERSION
end

local function getBaseSlotCount(Level)
	local Configuration = BaseConfigurations[Level] or BaseConfigurations[0] or {}
	return Configuration.Slots or 0
end

local function findAnimeTemplate(Name, Mutation)
	local Animes = ServerStorage:FindFirstChild("Animes")
	if not Animes then return end

	local ThingConfiguration = ThingsConfigurations[Name]
	local Area = ThingConfiguration and ThingConfiguration.Area
	if not Area then return end

	local MutationFolder = Animes:FindFirstChild(Mutation or "Default")
	local AreaFolder = MutationFolder and MutationFolder:FindFirstChild(Area)
	local Template = AreaFolder and AreaFolder:FindFirstChild(Name)
	if Template then return Template end

	local DefaultFolder = Animes:FindFirstChild("Default")
	local DefaultAreaFolder = DefaultFolder and DefaultFolder:FindFirstChild(Area)
	return DefaultAreaFolder and DefaultAreaFolder:FindFirstChild(Name)
end

local function getHeldPreviewsFolder()
	local Folder = workspace:FindFirstChild("HeldPreviews")
	if Folder then return Folder end

	Folder = Instance.new("Folder")
	Folder.Name = "HeldPreviews"
	Folder.Parent = workspace

	return Folder
end

local function cleanVisualModel(Model)
	for _, Descendant in ipairs(Model:GetDescendants()) do
		if Descendant:IsA("Script") or Descendant:IsA("LocalScript") or Descendant:IsA("ModuleScript")
			or Descendant:IsA("ProximityPrompt") or Descendant:IsA("BillboardGui") or Descendant:IsA("SurfaceGui")
			or Descendant:IsA("Humanoid") or Descendant:IsA("AnimationController")
			or Descendant:IsA("JointInstance") or Descendant:IsA("Constraint") or Descendant:IsA("BodyMover")
			or Descendant:IsA("TouchTransmitter") then
			Descendant:Destroy()
		elseif Descendant:IsA("BasePart") then
			Descendant.Anchored = false
			Descendant.CanCollide = false
			Descendant.CanTouch = false
			Descendant.CanQuery = false
			Descendant.Massless = true
		end
	end
end

local function cleanHeldPreviewModel(Model)
	for _, Descendant in ipairs(Model:GetDescendants()) do
		if Descendant:IsA("Script") or Descendant:IsA("LocalScript") or Descendant:IsA("ModuleScript")
			or Descendant:IsA("ProximityPrompt") or Descendant:IsA("BillboardGui") or Descendant:IsA("SurfaceGui")
			or Descendant:IsA("ClickDetector") or Descendant:IsA("BodyMover") or Descendant:IsA("TouchTransmitter") then
			Descendant:Destroy()
		elseif Descendant:IsA("Humanoid") then
			Descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			Descendant.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			Descendant.NameDisplayDistance = 0
		elseif Descendant:IsA("BasePart") then
			Descendant.Anchored = false
			Descendant.CanCollide = false
			Descendant.CanTouch = false
			Descendant.CanQuery = false
			Descendant.Massless = true
		end
	end
end

local function forceVisualOnly(Model)
	for _, Descendant in ipairs(Model:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		Descendant.Anchored = false
		Descendant.CanCollide = false
		Descendant.CanTouch = false
		Descendant.CanQuery = false
		Descendant.Massless = true
		pcall(function()
			Descendant.CollisionGroup = "HeldPreviews"
		end)
	end
end

local function getHeldAnimeCFrame(Root)
	return Root.CFrame * CFrame.new(HELD_ANIME_SIDE_OFFSET, HELD_ANIME_VERTICAL_OFFSET, HELD_ANIME_FORWARD_OFFSET)
end

local function getModelPrimaryPart(Model)
	if Model.PrimaryPart then return Model.PrimaryPart end

	local PrimaryPart = Model:FindFirstChild("HumanoidRootPart") or Model:FindFirstChildWhichIsA("BasePart", true)
	if PrimaryPart then
		Model.PrimaryPart = PrimaryPart
	end

	return PrimaryPart
end

local function weldLooseVisualParts(Model, PrimaryPart)
	for _, Descendant in ipairs(Model:GetDescendants()) do
		if not Descendant:IsA("BasePart") or Descendant == PrimaryPart then continue end
		if Descendant:FindFirstAncestorOfClass("Accessory") then continue end
		if Descendant:FindFirstChildWhichIsA("JointInstance") then continue end

		local HasExistingJoint = false
		for _, Joint in ipairs(Descendant:GetJoints()) do
			if Joint.Part0 == PrimaryPart or Joint.Part1 == PrimaryPart then
				HasExistingJoint = true
				break
			end
		end

		if HasExistingJoint then continue end

		local Weld = Instance.new("WeldConstraint")
		Weld.Part0 = PrimaryPart
		Weld.Part1 = Descendant
		Weld.Parent = PrimaryPart
	end
end

local function getHeldMutationAuraParts(Model)
	local PreferredParts = {
		"Head",
		"UpperTorso",
		"Torso",
		"LowerTorso",
		"LeftUpperArm",
		"Left Arm",
		"RightUpperArm",
		"Right Arm",
		"LeftUpperLeg",
		"Left Leg",
		"RightUpperLeg",
		"Right Leg"
	}

	local AuraParts = {}

	for _, PartName in ipairs(PreferredParts) do
		local Part = Model:FindFirstChild(PartName, true)
		if Part and Part:IsA("BasePart") and Part.Transparency < 0.95 then
			table.insert(AuraParts, Part)
		end
	end

	if #AuraParts == 0 then
		for _, Descendant in ipairs(Model:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end
			if Descendant == Model.PrimaryPart then continue end
			if Descendant.Transparency >= 0.95 then continue end

			table.insert(AuraParts, Descendant)

			if #AuraParts >= 6 then break end
		end
	end

	if #AuraParts == 0 and Model.PrimaryPart then
		table.insert(AuraParts, Model.PrimaryPart)
	end

	return AuraParts
end

local function applyHeldMutationVisual(Model, Mutation)
	local MutationConfiguration = MutationsConfigurations[Mutation]
	if not MutationConfiguration or Mutation == "Default" then return end

	local AuraConfiguration = MutationConfiguration.Aura
	if not AuraConfiguration then return end

	local HighlightConfiguration = AuraConfiguration.Highlight
	if HighlightConfiguration then
		local Highlight = Instance.new("Highlight")
		Highlight.Name = "HeldMutationHighlight"
		Highlight.Adornee = Model
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = HighlightConfiguration.FillColor or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Highlight.FillTransparency = HighlightConfiguration.FillTransparency or 0.65
		Highlight.OutlineColor = HighlightConfiguration.OutlineColor or Highlight.FillColor
		Highlight.OutlineTransparency = HighlightConfiguration.OutlineTransparency or 0.15
		Highlight.Parent = Model
	end

	local ParticleConfiguration = AuraConfiguration.Particle
	if ParticleConfiguration then
		for _, Part in ipairs(getHeldMutationAuraParts(Model)) do
			local AuraAttachment = Instance.new("Attachment")
			AuraAttachment.Name = "HeldMutationAuraAttachment"
			AuraAttachment.Parent = Part

			local Particle = Instance.new("ParticleEmitter")
			Particle.Name = "HeldMutationAura"
			Particle.Texture = ParticleConfiguration.Texture or "rbxasset://textures/particles/sparkles_main.dds"
			Particle.Color = ParticleConfiguration.Color or ColorSequence.new(MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255))
			Particle.LightEmission = ParticleConfiguration.LightEmission or 0.75
			Particle.LightInfluence = ParticleConfiguration.LightInfluence or 0
			Particle.Rate = ParticleConfiguration.Rate or 12
			Particle.Lifetime = ParticleConfiguration.Lifetime or NumberRange.new(0.8, 1.3)
			Particle.Speed = ParticleConfiguration.Speed or NumberRange.new(0.5, 1.2)
			Particle.SpreadAngle = ParticleConfiguration.SpreadAngle or Vector2.new(360, 360)
			Particle.Size = ParticleConfiguration.Size or NumberSequence.new(0.25)
			Particle.Transparency = ParticleConfiguration.Transparency or NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(1, 1)
			})
			Particle.Parent = AuraAttachment
		end
	end

	local LightConfiguration = AuraConfiguration.Light
	if LightConfiguration and Model.PrimaryPart then
		local Light = Instance.new("PointLight")
		Light.Name = "HeldMutationAuraLight"
		Light.Color = LightConfiguration.Color or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Light.Brightness = LightConfiguration.Brightness or 0.6
		Light.Range = LightConfiguration.Range or 8
		Light.Parent = Model.PrimaryPart
	end
end

local function createHeldThingGui(Model, Name, ThingConfiguration, Mutation, Level, RebirthMultiplier)
	local PrimaryPart = Model.PrimaryPart
	if not PrimaryPart then return end

	local ThingsModule = ServerStorage.Modules:WaitForChild("Things")
	local Resources = ThingsModule:WaitForChild("Resources")
	local ThingGui = Resources:WaitForChild("ThingGui"):Clone()

	local TimeLabel = ThingGui:FindFirstChild("Time")
	if TimeLabel then
		TimeLabel:Destroy()
	end

	local CarriedLabel = ThingGui:FindFirstChild("Carried")
	if CarriedLabel then
		CarriedLabel:Destroy()
	end

	ThingGui.Mutation.LayoutOrder = 0
	ThingGui.Area.LayoutOrder = 1
	ThingGui.Thing.LayoutOrder = 2
	ThingGui.Money.LayoutOrder = 3

	for _, LabelName in ipairs({"Mutation", "Thing", "Area", "Money"}) do
		local Label = ThingGui:FindFirstChild(LabelName)
		if Label and Label:IsA("TextLabel") then
			Label.Size = UDim2.new(0.9, 0, Label.Size.Y.Scale, Label.Size.Y.Offset)
		end
	end

	local Area = ThingConfiguration.Area
	local AreaConfiguration = Area and AreasConfigurations[Area]
	local MutationConfiguration = MutationsConfigurations[Mutation] or {}
	local Multiplier = MutationConfiguration.Multiplier or 1
	local LevelConfiguration = ThingConfiguration.Levels and ThingConfiguration.Levels[Level] or {}
	RebirthMultiplier = RebirthMultiplier or 1

	ThingGui.Thing.Text = string.format("%s (Lvl %s)", Name, Level)
	ThingGui.Area.Text = Area or ""
	ThingGui.Area.TextColor3 = AreaConfiguration and AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)
	ThingGui.Money.Text = string.format("$%s/s", Format.Number((LevelConfiguration.Money or 0) * Multiplier * RebirthMultiplier))
	ThingGui.Money.Visible = true

	if Mutation and Mutation ~= "Default" then
		ThingGui.Mutation.Text = Mutation
		ThingGui.Mutation.TextColor3 = MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		ThingGui.Mutation.Visible = true
	else
		ThingGui.Mutation.Visible = false
	end

	local ExistingAttachment = PrimaryPart:FindFirstChild("ThingAttachment")
	if ExistingAttachment then
		ExistingAttachment:Destroy()
	end

	local ThingAttachment = Instance.new("Attachment")
	ThingAttachment.Name = "ThingAttachment"
	ThingAttachment.CFrame = CFrame.new(Vector3.new(0, (ThingConfiguration.YOffset or 0) + ThingGui.Size.Y.Scale / 2 + 1, 0))
	ThingAttachment.Parent = PrimaryPart

	ThingGui.Parent = ThingAttachment
	ThingGui.MaxDistance = HELD_THING_GUI_MAX_DISTANCE
	ThingGui.Enabled = true
end

local function removeHeldAnimeWeld(Player)
	local Character = Player.Character
	local Root = Character and (Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart"))
	if not Root then return end

	for _, Child in ipairs(Root:GetChildren()) do
		if Child:IsA("WeldConstraint") and Child.Name == HELD_ANIME_WELD_NAME then
			Child:Destroy()
		end
	end
end

local function removeHeldModel(Player)
	removeHeldAnimeWeld(Player)

	local Existing = HeldModels[Player]
	if Existing then
		Existing:Destroy()
		HeldModels[Player] = nil
	end

	if HeldInventoryCarry[Player] then
		HeldInventoryCarry[Player] = nil

		PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.OwnedHold, false)
	end
end

local function createHeldModel(Player, Name, Mutation, Level)
	removeHeldModel(Player)

	local Character = Player.Character
	if not Character then return end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Root = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
	if not Humanoid or not Root then return end

	local Template = findAnimeTemplate(Name, Mutation)
	if not Template then return end

	local ThingConfiguration = ThingsConfigurations[Name]
	if not ThingConfiguration then return end
	Level = Level or 1

	local Model = Template:Clone()
	Model.Name = string.format("Held%s", Name)
	cleanHeldPreviewModel(Model)

	local PrimaryPart = getModelPrimaryPart(Model)
	if not PrimaryPart then
		Model:Destroy()
		return
	end

	weldLooseVisualParts(Model, PrimaryPart)
	applyHeldMutationVisual(Model, Mutation)
	local PlayerData = PlayersData[Player]
	local RebirthMultiplier = getRebirthMultiplier(PlayerData and PlayerData.Rebirths or 0)
	createHeldThingGui(Model, Name, ThingConfiguration, Mutation, Level, RebirthMultiplier)

	Model:PivotTo(getHeldAnimeCFrame(Root))

	local Weld = Instance.new("WeldConstraint")
	Weld.Name = HELD_ANIME_WELD_NAME
	Weld.Part0 = Root
	Weld.Part1 = PrimaryPart
	Weld.Parent = Root

	Model.Parent = getHeldPreviewsFolder()
	forceVisualOnly(Model)

	task.defer(function()
		if Model.Parent then
			forceVisualOnly(Model)
		end
	end)

	HeldModels[Player] = Model
	HeldInventoryCarry[Player] = true

	PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.OwnedHold, true)
end

local function equipInventoryTool(Player, ToolData)
	if not ToolData or not ToolData.Tool then return false end

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return false end

	ToolData.Tool.Parent = Player:WaitForChild("Backpack")
	Humanoid:EquipTool(ToolData.Tool)
	createHeldModel(Player, ToolData.Name, ToolData.Mutation, ToolData.Level)

	return true
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
		if not ThingsConfigurations[ToolData.Name] then continue end

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

	InventorySyncEvent:FireClient(Player, getInventorySnapshot(Player))
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

local function removeToolData(Player, Index, ToolData)
	removeHeldModel(Player)

	if ToolData and ToolData.Tool then
		ToolData.Tool:Destroy()
	end

	local PlayerData = PlayersData[Player]
	if not PlayerData then return end

	table.remove(PlayerData.Tools, Index)
	normalizeHotbarOrder(PlayerData)
	syncInventory(Player)
end

local function reconcileIndex(ExistingIndex)
	local Index = {}

	for Mutation in pairs(MutationsConfigurations) do
		Index[Mutation] = {}

		for Thing in pairs(ThingsConfigurations) do
			Index[Mutation][Thing] = ExistingIndex
				and ExistingIndex[Mutation]
				and ExistingIndex[Mutation][Thing] == true
				or false
		end
	end

	return Index
end

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

	local Slots = Base:FindFirstChild("Slots")
	if Slots then
		for _, Slot in ipairs(Slots:GetChildren()) do
			Bases.Remove(Base, Slot, true)
		end
	end

	local Level = Base:FindFirstChild("Level")
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

	PlayersModule.Replace(Player, "Things", {})
	PlayersModule.Replace(Player, "Tools", {})
	PlayersModule.Replace(Player, "HotbarOrder", {})
	PlayersModule.Replace(Player, "Index", reconcileIndex(nil))
	PlayersModule.Replace(Player, "Steals", 0)
	PlayersModule.Replace(Player, "Money", GameConfigurations.Defaults.Money)
	PlayersModule.Replace(Player, "Speed", GameConfigurations.Defaults.Speed)
	PlayersModule.Replace(Player, "Carry", GameConfigurations.Defaults.Carry)
	PlayersModule.Replace(Player, "Rebirths", 0)
	PlayersModule.Replace(Player, "Level", 0)
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

function PlayersModule.Setup()
	setupOwnerTextChatCommands()

	registerCollisionGroup("Players")
	registerCollisionGroup("Things")
	registerCollisionGroup("HeldPreviews")
	setGroupsCollidable("Players", "Things", false)
	setGroupsCollidable("Players", "Players", false)
	setGroupsCollidable("HeldPreviews", "Default", false)
	setGroupsCollidable("HeldPreviews", "Players", false)
	setGroupsCollidable("HeldPreviews", "Things", false)
	setGroupsCollidable("HeldPreviews", "HeldPreviews", false)

	local SellStation = getSellStation()
	if SellStation then
		ZoneTracker.RegisterZone("Sell", SellStation)
	else
		warn("Missing sell station zone: Workspace.Sell.Toggle")
	end

	Players.PlayerAdded:Connect(function(Player)
		Player.Chatted:Connect(function(Message)
			handlePlayerCommand(Player, Message)
		end)

		PlayersModule.Create(Player)
	end)

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

	MarketplaceService.ProcessReceipt = function(ReceiptInfo)
		local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
		if not Player then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local ProductId = ReceiptInfo.ProductId

		if ProductId == GameConfigurations.ProductsIds.Steal then
			local StealingData = PlayersData[Player].Stealing
			if not StealingData then return end

			local StolenPlayer = StealingData.Player
			local Base = StealingData.Base
			local Slot = StealingData.Slot

			if StolenPlayer == Bases.Retrieve(Base, "Player") then
				local Thing = Bases.Retrieve(Base, "SlotsData")[Slot.Name] and Bases.Retrieve(Base, "SlotsData")[Slot.Name].Thing 
				if not Thing then return end

				local Name = Thing.Name

				local ThingConfiguration = ThingsConfigurations[Name]
				if not ThingConfiguration then return end

				local Mutation = RetrieveThingDataFunction:Invoke(Thing, "Mutation")
				if not Mutation then return end

				local Level = RetrieveThingDataFunction:Invoke(Thing, "Level")
				if not Level then Level = 1 end

				CreateToolEvent:Fire(Player, Name, ThingConfiguration, Mutation, Level)

				Bases.Remove(Base, Slot)

				local AreaConfiguration = AreasConfigurations[ThingConfiguration.Area]
				if not AreaConfiguration then return end

				local Colour = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

				Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)

				local Text = string.format("%s stole your <font color=\"%s\">%s</font> Thing!", Player.Name, Colour, Name)

				AnnouncementEvent:FireClient(StolenPlayer, Text)

				local Text = string.format("You stole %s's <font color=\"%s\">%s</font> Thing!", StolenPlayer.Name, Colour, Name)

				AnnouncementEvent:FireClient(Player, Text)
			else
				ReplacePlayerDataEvent:Fire(Player, "Steals", RetrievePlayerDataFunction:Invoke(Player, "Steals") + 1)
			end
		elseif ProductId == GameConfigurations.ProductsIds.SkipRebirth then
			local Rebirths = PlayersModule.Retrieve(Player, "Rebirths")
			local Speed = PlayersModule.Retrieve(Player, "Speed")

			if not RebirthsConfigurations[Rebirths + 1] then return end

			ReplacePlayerDataEvent:Fire(Player, "Rebirths", Rebirths + 1)

			RebirthEvent:FireClient(Player, Rebirths + 1, Speed)
		end

		for Upgrade, UpgradeConfiguration in pairs(UpgradesConfigurations) do
			if UpgradeConfiguration.ProductId ~= ProductId then continue end

			local Type, Increment = Upgrade:match("([A-Za-z]+)(%d+)")
			if not Type or not Increment then continue end

			Increment = tonumber(Increment)

			if Type == "Speed" then
				PlayersModule.Replace(Player, "Speed", PlayersModule.Retrieve(Player, "Speed") + Increment)
			elseif Type == "Carry" then
				PlayersModule.Replace(Player, "Carry", PlayersModule.Retrieve(Player, "Carry") + Increment)
			end

			break
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
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
				if not ToolData or not ThingsConfigurations[ToolData.Name] then continue end

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

		MoneyEvent:FireClient(Player, Value)
	elseif Name == "MoneyPerSecond" then
		local Leaderstats = Player:WaitForChild("leaderstats")
		local MoneyPerSecond = Leaderstats:WaitForChild("$/s")

		MoneyPerSecond.Value = string.format("%s/s", Format.Number(PlayerData.MoneyPerSecond))
	elseif Name == "Speed" then
		SpeedEvent:FireClient(Player, Value)
		RebirthEvent:FireClient(Player, PlayerData.Rebirths, Value)
		
		ToggleSpeedEvent:FireClient(Player)
	elseif Name == "Carry" then
		CarryEvent:FireClient(Player, Value)
	elseif Name == "Rebirths" then
		RebirthEvent:FireClient(Player, Value, PlayerData.Speed)
		
		local RebirthMultiplier = getRebirthMultiplier(PlayerData.Rebirths)

		if PlayerData.Base and PlayerData.Base:FindFirstChild("Data") and PlayerData.Base.Data:FindFirstChild("DataGui") then
			PlayerData.Base.Data.DataGui.Rebirths.Text = string.format("Rebirth %s (%sx $)", PlayerData.Rebirths, RebirthMultiplier)
		end
		
		local MoneyPerSecond = 0

		local ThingsData = RetrievePlayerDataFunction:Invoke(Player, "Things")
		for _, ThingData in ipairs(ThingsData) do
			local Name = ThingData.Name
			local ThingConfiguration = ThingsConfigurations[Name]
			local Mutation = ThingData.Mutation
			local MutationConfiguration = MutationsConfigurations[Mutation]
			local Level = ThingData.Level or 1

			local Multiplier = MutationConfiguration.Multiplier or 1

			MoneyPerSecond += ThingConfiguration.Levels[Level].Money * Multiplier
		end

		local RebirthMutiplier = RebirthsConfigurations[Value] and RebirthsConfigurations[Value].Multiplier or 1

		MoneyPerSecond = MoneyPerSecond * RebirthMutiplier

		ReplacePlayerDataEvent:Fire(Player, "MoneyPerSecond", MoneyPerSecond)

		if PlayerData.Base and PlayerData.Base:FindFirstChild("Data") and PlayerData.Base.Data:FindFirstChild("DataGui") then
			PlayerData.Base.Data.DataGui.MoneyPerSecond.Text = string.format("%s/s", Format.Number(MoneyPerSecond))
		end

		Bases.RefreshPlayerEconomyDisplays(Player)
		syncInventory(Player)
	elseif Name == "Level" then
		local Base = PlayerData.Base

		if Base then
			Bases.Level(PlayerData, Base)
		end
	elseif Name == "Index" then
		IndexEvent:FireClient(Player, Value)
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

			task.delay(1, function()
				if AnimationTrack.Length == 0 then
					warn(string.format("Hold animation %s loaded with length 0 for %s; verify the asset works with this rig.", tostring(AnimationId), Player.Name))
				end
			end)
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

	Player.CharacterAdded:Connect(function(Character)
		local Humanoid = Character:WaitForChild("Humanoid")

		Humanoid.WalkSpeed = PlayerData.Speed

		for _, Descendant in ipairs(Character:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end

			Descendant.CollisionGroup = "Players"
		end

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

				local ThingConfiguration = ThingsConfigurations[Name]
				if not ThingConfiguration then return end

				table.remove(ToolsData, Index)

				PlayersModule.Replace(TriggeringPlayer, "Tools", ToolsData)

				Tool:Destroy()

				PlayersModule.Tool(Player, Name, ThingConfiguration, Mutation, Level)

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

				local ThingConfiguration = ThingsConfigurations[Name]
				if not ThingConfiguration then return end
				
				table.remove(ToolsData, Index)

				PlayersModule.Replace(TriggeringPlayer, "Tools", ToolsData)

				Tool:Destroy()
				
				PlayersModule.Tool(Player, Name, ThingConfiguration, Mutation, Level)
				
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

function PlayersModule.Tool(Player, Name, ThingConfiguration, Mutation, Level, ToolIndex, ToolData, AutoEquip)
	if typeof(ToolIndex) == "boolean" and ToolData == nil and AutoEquip == nil then
		AutoEquip = ToolIndex
		ToolIndex = nil
	end

	local Data = {}
	Mutation = Mutation or "Default"

	local Tool = script.Resources:WaitForChild("Tool")

	Tool = Tool:Clone()

	local Id = ToolData and ToolData.Id or makeInventoryId()

	Data.Tool = Tool
	Data.Id = Id
	Data.Name = Name
	Data.Mutation = Mutation
	Data.Level = Level or 1

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
	
	Tool.Equipped:Connect(function()
		createHeldModel(Player, Name, Mutation, Data.Level)
		syncInventory(Player)

		local Base = PlayersData[Player] and PlayersData[Player].Base
		if not Base then return end

		local SlotsData = Bases.Retrieve(Base, "SlotsData")
		if not SlotsData then return end

		for _, Slot in ipairs(Base.Slots:GetChildren()) do
			task.spawn(function()
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

				if getBaseSlotCount(PlayersData[Player].Level) < tonumber(Slot.Name) then return end

				if SlotsData[Slot.Name] and SlotsData[Slot.Name].Thing then
					SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = true})
				else
					SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = true})
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

	Tool.Unequipped:Connect(function()
		removeHeldModel(Player)
		syncInventory(Player)

		local Base = PlayersData[Player].Base
		if not Base then return end

		local SlotsData = Bases.Retrieve(Base, "SlotsData")
		if not SlotsData then return end

		for _, Slot in ipairs(Base.Slots:GetChildren()) do
			task.spawn(function()
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

				if not (SlotsData[Slot.Name] and SlotsData[Slot.Name].Thing) then return end
				if getBaseSlotCount(PlayersData[Player].Level) < tonumber(Slot.Name) then return end

				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = true})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = true})
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
	Tool.TextureId = ThingConfiguration.Icons[Mutation]
	Tool.RequiresHandle = false
	Tool:SetAttribute("InventoryId", Id)
	Tool:SetAttribute("Mutation", Mutation)
	Tool:SetAttribute("Level", Data.Level)

	if ToolIndex and ToolData then
		ToolData.Id = Id
		ToolData.Tool = Tool

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
	else
		task.defer(syncInventory, Player)
	end

	return Data
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
	if not self.Level then self.Level = 0 end
	if not self.Things then self.Things = {} end
	if not self.Steals then self.Steals = 0 end
	if not self.Rebirths then self.Rebirths = 0 end
	if not self.HotbarOrder then self.HotbarOrder = {} end

	migrateBaseProgression(self, Success and Data ~= nil)
	
	for Index = #self.Tools, 1, -1 do
		local ToolConfiguration = self.Tools[Index]
		if ThingsConfigurations[ToolConfiguration.Name] then
			ToolConfiguration.Id = ToolConfiguration.Id or makeInventoryId()
			self.Tools[Index] = ToolConfiguration
		else
			table.remove(self.Tools, Index)
		end
	end

	normalizeHotbarOrder(self)
	
	for Index = #self.Things, 1, -1 do
		local ThingConfiguration = self.Things[Index]
		if ThingsConfigurations[ThingConfiguration.Name] then continue end

		table.remove(self.Things, Index)
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
				local Thing = ToolData.Name
				local ThingConfiguration = ThingsConfigurations[Thing]

				PlayersModule.Tool(Player, Thing, ThingConfiguration, ToolData.Mutation, ToolData.Level, Index, ToolData)
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
					local Thing = ToolData.Name
					local ThingConfiguration = ThingsConfigurations[Thing]

					PlayersModule.Tool(Player, Thing, ThingConfiguration, ToolData.Mutation, ToolData.Level, Index, ToolData)
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
		Things = self.Things,
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

return PlayersModule

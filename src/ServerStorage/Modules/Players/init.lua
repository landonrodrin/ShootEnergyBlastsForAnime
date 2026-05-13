local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
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
local IncrementSpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("IncrementSpeed")
local IncrementCarryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("IncrementCarry")
local AnnouncementEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Announcement")
local ToggleSpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("ToggleSpeed")
local IndexEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Index")
local InventorySyncEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("InventorySync")
local SellInventoryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("SellInventory")
local EquipInventoryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("EquipInventory")
local UpdateHotbarSlotEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("UpdateHotbarSlot")

local PlayersData = {}

local PlayersModule = {}

local HeldModels = {}
local HeldInventoryCarry = {}

local SELL_STATION_DISTANCE = 18
local HOTBAR_MAX_SLOTS = 10

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

local function getToolSellValue(Name, Mutation, Level)
	local ThingConfiguration = ThingsConfigurations[Name]
	if not ThingConfiguration then return 0 end

	local LevelConfiguration = ThingConfiguration.Levels[Level or 1]
	if not LevelConfiguration then return 0 end

	local MutationConfiguration = MutationsConfigurations[Mutation] or {}
	local Multiplier = MutationConfiguration.Multiplier or 1

	return math.round((LevelConfiguration.Sell or 0) * Multiplier)
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
	local HighlightConfiguration = AuraConfiguration and AuraConfiguration.Highlight

	local Highlight = Instance.new("Highlight")
	Highlight.Name = "HeldMutationHighlight"
	Highlight.Adornee = Model
	Highlight.FillColor = HighlightConfiguration and HighlightConfiguration.FillColor or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
	Highlight.FillTransparency = HighlightConfiguration and HighlightConfiguration.FillTransparency or 0.7
	Highlight.OutlineColor = HighlightConfiguration and HighlightConfiguration.OutlineColor or Highlight.FillColor
	Highlight.OutlineTransparency = HighlightConfiguration and HighlightConfiguration.OutlineTransparency or 0.25
	Highlight.Parent = Model

	local ParticleConfiguration = AuraConfiguration and AuraConfiguration.Particle
	if ParticleConfiguration then
		for _, Part in ipairs(getHeldMutationAuraParts(Model)) do
			local AuraAttachment = Instance.new("Attachment")
			AuraAttachment.Name = "HeldMutationAuraAttachment"
			AuraAttachment.Parent = Part

			local Particle = Instance.new("ParticleEmitter")
			Particle.Name = "HeldMutationAura"
			Particle.Texture = ParticleConfiguration.Texture or "rbxasset://textures/particles/sparkles_main.dds"
			Particle.Color = ParticleConfiguration.Color or ColorSequence.new(MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255))
			Particle.LightEmission = ParticleConfiguration.LightEmission or 0.8
			Particle.Rate = ParticleConfiguration.Rate or 24
			Particle.Lifetime = ParticleConfiguration.Lifetime or NumberRange.new(1, 1.5)
			Particle.Speed = ParticleConfiguration.Speed or NumberRange.new(0.8, 1.8)
			Particle.SpreadAngle = ParticleConfiguration.SpreadAngle or Vector2.new(360, 360)
			Particle.Size = ParticleConfiguration.Size or NumberSequence.new(0.25)
			Particle.Transparency = ParticleConfiguration.Transparency or NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(1, 1)
			})
			Particle.Parent = AuraAttachment
		end
	end

	local LightConfiguration = AuraConfiguration and AuraConfiguration.Light
	if LightConfiguration and Model.PrimaryPart then
		local Light = Instance.new("PointLight")
		Light.Name = "HeldMutationAuraLight"
		Light.Color = LightConfiguration.Color or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Light.Brightness = LightConfiguration.Brightness or 0.8
		Light.Range = LightConfiguration.Range or 8
		Light.Parent = Model.PrimaryPart
	end
end

local function removeHeldModel(Player)
	local Existing = HeldModels[Player]
	if Existing then
		Existing:Destroy()
		HeldModels[Player] = nil
	end

	if HeldInventoryCarry[Player] then
		HeldInventoryCarry[Player] = nil

		local PlayerData = PlayersData[Player]
		if not (PlayerData and PlayerData.Carrying) then
			PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.Carry, false)
		end
	end
end

local function createHeldModel(Player, Name, Mutation)
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

	local YOffset = Humanoid.HipHeight + Root.Size.Y / 2 + (ThingConfiguration.YOffset or 0) + 1
	Model:PivotTo(Root.CFrame + Vector3.new(0, YOffset, 0))

	local Weld = Instance.new("WeldConstraint")
	Weld.Name = "HeldAnimeWeld"
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

	PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.Carry, true)
end

local function setupAnimePreviews()
	local Existing = ReplicatedStorage:FindFirstChild("AnimePreviews")
	if Existing then Existing:Destroy() end

	local Folder = Instance.new("Folder")
	Folder.Name = "AnimePreviews"
	Folder.Parent = ReplicatedStorage

	for Name in pairs(ThingsConfigurations) do
		local Template = findAnimeTemplate(Name, "Default")
		if not Template then continue end

		local Preview = Template:Clone()
		Preview.Name = Name
		cleanVisualModel(Preview)

		for _, Descendant in ipairs(Preview:GetDescendants()) do
			if Descendant:IsA("BasePart") then
				Descendant.Anchored = true
			end
		end

		Preview.Parent = Folder
	end
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
			Sell = getToolSellValue(ToolData.Name, ToolData.Mutation, ToolData.Level or 1)
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

function PlayersModule.Setup()
	setupAnimePreviews()

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
		PlayersModule.Create(Player)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		local PlayerData = PlayersData[Player]

		PlayerData:Save()
		
		ZoneTracker.ClearPlayer(Player)
		removeHeldModel(Player)
		HeldInventoryCarry[Player] = nil
	end)

	game:BindToClose(function()
		for Player, PlayerData in pairs(PlayersData) do
			PlayerData:Save()
		end
	end)

	RetrievePlayerDataFunction.OnInvoke = PlayersModule.Retrieve

	ReplacePlayerDataEvent.Event:Connect(PlayersModule.Replace)
	CreateToolEvent.Event:Connect(PlayersModule.Tool)

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
			ToolData.Tool.Parent = Player:WaitForChild("Backpack")
			Humanoid:EquipTool(ToolData.Tool)
			createHeldModel(Player, ToolData.Name, ToolData.Mutation)
			PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.Carry, true)
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

			Total += getToolSellValue(ToolData.Name, ToolData.Mutation, ToolData.Level or 1)
			removeToolData(Player, Index, ToolData)
		elseif Mode == "All" then
			for Index = #PlayerData.Tools, 1, -1 do
				local ToolData = PlayerData.Tools[Index]
				if not ToolData or not ThingsConfigurations[ToolData.Name] then continue end

				Total += getToolSellValue(ToolData.Name, ToolData.Mutation, ToolData.Level or 1)
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
		
		local Character = Player.Character
		if not Character then return end
		
		local MoneyPerSecondAttachment = Character.PrimaryPart:FindFirstChild("MoneyPerSecondAttachment")
		local MoneyPerSecondGui = MoneyPerSecondAttachment and MoneyPerSecondAttachment:FindFirstChild("MoneyPerSecondGui")
		
		if not MoneyPerSecondGui then return end

		MoneyPerSecondGui.MoneyPerSecond.Text = MoneyPerSecond.Value
	elseif Name == "Speed" then
		SpeedEvent:FireClient(Player, Value)
		RebirthEvent:FireClient(Player, PlayerData.Rebirths, Value)
		
		ToggleSpeedEvent:FireClient(Player)
	elseif Name == "Carry" then
		CarryEvent:FireClient(Player, Value)
	elseif Name == "Rebirths" then
		RebirthEvent:FireClient(Player, Value, PlayerData.Speed)
		
		PlayerData.Base.Data.DataGui.Rebirths.Text = string.format("Rebirth %s (%sx $)", PlayerData.Rebirths, RebirthsConfigurations[PlayerData.Rebirths].Multiplier)
		
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

		PlayerData.Base.Data.DataGui.MoneyPerSecond.Text = string.format("%s/s", Format.Number(MoneyPerSecond))
	elseif Name == "Level" then
		local Base = PlayerData.Base

		Bases.Level(PlayerData, Base)
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

		if AnimationId == GameConfigurations.AnimationsIds.Carry then
			AnimationTrack.Looped = true
			AnimationTrack.Priority = Enum.AnimationPriority.Action4

			task.delay(1, function()
				if AnimationTrack.Length == 0 then
					warn(string.format("Carry animation %s loaded with length 0 for %s; verify the asset works with this rig.", tostring(AnimationId), Player.Name))
				end
			end)
		end

		Tracks[AnimationId] = AnimationTrack
	end

	if Bool then
		if AnimationId == GameConfigurations.AnimationsIds.Carry then
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

		local YOffset = Character.Humanoid.HipHeight + Character.PrimaryPart.Size.Y / 2
		
		local MoneyPerSecondAttachment = Instance.new("Attachment")
		MoneyPerSecondAttachment.Name = "MoneyPerSecondAttachment"
		MoneyPerSecondAttachment.Parent = Character.PrimaryPart
		
		local MoneyPerSecondGui = script.Resources:WaitForChild("MoneyPerSecondGui")
		
		MoneyPerSecondGui = MoneyPerSecondGui:Clone()
		
		MoneyPerSecondGui.MoneyPerSecond.Text = MoneyPerSecond.Value
		
		MoneyPerSecondGui.Parent = MoneyPerSecondAttachment
		MoneyPerSecondGui.Enabled = true
		
		MoneyPerSecondAttachment.Position = Vector3.new(0, YOffset + MoneyPerSecondGui.Size.Y.Scale / 2 + 1, 0)
		
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

		local YOffset = Character.Humanoid.HipHeight + Character.PrimaryPart.Size.Y / 2
		
		local MoneyPerSecondAttachment = Instance.new("Attachment")
		MoneyPerSecondAttachment.Name = "MoneyPerSecondAttachment"
		MoneyPerSecondAttachment.Parent = Character.PrimaryPart

		local MoneyPerSecondGui = script.Resources:WaitForChild("MoneyPerSecondGui")

		MoneyPerSecondGui = MoneyPerSecondGui:Clone()

		MoneyPerSecondGui.MoneyPerSecond.Text = MoneyPerSecond.Value

		MoneyPerSecondGui.Parent = MoneyPerSecondAttachment
		MoneyPerSecondGui.Enabled = true
		
		MoneyPerSecondAttachment.Position = Vector3.new(0, YOffset + MoneyPerSecondGui.Size.Y.Scale / 2 + 1, 0)
		
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

function PlayersModule.Tool(Player, Name, ThingConfiguration, Mutation, Level, Index, ToolData)
	local Data = {}

	local Tool = script.Resources:WaitForChild("Tool")

	Tool = Tool:Clone()

	local Id = ToolData and ToolData.Id or makeInventoryId()

	Data.Tool = Tool
	Data.Id = Id
	Data.Name = Name
	Data.Mutation = Mutation
	Data.Level = Level or 1

	local Index = PlayersData[Player] and PlayersData[Player].Index
	if Index and Index[Mutation] and not Index[Mutation][Name] then
		PlayersData[Player].Index[Mutation][Name] = true
		
		IndexEvent:FireClient(Player, PlayersData[Player].Index)
	end
	
	Tool.Equipped:Connect(function()
		createHeldModel(Player, Name, Mutation)
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

				if BaseConfigurations[PlayersData[Player].Level].Slots < tonumber(Slot.Name) then return end

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
				if BaseConfigurations[PlayersData[Player].Level].Slots < tonumber(Slot.Name) then return end

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

	if Index and ToolData then
		ToolData.Id = Id
		ToolData.Tool = Tool

		PlayersData[Player].Tools[Index] = ToolData
	else
		local Tools = PlayersData[Player].Tools
		if not Tools then Tools = {} end

		table.insert(Tools, Data)

		PlayersData[Player].Tools = Tools
	end

	Tool.Parent = Player.Backpack
	normalizeHotbarOrder(PlayersData[Player])
	task.defer(syncInventory, Player)

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
		HotbarOrder = self.HotbarOrder
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

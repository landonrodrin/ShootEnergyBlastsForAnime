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
	local PlayersData = ctx.PlayersData
	local PlayersModule = ctx.PlayersModule
	local HeldModels = ctx.HeldModels
	local HeldTroves = ctx.HeldTroves
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
local function findAnimeTemplate(Name, Mutation)
	local Animes = ServerStorage:FindFirstChild("Animes")
	if not Animes then return end

	local AnimeConfiguration = AnimeConfigurations[Name]
	local Area = AnimeConfiguration and AnimeConfiguration.Area
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

local function getJointedParts(Model)
	local JointedParts = {}

	for _, Descendant in ipairs(Model:GetDescendants()) do
		if not Descendant:IsA("JointInstance") then continue end

		if Descendant.Part0 then
			JointedParts[Descendant.Part0] = true
		end

		if Descendant.Part1 then
			JointedParts[Descendant.Part1] = true
		end
	end

	return JointedParts
end

local function weldLooseVisualParts(Model, PrimaryPart)
	local JointedParts = getJointedParts(Model)

	for _, Descendant in ipairs(Model:GetDescendants()) do
		if not Descendant:IsA("BasePart") or Descendant == PrimaryPart then continue end
		if Descendant:FindFirstAncestorOfClass("Accessory") then continue end
		if JointedParts[Descendant] then continue end

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

local function createHeldAnimeGui(Model, Name, AnimeConfiguration, Mutation, Level, RebirthMultiplier)
	local PrimaryPart = Model.PrimaryPart
	if not PrimaryPart then return end

	local AnimeModule = ServerStorage.Modules:WaitForChild("Anime")
	local Resources = AnimeModule:WaitForChild("Resources")
	local AnimeGui = Resources:WaitForChild("AnimeGui"):Clone()

	local TimeLabel = AnimeGui:FindFirstChild("Time")
	if TimeLabel then
		TimeLabel:Destroy()
	end

	local CarriedLabel = AnimeGui:FindFirstChild("Carried")
	if CarriedLabel then
		CarriedLabel:Destroy()
	end

	AnimeGui.Mutation.LayoutOrder = 0
	AnimeGui.Area.LayoutOrder = 1
	AnimeGui.Anime.LayoutOrder = 2
	AnimeGui.Money.LayoutOrder = 3

	for _, LabelName in ipairs({"Mutation", "Anime", "Area", "Money"}) do
		local Label = AnimeGui:FindFirstChild(LabelName)
		if Label and Label:IsA("TextLabel") then
			Label.Size = UDim2.new(0.9, 0, Label.Size.Y.Scale, Label.Size.Y.Offset)
		end
	end

	local Area = AnimeConfiguration.Area
	local AreaConfiguration = Area and AreasConfigurations[Area]
	local MutationConfiguration = MutationsConfigurations[Mutation] or {}
	local Multiplier = MutationConfiguration.Multiplier or 1
	local LevelConfiguration = AnimeConfiguration.Levels and AnimeConfiguration.Levels[Level] or {}
	RebirthMultiplier = RebirthMultiplier or 1

	AnimeGui.Anime.Text = string.format("%s (Lvl %s)", Name, Level)
	AnimeGui.Area.Text = Area or ""
	AnimeGui.Area.TextColor3 = AreaConfiguration and AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)
	AnimeGui.Money.Text = string.format("$%s/s", Format.Number((LevelConfiguration.Money or 0) * Multiplier * RebirthMultiplier))
	AnimeGui.Money.Visible = true

	if Mutation and Mutation ~= "Default" then
		AnimeGui.Mutation.Text = Mutation
		AnimeGui.Mutation.TextColor3 = MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		AnimeGui.Mutation.Visible = true
	else
		AnimeGui.Mutation.Visible = false
	end

	local ExistingAttachment = PrimaryPart:FindFirstChild("AnimeAttachment")
	if ExistingAttachment then
		ExistingAttachment:Destroy()
	end

	local AnimeAttachment = Instance.new("Attachment")
	AnimeAttachment.Name = "AnimeAttachment"
	AnimeAttachment.CFrame = CFrame.new(Vector3.new(0, (AnimeConfiguration.YOffset or 0) + AnimeGui.Size.Y.Scale / 2 + 1, 0))
	AnimeAttachment.Parent = PrimaryPart

	AnimeGui.Parent = AnimeAttachment
	AnimeGui.MaxDistance = HELD_ANIME_GUI_MAX_DISTANCE
	AnimeGui.Enabled = true
end

local function getHeldPreviewAnimator(Model)
	local AnimatorOwner = Model:FindFirstChildOfClass("Humanoid")

	if not AnimatorOwner then
		AnimatorOwner = Model:FindFirstChildOfClass("AnimationController")

		if not AnimatorOwner then
			AnimatorOwner = Instance.new("AnimationController")
			AnimatorOwner.Name = "HeldPreviewAnimationController"
			AnimatorOwner.Parent = Model
		end
	end

	local Animator = AnimatorOwner:FindFirstChildOfClass("Animator")
	if not Animator then
		Animator = Instance.new("Animator")
		Animator.Parent = AnimatorOwner
	end

	return Animator
end

local function playHeldIdleAnimation(Model, AnimeConfiguration, HeldTrove)
	local AnimationsIds = AnimeConfiguration and AnimeConfiguration.AnimationsIds
	local IdleAnimationId = AnimationsIds and AnimationsIds.Idle
	if not IdleAnimationId or IdleAnimationId == "" then return end

	local Animator = getHeldPreviewAnimator(Model)
	local Animation = Instance.new("Animation")
	Animation.AnimationId = IdleAnimationId

	local Success, AnimationTrack = pcall(function()
		return Animator:LoadAnimation(Animation)
	end)

	Animation:Destroy()

	if not Success then
		warn(string.format("Failed to load held preview idle animation %s for %s: %s", tostring(IdleAnimationId), Model.Name, tostring(AnimationTrack)))
		return
	end

	AnimationTrack.Looped = true
	AnimationTrack.Priority = Enum.AnimationPriority.Idle
	AnimationTrack:Play()

	HeldTrove:Add(function()
		AnimationTrack:Stop(0.1)
		AnimationTrack:Destroy()
	end)
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
	if HeldTroves[Player] then
		HeldTroves[Player]:Destroy()
		HeldTroves[Player] = nil
	else
		removeHeldAnimeWeld(Player)

		local Existing = HeldModels[Player]
		if Existing then
			Existing:Destroy()
		end
	end

	HeldModels[Player] = nil

	if HeldInventoryCarry[Player] then
		HeldInventoryCarry[Player] = nil

		PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.OwnedHold, false)
	end
end

local function isInventoryAnimeTool(Tool)
	return Tool and Tool:IsA("Tool") and (Tool:GetAttribute("InventoryId") or AnimeConfigurations[Tool.Name])
end

local function clearHeldInventoryPreview(Player)
	local Character = Player.Character
	local EquippedTool = Character and Character:FindFirstChildOfClass("Tool")

	if isInventoryAnimeTool(EquippedTool) then
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid:UnequipTools()
		end
	end

	removeHeldModel(Player)
	task.defer(syncInventory, Player)
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

	local AnimeConfiguration = AnimeConfigurations[Name]
	if not AnimeConfiguration then return end
	Level = Level or 1

	local Model = Template:Clone()
	Model.Name = string.format("Held%s", Name)
	cleanHeldPreviewModel(Model)

	local PrimaryPart = getModelPrimaryPart(Model)
	if not PrimaryPart then
		Model:Destroy()
		return
	end

	local HeldTrove = ctx.Trove.new()

	weldLooseVisualParts(Model, PrimaryPart)
	applyHeldMutationVisual(Model, Mutation)
	local PlayerData = PlayersData[Player]
	local RebirthMultiplier = getRebirthMultiplier(PlayerData and PlayerData.Rebirths or 0)
	createHeldAnimeGui(Model, Name, AnimeConfiguration, Mutation, Level, RebirthMultiplier)

	Model:PivotTo(getHeldAnimeCFrame(Root))

	local Weld = Instance.new("WeldConstraint")
	Weld.Name = HELD_ANIME_WELD_NAME
	Weld.Part0 = Root
	Weld.Part1 = PrimaryPart
	Weld.Parent = Root
	HeldTrove:Add(Weld)

	Model.Parent = getHeldPreviewsFolder()
	HeldTrove:Add(Model)
	forceVisualOnly(Model)
	playHeldIdleAnimation(Model, AnimeConfiguration, HeldTrove)

	local VisualCleanupThread = task.defer(function()
		if Model.Parent then
			forceVisualOnly(Model)
		end
	end)
	HeldTrove:Add(VisualCleanupThread)

	HeldModels[Player] = Model
	HeldTroves[Player] = HeldTrove
	HeldInventoryCarry[Player] = true

	PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.OwnedHold, true)
end
	ctx.createHeldModel = createHeldModel
	ctx.removeHeldModel = removeHeldModel
	ctx.removeHeldAnimeWeld = removeHeldAnimeWeld
	ctx.clearHeldInventoryPreview = clearHeldInventoryPreview
	PlayersModule.ClearHeldInventoryPreview = clearHeldInventoryPreview
end

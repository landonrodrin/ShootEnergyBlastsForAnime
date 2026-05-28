local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))

local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("RebirthsConfigurations"))

local HeldPreviewController = {}

local LOCAL_PLAYER = Players.LocalPlayer
local HELD_ANIME_GUI_MAX_DISTANCE = 50
local HELD_ANIME_WELD_NAME = "ClientHeldAnimeWeld"
local HELD_ANIME_SIDE_OFFSET = 1
local HELD_ANIME_FORWARD_OFFSET = -1.55
local HELD_ANIME_VERTICAL_OFFSET = 3.1
local PREVIEW_CACHE_LIMIT = 10
local AURA_ENABLE_DELAY = 0.08

local ScriptTrove = Trove.new()
local PlayerTroves = {}
local CharacterTroves = {}
local ActivePreviews = {}
local ActiveHoldAnimations = {}
local HoldAnimationCaches = {}
local PreviewCaches = {}
local RefreshQueued = {}
local PreviewUseCounter = 0
local PrewarmQueued = false
local PrewarmGeneration = 0
local Started = false
local InventoryController
local PlayerController
local StatsController

local function getPreviewFolder()
	local FolderName = string.format("ClientHeldPreviews_%s", LOCAL_PLAYER.UserId)
	local Folder = workspace:FindFirstChild(FolderName)
	if Folder then return Folder end

	Folder = Instance.new("Folder")
	Folder.Name = FolderName
	Folder.Parent = workspace

	ScriptTrove:Add(Folder)

	return Folder
end

local function getTemplatesFolder()
	local PreviewTemplates = ReplicatedStorage:FindFirstChild("PreviewTemplates")
	return PreviewTemplates and PreviewTemplates:FindFirstChild("Animes")
end

local function getPreviewAnimeGuiTemplate()
	local PreviewTemplates = ReplicatedStorage:FindFirstChild("PreviewTemplates")
	local Resources = PreviewTemplates and PreviewTemplates:FindFirstChild("Resources")
	local AnimeGui = Resources and Resources:FindFirstChild("AnimeGui")

	if AnimeGui and AnimeGui:IsA("BillboardGui") then
		return AnimeGui
	end
end

local function getEquippedAnimeTool(Player)
	local Character = Player.Character
	local Tool = Character and Character:FindFirstChildOfClass("Tool")
	if not Tool then return nil end
	if not Tool:GetAttribute("InventoryId") then return nil end
	if not AnimeConfigurations[Tool.Name] then return nil end

	return Tool
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

local function setPreviewEffectsEnabled(Model, Enabled)
	for _, Descendant in ipairs(Model:GetDescendants()) do
		if Descendant:IsA("ParticleEmitter")
			or Descendant:IsA("Beam")
			or Descendant:IsA("Trail")
			or Descendant:IsA("PointLight")
			or Descendant:IsA("SpotLight")
			or Descendant:IsA("SurfaceLight")
			or Descendant:IsA("Highlight")
		then
			Descendant.Enabled = Enabled
		end
	end
end

local function getHeldAnimeCFrame(Root)
	return Root.CFrame * CFrame.new(HELD_ANIME_SIDE_OFFSET, HELD_ANIME_VERTICAL_OFFSET, HELD_ANIME_FORWARD_OFFSET)
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
		"Right Leg",
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
				NumberSequenceKeypoint.new(1, 1),
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

local function getRebirthMultiplier(Rebirths)
	local RebirthConfiguration = RebirthsConfigurations[Rebirths or 0]
	return RebirthConfiguration and RebirthConfiguration.Multiplier or 1
end

local function createHeldAnimeGui(Model, Name, AnimeConfiguration, Mutation, Level, Rebirths)
	local PrimaryPart = Model.PrimaryPart
	if not PrimaryPart then return end
	local AnimeGuiTemplate = getPreviewAnimeGuiTemplate()
	if not AnimeGuiTemplate then return end

	local Area = AnimeConfiguration.Area
	local AreaConfiguration = Area and AreasConfigurations[Area]
	local MutationConfiguration = MutationsConfigurations[Mutation] or {}
	local Multiplier = MutationConfiguration.Multiplier or 1
	local LevelConfiguration = AnimeConfiguration.Levels and AnimeConfiguration.Levels[Level] or {}
	local RebirthMultiplier = getRebirthMultiplier(Rebirths)

	local AnimeAttachment = Instance.new("Attachment")
	AnimeAttachment.Name = "AnimeAttachment"
	AnimeAttachment.Parent = PrimaryPart

	local AnimeGui = AnimeGuiTemplate:Clone()
	AnimeGui.AlwaysOnTop = false
	AnimeGui.MaxDistance = HELD_ANIME_GUI_MAX_DISTANCE

	if AnimeGui:FindFirstChild("Time") then
		AnimeGui.Time.LayoutOrder = 0
	end
	if AnimeGui:FindFirstChild("Mutation") then
		AnimeGui.Mutation.LayoutOrder = 1
	end
	if AnimeGui:FindFirstChild("Area") then
		AnimeGui.Area.LayoutOrder = 2
	end
	if AnimeGui:FindFirstChild("Anime") then
		AnimeGui.Anime.LayoutOrder = 3
	end
	if AnimeGui:FindFirstChild("Money") then
		AnimeGui.Money.LayoutOrder = 4
	end

	for _, LabelName in ipairs({"Mutation", "Anime", "Area", "Money", "Time"}) do
		local Label = AnimeGui:FindFirstChild(LabelName)
		if Label and Label:IsA("TextLabel") then
			Label.Size = UDim2.new(0.9, 0, Label.Size.Y.Scale, Label.Size.Y.Offset)
		end
	end

	if AnimeGui:FindFirstChild("Anime") then
		AnimeGui.Anime.Text = string.format("%s (Lvl %s)", Name, Level)
	end

	if AnimeGui:FindFirstChild("Area") then
		AnimeGui.Area.Text = Area or ""
		AnimeGui.Area.TextColor3 = AreaConfiguration and AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)
	end

	if AnimeGui:FindFirstChild("Money") then
		AnimeGui.Money.Text = string.format("$%s/s", Format.Number((LevelConfiguration.Money or 0) * Multiplier * RebirthMultiplier))
		AnimeGui.Money.Visible = true
	end

	if AnimeGui:FindFirstChild("Mutation") then
		AnimeGui.Mutation.Visible = false

		if Mutation and Mutation ~= "Default" then
			AnimeGui.Mutation.Text = Mutation
			AnimeGui.Mutation.TextColor3 = MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
			AnimeGui.Mutation.Visible = true
		end
	end

	if AnimeGui:FindFirstChild("Time") then
		AnimeGui.Time.Visible = false
	end

	if AnimeGui:FindFirstChild("Carried") then
		AnimeGui.Carried.Visible = false
	end

	AnimeGui.Enabled = true
	AnimeGui.Parent = AnimeAttachment
	AnimeAttachment.CFrame = CFrame.new(Vector3.new(0, (AnimeConfiguration.YOffset or 0) + AnimeGui.Size.Y.Scale / 2 + 1, 0))
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

local function ensureHeldIdleAnimation(Record)
	if Record.IdleTrack then return end

	local Model = Record.Model
	local AnimeConfiguration = Record.AnimeConfiguration
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
	if not Success then return end

	AnimationTrack.Looped = true
	AnimationTrack.Priority = Enum.AnimationPriority.Idle
	Record.IdleTrack = AnimationTrack

	Record.Trove:Add(function()
		AnimationTrack:Stop(0.1)
		AnimationTrack:Destroy()
	end)
end

local function playHeldIdleAnimation(Record)
	ensureHeldIdleAnimation(Record)

	local AnimationTrack = Record.IdleTrack
	if AnimationTrack and not AnimationTrack.IsPlaying then
		AnimationTrack:Play()
	end
end

local function stopHeldIdleAnimation(Record)
	local AnimationTrack = Record.IdleTrack
	if AnimationTrack and AnimationTrack.IsPlaying then
		AnimationTrack:Stop(0.1)
	end
end

local function findPreviewTemplate(Name, Mutation)
	local Templates = getTemplatesFolder()
	if not Templates then return nil end

	local AnimeConfiguration = AnimeConfigurations[Name]
	local Area = AnimeConfiguration and AnimeConfiguration.Area
	if not Area then return nil end

	local AreaFolder = Templates:FindFirstChild(Area)
	local Template = AreaFolder and AreaFolder:FindFirstChild(Name)
	if Template then return Template end

	local MutationFolder = Templates:FindFirstChild(Mutation or "Default")
	local MutationAreaFolder = MutationFolder and MutationFolder:FindFirstChild(Area)
	Template = MutationAreaFolder and MutationAreaFolder:FindFirstChild(Name)
	if Template then return Template end

	local DefaultFolder = Templates:FindFirstChild("Default")
	local DefaultAreaFolder = DefaultFolder and DefaultFolder:FindFirstChild(Area)
	return DefaultAreaFolder and DefaultAreaFolder:FindFirstChild(Name)
end

local function getHoldAnimationId(HoldState)
	if HoldState == "Carry" then
		return GameConfigurations.AnimationsIds.Carry
	elseif HoldState == "Inventory" then
		return GameConfigurations.AnimationsIds.OwnedHold
	end
end

local function clearHoldAnimation(Player)
	local Active = ActiveHoldAnimations[Player]
	if not Active then return end

	ActiveHoldAnimations[Player] = nil

	local Track = Active.Track
	if not Track then return end

	pcall(function()
		Track:Stop(0.1)
	end)
end

local function destroyHoldAnimationCache(Player)
	clearHoldAnimation(Player)

	local Cache = HoldAnimationCaches[Player]
	if not Cache then return end

	for _, Record in pairs(Cache.Tracks) do
		local Track = Record.Track
		if Track then
			pcall(function()
				Track:Stop(0)
				Track:Destroy()
			end)
		end
	end

	HoldAnimationCaches[Player] = nil
end

local function getCharacterAnimator(Character)
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	local Animator = Humanoid:FindFirstChildOfClass("Animator")
	if not Animator then
		Animator = Instance.new("Animator")
		Animator.Parent = Humanoid
	end

	return Animator
end

local function getOrCreateHoldAnimationRecord(Player, Character, HoldState, Animator, AnimationId)
	local Cache = HoldAnimationCaches[Player]
	if Cache and Cache.Character ~= Character then
		destroyHoldAnimationCache(Player)
		Cache = nil
	end

	if not Cache then
		Cache = {
			Character = Character,
			Tracks = {},
		}
		HoldAnimationCaches[Player] = Cache
	end

	local Record = Cache.Tracks[HoldState]
	if Record then return Record end

	local Animation = Instance.new("Animation")
	Animation.AnimationId = AnimationId

	local Success, TrackOrError = pcall(function()
		return Animator:LoadAnimation(Animation)
	end)

	Animation:Destroy()
	if not Success then
		warn(string.format("Failed to load held animation %s for %s: %s", tostring(AnimationId), Player.Name, tostring(TrackOrError)))
		return nil
	end

	local Track = TrackOrError
	Track.Looped = true
	Track.Priority = Enum.AnimationPriority.Action4

	Record = {
		Character = Character,
		HoldState = HoldState,
		Track = Track,
	}
	Cache.Tracks[HoldState] = Record

	return Record
end

local function playHoldAnimation(Player, HoldState)
	local AnimationId = getHoldAnimationId(HoldState)
	if not AnimationId or AnimationId == "" then
		clearHoldAnimation(Player)
		return
	end

	local Character = Player.Character
	local Animator = getCharacterAnimator(Character)
	if not Animator then
		clearHoldAnimation(Player)
		return
	end

	local Active = ActiveHoldAnimations[Player]
	if Active and Active.Character == Character and Active.HoldState == HoldState then
		if not Active.Track.IsPlaying then
			Active.Track:Play(0.1, 1, 1)
		end
		return
	end

	clearHoldAnimation(Player)

	local Record = getOrCreateHoldAnimationRecord(Player, Character, HoldState, Animator, AnimationId)
	if not Record then return end

	Record.Track:Play(0.1, 1, 1)
	ActiveHoldAnimations[Player] = Record
end

local function getVisualKeyFromValues(Name, Mutation, Level, Rebirths)
	return string.format(
		"%s:%s:%s:%s",
		Name,
		Mutation or "Default",
		Level or 1,
		Rebirths or 0
	)
end

local function getVisualKey(Tool)
	return getVisualKeyFromValues(
		Tool.Name,
		Tool:GetAttribute("Mutation") or "Default",
		Tool:GetAttribute("Level") or 1,
		Tool:GetAttribute("Rebirths") or 0
	)
end

local function getPlayerCache(Player)
	local Cache = PreviewCaches[Player]
	if Cache then return Cache end

	Cache = {}
	PreviewCaches[Player] = Cache

	return Cache
end

local function hidePreviewRecord(Record)
	Record.AuraToken = (Record.AuraToken or 0) + 1

	if Record.Weld then
		Record.Weld:Destroy()
		Record.Weld = nil
	end

	stopHeldIdleAnimation(Record)
	setPreviewEffectsEnabled(Record.Model, false)
	Record.Model.Parent = nil
end

local function destroyPreviewRecord(Record)
	hidePreviewRecord(Record)
	Record.Trove:Destroy()
end

local function clearPreview(Player)
	local Record = ActivePreviews[Player]
	if not Record then return end

	hidePreviewRecord(Record)
	ActivePreviews[Player] = nil
end

local function destroyPreviewCache(Player)
	clearPreview(Player)

	local Cache = PreviewCaches[Player]
	if not Cache then return end

	for _, Record in pairs(Cache) do
		destroyPreviewRecord(Record)
	end

	PreviewCaches[Player] = nil
end

local function prunePreviewCache(Player, ActiveKey)
	local Cache = PreviewCaches[Player]
	if not Cache then return end

	local Count = 0
	local OldestKey
	local OldestUse

	for Key, Record in pairs(Cache) do
		Count += 1

		if Key ~= ActiveKey and (not OldestUse or Record.LastUsed < OldestUse) then
			OldestKey = Key
			OldestUse = Record.LastUsed
		end
	end

	if Count <= PREVIEW_CACHE_LIMIT or not OldestKey then return end

	local Record = Cache[OldestKey]
	Cache[OldestKey] = nil
	destroyPreviewRecord(Record)
end

local function createPreviewRecordFromValues(Player, Name, Mutation, Level, Rebirths, Key)
	Mutation = Mutation or "Default"
	Level = Level or 1
	Rebirths = Rebirths or 0

	local AnimeConfiguration = AnimeConfigurations[Name]
	local Template = AnimeConfiguration and findPreviewTemplate(Name, Mutation)
	if not Template then return end

	local Model = Template:Clone()
	Model.Name = string.format("ClientHeld_%s_%s", Player.UserId, Key)
	forceVisualOnly(Model)

	local PrimaryPart = getModelPrimaryPart(Model)
	if not PrimaryPart then
		Model:Destroy()
		return
	end

	local PreviewTrove = Trove.new()
	PreviewTrove:Add(Model)

	weldLooseVisualParts(Model, PrimaryPart)
	applyHeldMutationVisual(Model, Mutation)
	createHeldAnimeGui(Model, Name, AnimeConfiguration, Mutation, Level, Rebirths)
	forceVisualOnly(Model)
	setPreviewEffectsEnabled(Model, false)

	local VisualCleanupThread = task.defer(function()
		if Model.Parent then
			forceVisualOnly(Model)
		end
	end)
	PreviewTrove:Add(VisualCleanupThread)

	return {
		Key = Key,
		Model = Model,
		PrimaryPart = PrimaryPart,
		AnimeConfiguration = AnimeConfiguration,
		LastUsed = 0,
		Trove = PreviewTrove,
	}
end

local function createPreviewRecord(Player, Tool, Key)
	return createPreviewRecordFromValues(
		Player,
		Tool.Name,
		Tool:GetAttribute("Mutation") or "Default",
		Tool:GetAttribute("Level") or 1,
		Tool:GetAttribute("Rebirths") or 0,
		Key
	)
end

local function getOrCreatePreviewRecord(Player, Tool, Key)
	local Cache = getPlayerCache(Player)
	local Record = Cache[Key]
	if Record then return Record end

	Record = createPreviewRecord(Player, Tool, Key)
	if not Record then return end

	Cache[Key] = Record
	return Record
end

local function getOrCreatePreviewRecordFromValues(Player, Name, Mutation, Level, Rebirths)
	local Key = getVisualKeyFromValues(Name, Mutation, Level, Rebirths)
	local Cache = getPlayerCache(Player)
	local Record = Cache[Key]
	if Record then return Record end

	Record = createPreviewRecordFromValues(Player, Name, Mutation, Level, Rebirths, Key)
	if not Record then return end

	Cache[Key] = Record
	return Record
end

local function prewarmHotbarPreviews(Generation)
	if not InventoryController or not InventoryController.GetSnapshot then return end

	local Snapshot = InventoryController.GetSnapshot()
	local ItemsById = {}
	for _, Item in ipairs(Snapshot.Items or {}) do
		if typeof(Item.Id) == "string" and Item.Id ~= "" then
			ItemsById[Item.Id] = Item
		end
	end

	local Rebirths = 0
	if StatsController and StatsController.Get then
		Rebirths = tonumber(StatsController.Get("Rebirths")) or 0
	end

	local MaxHotbarSlots = math.min(tonumber(Snapshot.MaxHotbarSlots) or 0, PREVIEW_CACHE_LIMIT)
	for Slot = 1, MaxHotbarSlots do
		if Generation ~= PrewarmGeneration then return end

		local Id = Snapshot.HotbarOrder and Snapshot.HotbarOrder[Slot]
		local Item = Id and ItemsById[Id]
		if Item and AnimeConfigurations[Item.Name] then
			local Record = getOrCreatePreviewRecordFromValues(
				LOCAL_PLAYER,
				Item.Name,
				Item.Mutation or "Default",
				tonumber(Item.Level) or 1,
				Rebirths
			)

			if Record then
				ensureHeldIdleAnimation(Record)

				PreviewUseCounter += 1
				Record.LastUsed = PreviewUseCounter
				prunePreviewCache(LOCAL_PLAYER, ActivePreviews[LOCAL_PLAYER] and ActivePreviews[LOCAL_PLAYER].Key)
			end
		end

		RunService.Heartbeat:Wait()
	end
end

local function scheduleHotbarPrewarm()
	if PrewarmQueued then return end

	PrewarmQueued = true
	PrewarmGeneration += 1
	local Generation = PrewarmGeneration

	task.spawn(function()
		RunService.Heartbeat:Wait()
		PrewarmQueued = false

		if Generation ~= PrewarmGeneration then return end
		prewarmHotbarPreviews(Generation)
	end)
end

local function showPreviewRecord(Player, Record)
	local Character = Player.Character
	local Root = Character and (Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart"))
	if not Root then return false end

	local ActiveRecord = ActivePreviews[Player]
	if ActiveRecord and ActiveRecord ~= Record then
		hidePreviewRecord(ActiveRecord)
	end

	if Record.Weld then
		Record.Weld:Destroy()
		Record.Weld = nil
	end

	Record.Model:PivotTo(getHeldAnimeCFrame(Root))
	Record.Model.Parent = getPreviewFolder()
	forceVisualOnly(Record.Model)
	setPreviewEffectsEnabled(Record.Model, false)

	local Weld = Instance.new("WeldConstraint")
	Weld.Name = HELD_ANIME_WELD_NAME
	Weld.Part0 = Root
	Weld.Part1 = Record.PrimaryPart
	Weld.Parent = Root
	Record.Weld = Weld

	playHeldIdleAnimation(Record)

	PreviewUseCounter += 1
	Record.LastUsed = PreviewUseCounter
	ActivePreviews[Player] = Record

	Record.AuraToken = (Record.AuraToken or 0) + 1
	local AuraToken = Record.AuraToken
	task.delay(AURA_ENABLE_DELAY, function()
		if ActivePreviews[Player] ~= Record then return end
		if Record.AuraToken ~= AuraToken then return end
		if not Record.Model.Parent then return end

		setPreviewEffectsEnabled(Record.Model, true)
	end)

	prunePreviewCache(Player, Record.Key)

	return true
end

local function refreshPlayer(Player)
	RefreshQueued[Player] = nil

	local HoldState = Player:GetAttribute("HoldState")
	if HoldState == "Carry" then
		playHoldAnimation(Player, HoldState)
		clearPreview(Player)
		return
	elseif HoldState ~= "Inventory" then
		clearHoldAnimation(Player)
		clearPreview(Player)
		return
	end

	local Tool = getEquippedAnimeTool(Player)
	if not Tool then
		clearHoldAnimation(Player)
		clearPreview(Player)
		return
	end

	playHoldAnimation(Player, HoldState)

	local Key = getVisualKey(Tool)
	local Preview = ActivePreviews[Player]
	if Preview and Preview.Key == Key and Preview.Model.Parent and Preview.Weld and Preview.Weld.Parent then return end

	local Record = getOrCreatePreviewRecord(Player, Tool, Key)
	if not Record then
		clearPreview(Player)
		return
	end

	showPreviewRecord(Player, Record)
end

local function scheduleRefresh(Player)
	if RefreshQueued[Player] then return end
	RefreshQueued[Player] = true

	task.spawn(function()
		RunService.Heartbeat:Wait()

		if Player.Parent or Player == LOCAL_PLAYER then
			refreshPlayer(Player)
		else
			RefreshQueued[Player] = nil
		end
	end)
end

local function watchTool(Tool, OwnerTrove, Player)
	if not Tool:IsA("Tool") then return end

	OwnerTrove:Connect(Tool:GetAttributeChangedSignal("InventoryId"), function()
		scheduleRefresh(Player)
	end)
	OwnerTrove:Connect(Tool:GetAttributeChangedSignal("Mutation"), function()
		scheduleRefresh(Player)
	end)
	OwnerTrove:Connect(Tool:GetAttributeChangedSignal("Level"), function()
		scheduleRefresh(Player)
	end)
	OwnerTrove:Connect(Tool:GetAttributeChangedSignal("Rebirths"), function()
		scheduleRefresh(Player)
	end)
	OwnerTrove:Connect(Tool.Destroying, function()
		scheduleRefresh(Player)
	end)
end

local function connectCharacter(Player, Character, OwnerTrove)
	if CharacterTroves[Player] then
		CharacterTroves[Player]:Destroy()
		CharacterTroves[Player] = nil
	end

	if not Character then
		scheduleRefresh(Player)
		return
	end

	local CharacterTrove = OwnerTrove:Extend()
	CharacterTroves[Player] = CharacterTrove
	CharacterTrove:Add(function()
		CharacterTroves[Player] = nil
	end)

	for _, Child in ipairs(Character:GetChildren()) do
		if Child:IsA("Tool") then
			watchTool(Child, CharacterTrove, Player)
		end
	end

	CharacterTrove:Connect(Character.ChildAdded, function(Child)
		if Child:IsA("Tool") then
			watchTool(Child, CharacterTrove, Player)
		end
		scheduleRefresh(Player)
	end)

	CharacterTrove:Connect(Character.ChildRemoved, function()
		scheduleRefresh(Player)
	end)

	CharacterTrove:Connect(Character.Destroying, function()
		clearPreview(Player)
		destroyHoldAnimationCache(Player)
	end)

	scheduleRefresh(Player)
end

local function connectPlayer(Player)
	if PlayerTroves[Player] then return end

	local PlayerTrove = ScriptTrove:Extend()
	PlayerTroves[Player] = PlayerTrove

	PlayerTrove:Add(function()
		if CharacterTroves[Player] then
			CharacterTroves[Player]:Destroy()
			CharacterTroves[Player] = nil
		end
		destroyPreviewCache(Player)
		destroyHoldAnimationCache(Player)
		PlayerTroves[Player] = nil
		RefreshQueued[Player] = nil
	end)

	PlayerTrove:Connect(Player.CharacterAdded, function(Character)
		connectCharacter(Player, Character, PlayerTrove)
	end)

	PlayerTrove:Connect(Player.CharacterRemoving, function()
		if CharacterTroves[Player] then
			CharacterTroves[Player]:Destroy()
			CharacterTroves[Player] = nil
		end
		clearPreview(Player)
		destroyHoldAnimationCache(Player)
		scheduleRefresh(Player)
	end)

	PlayerTrove:Connect(Player:GetAttributeChangedSignal("HoldState"), function()
		scheduleRefresh(Player)
	end)

	if Player.Character then
		connectCharacter(Player, Player.Character, PlayerTrove)
	end
end

local function refreshAllPlayers()
	for _, Player in ipairs(Players:GetPlayers()) do
		scheduleRefresh(Player)
	end
end

function HeldPreviewController.Init(Controllers)
	InventoryController = Controllers.InventoryController
	PlayerController = Controllers.PlayerController
	StatsController = Controllers.StatsController
end

function HeldPreviewController.Start()
	if Started then return end
	Started = true

	ScriptTrove:Connect(Players.PlayerAdded, connectPlayer)
	ScriptTrove:Connect(Players.PlayerRemoving, function(Player)
		local PlayerTrove = PlayerTroves[Player]
		if PlayerTrove then
			PlayerTrove:Destroy()
		else
			destroyPreviewCache(Player)
			destroyHoldAnimationCache(Player)
		end
	end)

	for _, Player in ipairs(Players:GetPlayers()) do
		connectPlayer(Player)
	end

	if PlayerController and PlayerController.EquippedAnimeChanged then
		ScriptTrove:Connect(PlayerController.EquippedAnimeChanged, function()
			scheduleRefresh(LOCAL_PLAYER)
		end)
	end

	if InventoryController and InventoryController.Changed then
		ScriptTrove:Connect(InventoryController.Changed, function(Name)
			if Name == "Inventory" then
				scheduleHotbarPrewarm()
			end
		end)
	end

	if StatsController and StatsController.Changed then
		ScriptTrove:Connect(StatsController.Changed, function(Name)
			if Name ~= "Rebirths" then return end

			destroyPreviewCache(LOCAL_PLAYER)
			scheduleHotbarPrewarm()
			scheduleRefresh(LOCAL_PLAYER)
		end)
	end

	task.spawn(function()
		local PreviewTemplates = ReplicatedStorage:WaitForChild("PreviewTemplates", 15)
		if not PreviewTemplates then return end

		local Templates = PreviewTemplates:WaitForChild("Animes", 15)
		if Templates then
			refreshAllPlayers()
			scheduleHotbarPrewarm()
		end
	end)

	ScriptTrove:Connect(script.Destroying, function()
		ScriptTrove:Destroy()
	end)
end

return HeldPreviewController

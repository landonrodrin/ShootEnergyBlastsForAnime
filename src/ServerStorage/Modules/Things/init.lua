local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local PlayersModule = require(ServerStorage.Modules:WaitForChild("Players"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local Grounding = require(ServerStorage.Modules:WaitForChild("Grounding"))
local FinishBarrier = require(ServerStorage.Modules:WaitForChild("FinishBarrier"))

local shared = ReplicatedStorage:WaitForChild("Shared")
local PathUtils = require(shared:WaitForChild("PathUtils"))

local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))

local RetrieveThingDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveThingData")
local CreateThingFunction = ServerStorage.Network.BindableFunctions:WaitForChild("CreateThing")
local AnimateThingEvent = ServerStorage.Network.BindableEvents:WaitForChild("AnimateThing")

local DropEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Drop")

local Things = {}

local ThingsData = {}

local FACING_TARGET_PATH = {"Map", "Main Floor"}
local DEFAULT_INITIAL_POPULATION = 0
local DEFAULT_MAX_POPULATION = math.huge
local DEFAULT_SPAWN_SPACING = 18
local DEFAULT_SPAWN_JITTER = 5
local DEFAULT_INITIAL_TIME_SCALE_MIN = 0.3
local DEFAULT_INITIAL_TIME_SCALE_MAX = 1
local DEFAULT_SPAWN_TIME_SCALE_MIN = 0.3
local DEFAULT_SPAWN_TIME_SCALE_MAX = 1
local THING_GUI_MAX_DISTANCE = 50
local THING_CARRY_HOLD_DURATION = 0.5
local PICK_UP_PROMPT_TEXT = "Pick Up"
local CARRIED_THING_WELD_NAME = "CarriedThingWeld"
local CARRIED_FORWARD_OFFSET = 0
local CARRIED_BASE_VERTICAL_OFFSET = 6
local CARRIED_STACK_PADDING = 2.75
local CARRIED_PHYSICS_ATTRIBUTE_PREFIX = "CarriedOriginal"

local function getSpawnZone(Area, AreaConfiguration)
	if AreaConfiguration and AreaConfiguration.SpawnZonePath then
		local SpawnZone = PathUtils.FindByPath(workspace, AreaConfiguration.SpawnZonePath)
		if SpawnZone and SpawnZone:IsA("BasePart") then
			return SpawnZone
		end

		warn(string.format("Missing spawn zone for area %s: %s", Area, table.concat(AreaConfiguration.SpawnZonePath, ".")))
	end

	local AreasFolder = workspace:FindFirstChild("Areas")
	local AreaModel = AreasFolder and AreasFolder:FindFirstChild(Area)
	if AreaModel and AreaModel:IsA("Model") and AreaModel.PrimaryPart then
		return AreaModel.PrimaryPart
	elseif AreaModel and AreaModel:IsA("BasePart") then
		return AreaModel
	end

	warn("Area has no spawn zone:", Area)
end

local function getFacingTarget()
	local FacingTarget = PathUtils.FindByPath(workspace, FACING_TARGET_PATH)
	if FacingTarget and FacingTarget:IsA("BasePart") then
		return FacingTarget
	end
end

local function getAreaThingConfiguration(Thing)
	if not Thing or not Thing.Name then return end

	return ThingsConfigurations[Thing.Name]
end

local function getAreaThings(Area)
	local AreaThings = {}
	local ThingsFolder = workspace:FindFirstChild("Things")
	if not ThingsFolder then return AreaThings end

	for _, Thing in ipairs(ThingsFolder:GetChildren()) do
		local ThingConfiguration = getAreaThingConfiguration(Thing)
		if ThingConfiguration and ThingConfiguration.Area == Area and Thing.PrimaryPart then
			table.insert(AreaThings, Thing)
		end
	end

	return AreaThings
end

local function getAreaThingCount(Area)
	return #getAreaThings(Area)
end

local function canSpawnInArea(Area, AreaConfiguration)
	local MaxPopulation = AreaConfiguration.MaxPopulation or DEFAULT_MAX_POPULATION

	return getAreaThingCount(Area) < MaxPopulation
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

local function hasThingTemplate(Area, Thing, Mutation)
	local Animes = ServerStorage:FindFirstChild("Animes")

	local function hasInMutation(MutationName)
		local MutationFolder = Animes and Animes:FindFirstChild(MutationName)
		local AreaFolder = MutationFolder and MutationFolder:FindFirstChild(Area)

		return AreaFolder and AreaFolder:FindFirstChild(Thing) ~= nil
	end

	if hasInMutation(Mutation) then
		return true
	end

	return Mutation ~= "Default" and hasInMutation("Default")
end

local function areaHasSpawnableThings(Area)
	for Thing, ThingConfiguration in pairs(ThingsConfigurations) do
		if ThingConfiguration.Area ~= Area then continue end

		for Mutation in pairs(MutationsConfigurations) do
			if hasThingTemplate(Area, Thing, Mutation) then
				return true
			end
		end

		if hasThingTemplate(Area, Thing, "Default") then
			return true
		end
	end

	return false
end

function Things.Retrieve(Thing, Name)
	if not ThingsData[Thing] then return end

	if Name then
		return ThingsData[Thing][Name]
	else
		return ThingsData[Thing]
	end
end

local function getRandomTimeScale(Range, DefaultMinimum, DefaultMaximum)
	local Minimum = Range and Range.Minimum or DefaultMinimum
	local Maximum = Range and Range.Maximum or DefaultMaximum

	if Maximum < Minimum then
		Maximum = Minimum
	end

	return Minimum + (math.random() * (Maximum - Minimum))
end

local function getRandomLevel(ThingConfiguration)
	local MaximumConfiguredLevel = 1
	for Level in pairs(ThingConfiguration.Levels or {}) do
		if Level > MaximumConfiguredLevel then
			MaximumConfiguredLevel = Level
		end
	end

	local LevelRange = ThingConfiguration.Level or {}
	local Minimum = math.clamp(LevelRange.Minimum or 1, 1, MaximumConfiguredLevel)
	local Maximum = math.clamp(LevelRange.Maximum or MaximumConfiguredLevel, Minimum, MaximumConfiguredLevel)

	return math.random(Minimum, Maximum)
end

local function spawnRandomThing(Area, AreaConfiguration, SpawnOptions)
	if not canSpawnInArea(Area, AreaConfiguration) then return end

	local Attempts = AreaConfiguration.SpawnAttempts or 30
	SpawnOptions = SpawnOptions or {}

	for _ = 1, Attempts do
		local Thing, ThingConfiguration, Mutation, MutationConfiguration, Level = Things.Random(Area)
		if not Thing then return end
		if not hasThingTemplate(Area, Thing, Mutation) then continue end

		local CreatedThing = Things.Create(Area, AreaConfiguration, Thing, ThingConfiguration, Mutation, MutationConfiguration, Level)
		if CreatedThing then
			local ThingData = ThingsData[CreatedThing]
			if ThingData then
				ThingData.TimeScale = SpawnOptions.TimeScale or getRandomTimeScale(AreaConfiguration.SpawnTimeScale, DEFAULT_SPAWN_TIME_SCALE_MIN, DEFAULT_SPAWN_TIME_SCALE_MAX)
				ThingData:Spawn()
			end

			if CreatedThing.Parent then
				return CreatedThing
			end
		end
	end
end

function Things.Setup()
	local ThingsFolder = workspace:FindFirstChild("Things") or Instance.new("Folder")
	ThingsFolder.Name = "Things"
	ThingsFolder.Parent = workspace
	ThingsFolder:ClearAllChildren()
	
	registerCollisionGroup("Things")
	registerCollisionGroup("Players")
	setGroupsCollidable("Things", "Players", false)
	setGroupsCollidable("Things", "Things", false)

	RetrieveThingDataFunction.OnInvoke = Things.Retrieve
	CreateThingFunction.OnInvoke = Things.Create
	
	AnimateThingEvent.Event:Connect(Things.Animate)

	Players.PlayerAdded:Connect(function(Player)
		Player.CharacterRemoving:Connect(function()
			Things.Drop(Player)
		end)
	end)

	DropEvent.OnServerEvent:Connect(function(Player)
		Things.Drop(Player)
	end)
	
	Players.PlayerRemoving:Connect(function(Player)
		Things.Drop(Player)
	end)

	FinishBarrier.OnReturn(function(Player)
		Things.Zone(Player)
	end, 100)
	
	for Area, AreaConfiguration in pairs(AreasConfigurations) do
		if AreaConfiguration.Enabled == false then continue end
		if not areaHasSpawnableThings(Area) then
			warn(string.format("Skipping anime area %s: no configured anime templates found.", Area))
			continue
		end

		local InitialPopulation = AreaConfiguration.InitialPopulation or DEFAULT_INITIAL_POPULATION
		for Index = 1, InitialPopulation do
			local TimeScale = getRandomTimeScale(AreaConfiguration.InitialTimeScale, DEFAULT_INITIAL_TIME_SCALE_MIN, DEFAULT_INITIAL_TIME_SCALE_MAX)
			if InitialPopulation > 1 then
				local EvenScale = DEFAULT_INITIAL_TIME_SCALE_MIN + ((Index - 1) / (InitialPopulation - 1)) * (DEFAULT_INITIAL_TIME_SCALE_MAX - DEFAULT_INITIAL_TIME_SCALE_MIN)
				TimeScale = math.clamp((TimeScale + EvenScale) / 2, DEFAULT_INITIAL_TIME_SCALE_MIN, DEFAULT_INITIAL_TIME_SCALE_MAX)
			end

			if not spawnRandomThing(Area, AreaConfiguration, {TimeScale = TimeScale}) then
				break
			end
		end

		task.spawn(function()
			local Minimum = AreaConfiguration.Rate and AreaConfiguration.Rate.Minimum and math.clamp(AreaConfiguration.Rate.Minimum, 0.01, math.huge) or 0.01
			local Maximum = AreaConfiguration.Rate and AreaConfiguration.Rate.Maximum and AreaConfiguration.Rate.Maximum or 5

			local Chance = AreaConfiguration.Chance or 1

			while task.wait(math.random(Minimum, Maximum)) do
				if not canSpawnInArea(Area, AreaConfiguration) then continue end
				if math.random() > Chance then continue end

				spawnRandomThing(Area, AreaConfiguration)
			end
		end)
		
		if not AreaConfiguration.Guaranteed or AreaConfiguration.Guaranteed <= 0 then continue end
		
		task.spawn(function()
			local GuaranteedArea = script.Resources:WaitForChild("GuaranteedArea")

			GuaranteedArea = GuaranteedArea:Clone()

			local Colour = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

			Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)
			
			GuaranteedArea.Text = string.format("<font color=\"%s\">%s</font> appears in %s", Colour, Area, Format.Time(AreaConfiguration.Guaranteed))
			
			GuaranteedArea.Name = Area
			GuaranteedArea.Parent = workspace.GuaranteedAreas:WaitForChild("GuaranteedAreasGui")
			GuaranteedArea.Visible = true
			
			local Timer = tonumber(AreaConfiguration.Guaranteed)
			
			while task.wait(1) do
				Timer -= 1
				
				GuaranteedArea.Text = string.format("<font color=\"%s\">%s</font> appears in %s", Colour, Area, Format.Time(Timer))
			
				if Timer > 0 then continue end
				
				Timer = tonumber(AreaConfiguration.Guaranteed)
				if not canSpawnInArea(Area, AreaConfiguration) then continue end
				
				spawnRandomThing(Area, AreaConfiguration)
			end
		end)
	end
end

function Things.Random(Area)
	local AreaThings = {}

	local TotalChance = 0

	for Thing, ThingConfiguration in pairs(ThingsConfigurations) do
		local ThingArea = ThingConfiguration.Area
		
		if not ThingArea or ThingArea ~= Area then continue end

		TotalChance += ThingConfiguration.Chance or 1

		AreaThings[Thing] = ThingConfiguration
	end

	if TotalChance <= 0 then
		return
	end

	local RandomThing = nil
	local RandomConfiguration = nil

	local Roll = math.random() * TotalChance
	local Sum = 0

	for Thing, ThingConfiguration in pairs(AreaThings) do
		Sum += ThingConfiguration.Chance or 1

		if Roll > Sum then continue end

		RandomThing = Thing
		RandomConfiguration = ThingConfiguration

		break
	end

	if not RandomThing then return end

	TotalChance = 0

	for Mutation, MutationConfiguration in pairs(MutationsConfigurations) do
		local Chance = MutationConfiguration.Chance or 1

		TotalChance += Chance
	end

	local RandomMutation
	local RandomMutationConfiguration

	Roll = math.random() * TotalChance
	Sum = 0

	for Mutation, MutationConfiguration in pairs(MutationsConfigurations) do
		Sum += MutationConfiguration.Chance or 1

		if Roll > Sum then continue end

		RandomMutation = Mutation
		RandomMutationConfiguration = MutationConfiguration

		break
	end

	if not RandomMutation then
		RandomMutation = "Default"
	end

	return RandomThing, RandomConfiguration, RandomMutation, RandomMutationConfiguration, getRandomLevel(RandomConfiguration)
end

function Things.Animate(Thing, AnimationId, Bool)
	if not AnimationId or AnimationId == "" then return end
	
	local Data = ThingsData[Thing]

	if not Data then return end

	local AnimatorOwner = Thing:FindFirstChildOfClass("Humanoid")

	if not AnimatorOwner then
		AnimatorOwner = Thing:FindFirstChildOfClass("AnimationController")

		if not AnimatorOwner then
			AnimatorOwner = Instance.new("AnimationController")
			AnimatorOwner.Parent = Thing
		end
	end

	local Animator = AnimatorOwner:FindFirstChildOfClass("Animator")
	if not Animator then
		Animator = Instance.new("Animator")
		Animator.Parent = AnimatorOwner
	end

	Data.AnimationTracks = Data.AnimationTracks or {}

	Data.AnimationTracks[Animator] = Data.AnimationTracks[Animator] or {}

	local Tracks = Data.AnimationTracks[Animator]

	local AnimationTrack = Tracks[AnimationId]

	if not AnimationTrack then
		local Animation = Instance.new("Animation")
		Animation.AnimationId = AnimationId

		AnimationTrack = Animator:LoadAnimation(Animation)

		Tracks[AnimationId] = AnimationTrack
	end

	if Bool then
		AnimationTrack:Play()
	else
		AnimationTrack:Stop()
	end

	return AnimationTrack
end

local function getThingGui(Thing)
	local PrimaryPart = Thing and Thing.PrimaryPart
	local ThingAttachment = PrimaryPart and PrimaryPart:FindFirstChild("ThingAttachment")
	return ThingAttachment and ThingAttachment:FindFirstChild("ThingGui")
end

local function resetThingTimer(Thing, ThingData, ThingConfiguration)
	if not ThingData or not ThingConfiguration then return end

	local BaseTime = ThingConfiguration.Time or 10
	local TimeScale = ThingData.TimeScale or 1
	local Time = math.max(1, math.floor(BaseTime * TimeScale))
	ThingData.Time = Time

	local ThingGui = getThingGui(Thing)
	if ThingGui and ThingGui:FindFirstChild("Time") then
		ThingGui.Time.Text = Format.Time(Time)
		ThingGui.Time.Visible = true
	end
end

local function removeCarryWelds(Player, Thing)
	if Thing then
		for _, Descendant in ipairs(Thing:GetDescendants()) do
			if Descendant:IsA("WeldConstraint") and Descendant.Name == CARRIED_THING_WELD_NAME then
				Descendant:Destroy()
			end
		end
	end

	local Character = Player.Character
	local Root = Character and Character.PrimaryPart
	if Root then
		for _, Child in ipairs(Root:GetChildren()) do
			if Child:IsA("WeldConstraint") and Child.Name == CARRIED_THING_WELD_NAME then
				Child:Destroy()
			end
		end
	end
end

local function setCarriedPhysics(Thing)
	for _, Descendant in ipairs(Thing:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		if Descendant:GetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "Anchored") == nil then
			Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "Anchored", Descendant.Anchored)
			Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanCollide", Descendant.CanCollide)
			Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanTouch", Descendant.CanTouch)
			Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanQuery", Descendant.CanQuery)
			Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "Massless", Descendant.Massless)
		end

		Descendant.Anchored = false
		Descendant.CanCollide = false
		Descendant.CanTouch = false
		Descendant.CanQuery = false
		Descendant.Massless = true
	end
end

local function restoreThingPhysics(Thing)
	for _, Descendant in ipairs(Thing:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		local OriginalAnchored = Descendant:GetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "Anchored")
		local OriginalCanCollide = Descendant:GetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanCollide")
		local OriginalCanTouch = Descendant:GetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanTouch")
		local OriginalCanQuery = Descendant:GetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanQuery")
		local OriginalMassless = Descendant:GetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "Massless")

		if OriginalAnchored ~= nil then Descendant.Anchored = OriginalAnchored end
		if OriginalCanCollide ~= nil then Descendant.CanCollide = OriginalCanCollide end
		if OriginalCanTouch ~= nil then Descendant.CanTouch = OriginalCanTouch end
		if OriginalCanQuery ~= nil then Descendant.CanQuery = OriginalCanQuery end
		if OriginalMassless ~= nil then Descendant.Massless = OriginalMassless end

		Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "Anchored", nil)
		Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanCollide", nil)
		Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanTouch", nil)
		Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "CanQuery", nil)
		Descendant:SetAttribute(CARRIED_PHYSICS_ATTRIBUTE_PREFIX .. "Massless", nil)

		Descendant.CollisionGroup = "Things"
	end
end

local function getCarryCFrame(Character, Thing, StackIndex)
	local Root = Character and Character.PrimaryPart
	if not Root then return end

	local _, Size = Thing:GetBoundingBox()
	local StackOffset = math.max(Size.Y * 0.55 + CARRIED_STACK_PADDING, 1.25) * math.max((StackIndex or 1) - 1, 0)
	local Position = (Root.CFrame * CFrame.new(0, CARRIED_BASE_VERTICAL_OFFSET + StackOffset, CARRIED_FORWARD_OFFSET)).Position

	return CFrame.lookAt(Position, Position + Root.CFrame.LookVector)
end

local function weldThingToPlayer(Player, Thing, StackIndex)
	local Character = Player.Character
	local Root = Character and Character.PrimaryPart
	if not Root or not Thing.PrimaryPart then return end

	removeCarryWelds(Player, Thing)
	setCarriedPhysics(Thing)

	local CarryCFrame = getCarryCFrame(Character, Thing, StackIndex)
	if CarryCFrame then
		Thing:PivotTo(CarryCFrame)
	end

	local WeldConstraint = Instance.new("WeldConstraint")
	WeldConstraint.Name = CARRIED_THING_WELD_NAME
	WeldConstraint.Part0 = Thing.PrimaryPart
	WeldConstraint.Part1 = Root
	WeldConstraint.Parent = Thing.PrimaryPart
end

local function refreshCarriedThingPositions(Player, Carrying)
	for Index, Thing in ipairs(Carrying or {}) do
		if Thing and Thing.Parent and Thing.PrimaryPart then
			weldThingToPlayer(Player, Thing, Index)
		end
	end
end

local function alignDroppedThingToGround(Player, Thing, ThingConfiguration)
	local Character = Player.Character
	local Root = Character and Character.PrimaryPart
	local Origin = (Thing:GetPivot().Position) + Vector3.new(0, 8, 0)
	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParameters.FilterDescendantsInstances = {Thing, Character}

	local Result = workspace:Raycast(Origin, Vector3.new(0, -80, 0), RaycastParameters)
	if Result then
		Grounding.AlignBottomToY(Thing, Result.Position.Y, ThingConfiguration)
	elseif Root then
		Thing:PivotTo(CFrame.lookAt(Root.Position + Root.CFrame.LookVector * 2, Root.Position + Root.CFrame.LookVector * 3))
	end
end

function Things.Drop(Player, ResetTimers)
	if ResetTimers == nil then
		ResetTimers = true
	end

	local Carrying = PlayersModule.Retrieve(Player, "Carrying")

	if not Carrying then return end

	DropEvent:FireClient(Player, false)
	
	for _, Thing in ipairs(Carrying) do
		local ThingConfiguration = ThingsConfigurations[Thing.Name]
		local ThingData = ThingsData[Thing]
		if not ThingConfiguration or not ThingData then continue end
		if not Thing.Parent or not Thing.PrimaryPart then
			ThingsData[Thing] = nil
			continue
		end

		removeCarryWelds(Player, Thing)

		local ThingsFolder = workspace:FindFirstChild("Things")
		if ThingsFolder then
			Thing.Parent = ThingsFolder
		end

		restoreThingPhysics(Thing)
		alignDroppedThingToGround(Player, Thing, ThingConfiguration)

		local ProximityPrompt = Thing.PrimaryPart:FindFirstChild("ProximityPrompt")
		if ProximityPrompt then
			SetProperties.AllClients(ProximityPrompt, {Enabled = true, ActionText = PICK_UP_PROMPT_TEXT})
		end

		local ThingGui = getThingGui(Thing)
		if ThingGui and ThingGui:FindFirstChild("Carried") then
			ThingGui.Carried.Visible = false
		end

		ThingData.Carried = nil
		if ResetTimers then
			resetThingTimer(Thing, ThingData, ThingConfiguration)
		end
	end

	for _, Thing in ipairs(workspace.Things:GetChildren()) do
		task.spawn(function()
			if not Thing.PrimaryPart then return end

			local OtherProximityPrompt = Thing.PrimaryPart:FindFirstChild("ProximityPrompt")
			if not OtherProximityPrompt then return end

			SetProperties.Client(Player, OtherProximityPrompt, {Enabled = true, ActionText = PICK_UP_PROMPT_TEXT})

			for _, OtherPlayer in ipairs(Players:GetPlayers()) do
				local Carrying = PlayersModule.Retrieve(OtherPlayer, "Carrying")
				if not Carrying then continue end

				if table.find(Carrying, Thing) then return end
			end
		end)
	end

	PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.Carry, false)

	PlayersModule.Replace(Player, "Carrying", nil)
	PlayersModule.Replace(Player, "Carried", nil)
end

function Things.Zone(Player)
	local Carrying = PlayersModule.Retrieve(Player, "Carrying")
	if not Carrying then return end

	local ReturningThings = {}
	for _, Thing in ipairs(Carrying) do
		local Name = Thing.Name
		local ThingConfiguration = ThingsConfigurations[Name]
		local Data = ThingsData[Thing]

		if ThingConfiguration and Data then
			table.insert(ReturningThings, {
				Thing = Thing,
				Name = Name,
				ThingConfiguration = ThingConfiguration,
				Mutation = Data.Mutation,
				Level = Data.Level or 1
			})
		end
	end

	Things.Drop(Player, false)

	for _, ThingData in ipairs(ReturningThings) do
		local Data = ThingsData[ThingData.Thing]
		if not Data then continue end

		Data:Destroy()

		PlayersModule.Tool(Player, ThingData.Name, ThingData.ThingConfiguration, ThingData.Mutation, ThingData.Level, true)
	end
end

local function findThingTemplate(Animes, Mutation, Area, Thing)
	local function findInMutation(MutationName)
		local MutationFolder = Animes and Animes:FindFirstChild(MutationName)
		local AreaFolder = MutationFolder and MutationFolder:FindFirstChild(Area)

		return AreaFolder and AreaFolder:FindFirstChild(Thing)
	end

	local ThingTemplate = findInMutation(Mutation)
	if ThingTemplate then
		return ThingTemplate
	end

	if Mutation ~= "Default" then
		return findInMutation("Default")
	end
end

local function getMutationAuraParts(Thing)
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
		local Part = Thing:FindFirstChild(PartName, true)
		if Part and Part:IsA("BasePart") and Part.Transparency < 0.95 then
			table.insert(AuraParts, Part)
		end
	end

	if #AuraParts == 0 then
		for _, Descendant in ipairs(Thing:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end
			if Descendant == Thing.PrimaryPart then continue end
			if Descendant.Transparency >= 0.95 then continue end

			table.insert(AuraParts, Descendant)

			if #AuraParts >= 6 then break end
		end
	end

	if #AuraParts == 0 and Thing.PrimaryPart then
		table.insert(AuraParts, Thing.PrimaryPart)
	end

	return AuraParts
end

local function applyMutationAura(Thing, Mutation, MutationConfiguration)
	if not Mutation or Mutation == "Default" or not MutationConfiguration then return end

	local AuraConfiguration = MutationConfiguration.Aura
	if not AuraConfiguration then return end

	local HighlightConfiguration = AuraConfiguration.Highlight
	if HighlightConfiguration then
		local Highlight = Instance.new("Highlight")
		Highlight.Name = "MutationHighlight"
		Highlight.Adornee = Thing
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = HighlightConfiguration.FillColor or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Highlight.FillTransparency = HighlightConfiguration.FillTransparency or 0.65
		Highlight.OutlineColor = HighlightConfiguration.OutlineColor or Highlight.FillColor
		Highlight.OutlineTransparency = HighlightConfiguration.OutlineTransparency or 0.15
		Highlight.Parent = Thing
	end

	local ParticleConfiguration = AuraConfiguration.Particle
	if ParticleConfiguration then
		for _, AuraPart in ipairs(getMutationAuraParts(Thing)) do
			local AuraAttachment = Instance.new("Attachment")
			AuraAttachment.Name = "MutationAuraAttachment"
			AuraAttachment.Parent = AuraPart

			local Particle = Instance.new("ParticleEmitter")
			Particle.Name = "MutationAura"
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
	if LightConfiguration and Thing.PrimaryPart then
		local Light = Instance.new("PointLight")
		Light.Name = "MutationAuraLight"
		Light.Color = LightConfiguration.Color or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Light.Brightness = LightConfiguration.Brightness or 0.6
		Light.Range = LightConfiguration.Range or 8
		Light.Parent = Thing.PrimaryPart
	end
end

function Things.Create(Area, AreaConfiguration, Thing, ThingConfiguration, Mutation, MutationConfiguration, Level)
	Level = Level or 1

	local Data = setmetatable({}, {__index = Things})

	local Animes = ServerStorage:FindFirstChild("Animes")
	local ThingTemplate = findThingTemplate(Animes, Mutation, Area, Thing)

	if not ThingTemplate then
		warn(string.format("Missing anime asset: %s.%s.%s or Default.%s.%s", tostring(Mutation), tostring(Area), tostring(Thing), tostring(Area), tostring(Thing)))
		return
	end

	if not ThingTemplate.PrimaryPart then
		warn(string.format("%s thing has no primary part.", ThingTemplate.Name))
		return
	end

	Thing = ThingTemplate:Clone()
	applyMutationAura(Thing, Mutation, MutationConfiguration)

	Data.Thing = Thing
	Data.Mutation = Mutation
	Data.Level = Level
	Data.AnimationTracks = {}

	for _, Descendant in ipairs(Thing:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		Descendant.CollisionGroup = "Things"

		if Descendant == Thing.PrimaryPart then
			Descendant.Anchored = true
		else
			Descendant.Anchored = false
		end
	end

	local ThingAttachment = Instance.new("Attachment")
	ThingAttachment.Name = "ThingAttachment"
	ThingAttachment.Parent = Thing.PrimaryPart

	local ThingGui = script.Resources:WaitForChild("ThingGui")

	ThingGui = ThingGui:Clone()

	ThingGui.Time.LayoutOrder = 0
	ThingGui.Mutation.LayoutOrder = 1
	ThingGui.Area.LayoutOrder = 2
	ThingGui.Thing.LayoutOrder = 3
	ThingGui.Money.LayoutOrder = 4

	for _, LabelName in ipairs({"Mutation", "Thing", "Area", "Money", "Time"}) do
		local Label = ThingGui:FindFirstChild(LabelName)
		if Label and Label:IsA("TextLabel") then
			Label.Size = UDim2.new(0.9, 0, Label.Size.Y.Scale, Label.Size.Y.Offset)
		end
	end

	ThingGui.Thing.Text = string.format("%s (Lvl %s)", Thing.Name, Level)
	ThingGui.Area.Text = Area

	local Multiplier = MutationConfiguration.Multiplier or 1

	ThingGui.Money.Text = string.format("$%s/s", Format.Number((ThingConfiguration.Levels[Level].Money or 0) * Multiplier))
	ThingGui.Money.Visible = true
	
	ThingGui.Area.TextColor3 = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

	if Mutation and Mutation ~= "Default" then
		ThingGui.Mutation.Text = Mutation

		ThingGui.Mutation.TextColor3 = MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)

		ThingGui.Mutation.Visible = true
	end

	ThingGui.Parent = ThingAttachment
	ThingGui.MaxDistance = THING_GUI_MAX_DISTANCE
	ThingGui.Enabled = true

	ThingAttachment.CFrame = CFrame.new(Vector3.new(0, ThingConfiguration.YOffset + ThingGui.Size.Y.Scale / 2 + 1, 0))

	ThingsData[Thing] = Data

	return Thing
end

local function getCandidateSpacing(AreaConfiguration, ThingConfiguration)
	return math.max(
		AreaConfiguration.SpawnSpacing or DEFAULT_SPAWN_SPACING,
		(ThingConfiguration.Distance or 0) * 3
	)
end

local function scoreSpawnCandidate(Area, AreaConfiguration, ThingConfiguration, Candidate)
	local Spacing = getCandidateSpacing(AreaConfiguration, ThingConfiguration)
	local RequiredSpacing = Spacing * 0.75
	local NearbyCount = 0
	local NearestDistance = math.huge

	for _, OtherThing in ipairs(getAreaThings(Area)) do
		local OtherConfiguration = getAreaThingConfiguration(OtherThing)
		if not OtherConfiguration then continue end

		local RequiredDistance = math.max(
			RequiredSpacing,
			(ThingConfiguration.Distance or 0) + (OtherConfiguration.Distance or 0)
		)
		local Delta = OtherThing.PrimaryPart.Position - Candidate
		local Distance = Vector2.new(Delta.X, Delta.Z).Magnitude

		if Distance < RequiredDistance then
			return nil
		end

		if Distance < Spacing * 1.5 then
			NearbyCount += 1
		end

		if Distance < NearestDistance then
			NearestDistance = Distance
		end
	end

	return NearbyCount * 1000 - NearestDistance
end

local function getGridSpawnPosition(Area, AreaConfiguration, ThingConfiguration, SpawnZone)
	local AreaCFrame = SpawnZone.CFrame
	local AreaSize = SpawnZone.Size
	local Spacing = getCandidateSpacing(AreaConfiguration, ThingConfiguration)
	local Jitter = math.min(AreaConfiguration.SpawnJitter or DEFAULT_SPAWN_JITTER, Spacing * 0.35)

	local Padding = math.max(ThingConfiguration.Distance or 0, 2)
	local HalfX = (AreaSize.X / 2) - Padding
	local HalfZ = (AreaSize.Z / 2) - Padding
	if HalfX <= 0 or HalfZ <= 0 then return end

	local Columns = math.max(1, math.floor((HalfX * 2) / Spacing))
	local Rows = math.max(1, math.floor((HalfZ * 2) / Spacing))

	local BestPosition
	local BestScore

	for Column = 1, Columns do
		for Row = 1, Rows do
			local LocalX = -HalfX + ((Column - 0.5) / Columns) * (HalfX * 2)
			local LocalZ = -HalfZ + ((Row - 0.5) / Rows) * (HalfZ * 2)

			LocalX += (math.random() - 0.5) * 2 * Jitter
			LocalZ += (math.random() - 0.5) * 2 * Jitter

			LocalX = math.clamp(LocalX, -HalfX, HalfX)
			LocalZ = math.clamp(LocalZ, -HalfZ, HalfZ)

			local Candidate = AreaCFrame:PointToWorldSpace(Vector3.new(LocalX, AreaSize.Y / 2, LocalZ))
			local Score = scoreSpawnCandidate(Area, AreaConfiguration, ThingConfiguration, Candidate)
			if Score and (not BestScore or Score < BestScore) then
				BestPosition = Candidate
				BestScore = Score
			end
		end
	end

	return BestPosition
end

local function getSpawnCFrame(Position, ThingConfiguration, SpawnZone)
	local SpawnPosition = Position
	local FacingTarget = getFacingTarget()

	if not FacingTarget then
		return CFrame.new(SpawnPosition)
	end

	local TargetPosition = Vector3.new(FacingTarget.Position.X, SpawnPosition.Y, FacingTarget.Position.Z)
	if (TargetPosition - SpawnPosition).Magnitude < 0.1 then
		return CFrame.new(SpawnPosition)
	end

	return CFrame.lookAt(SpawnPosition, TargetPosition)
end

function Things:Spawn()
	local Thing = self.Thing
	
	local ThingConfiguration = ThingsConfigurations[Thing.Name]

	local AreaName = ThingConfiguration.Area
	local AreaConfiguration = AreasConfigurations[AreaName]
	local SpawnZone = getSpawnZone(AreaName, AreaConfiguration)
	if not SpawnZone then return end

	local Position = getGridSpawnPosition(AreaName, AreaConfiguration, ThingConfiguration, SpawnZone)

	if not Position then
		self:Destroy()

		return
	end

	Thing.Parent = workspace:WaitForChild("Things")

	local TargetCFrame = getSpawnCFrame(Position, ThingConfiguration, SpawnZone)

	Thing:PivotTo(TargetCFrame)
	Grounding.AlignBottomToSurface(Thing, SpawnZone, ThingConfiguration)

	local _IdleTrack = Things.Animate(Thing, ThingConfiguration.AnimationsIds.Idle, true)
	Grounding.AlignBottomToSurfaceAfterAnimation(Thing, SpawnZone, ThingConfiguration)

	local ProximityPrompt = Instance.new("ProximityPrompt")
	ProximityPrompt.Enabled = true
	ProximityPrompt.ActionText = PICK_UP_PROMPT_TEXT
	ProximityPrompt.HoldDuration = THING_CARRY_HOLD_DURATION
	ProximityPrompt.ObjectText = Thing.Name
	ProximityPrompt.RequiresLineOfSight = false
	ProximityPrompt.Parent = Thing.PrimaryPart

	SetProperties.AllClients(ProximityPrompt, {Enabled = true, ActionText = PICK_UP_PROMPT_TEXT})

	for _, Player in ipairs(Players:GetPlayers()) do
		local Carrying = PlayersModule.Retrieve(Player, "Carrying")
		if not Carrying then continue end

		if #Carrying < PlayersModule.Retrieve(Player, "Carry") then continue end

		SetProperties.Client(Player, ProximityPrompt, {Enabled = false, ActionText = PICK_UP_PROMPT_TEXT})
	end

	ProximityPrompt.Triggered:Connect(function(Player)
		if (self.Time or 0) < 1 then return end
		
		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			if OtherPlayer == Player then continue end

			local Carrying = PlayersModule.Retrieve(OtherPlayer, "Carrying")
			if not Carrying then continue end

			if table.find(Carrying, Thing) then return end
		end

		local Carrying = PlayersModule.Retrieve(Player, "Carrying")

		if Carrying and table.find(Carrying, Thing) then
			Things.Drop(Player)

			return
		elseif Carrying and #Carrying >= PlayersModule.Retrieve(Player, "Carry") then
			Things.Drop(Player)

			return
		elseif not Carrying then
			Carrying = {}
		end

		table.insert(Carrying, Thing)

		PlayersModule.Replace(Player, "Carrying", Carrying)

		self.Carried = Player

		ThingsData[Thing] = self

		PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.Carry, true)

		local ThingGui = getThingGui(Thing)
		if ThingGui and ThingGui:FindFirstChild("Time") then
			ThingGui.Time.Visible = false
		end

		for _, OtherThing in ipairs(workspace.Things:GetChildren()) do
			task.spawn(function()
				if not OtherThing.PrimaryPart then return end

				local OtherProximityPrompt = OtherThing.PrimaryPart:FindFirstChild("ProximityPrompt")
				if not OtherProximityPrompt then return end

				if OtherProximityPrompt == ProximityPrompt then
					SetProperties.AllClients(OtherProximityPrompt, {Enabled = false, ActionText = PICK_UP_PROMPT_TEXT})

					return
				end

				if #Carrying < PlayersModule.Retrieve(Player, "Carry") then return end

				SetProperties.Client(Player, OtherProximityPrompt, {Enabled = false, ActionText = PICK_UP_PROMPT_TEXT})
			end)
		end

		refreshCarriedThingPositions(Player, Carrying)
		
		DropEvent:FireClient(Player, true)
	end)

	local ThingAttachment = Thing.PrimaryPart:WaitForChild("ThingAttachment")
	local ThingGui = ThingAttachment:WaitForChild("ThingGui")

	local BaseTime = ThingConfiguration.Time or 10
	local TimeScale = self.TimeScale or 1
	self.Time = math.max(1, math.floor(BaseTime * TimeScale))

	ThingGui.Time.Text = Format.Time(self.Time)

	task.spawn(function()
		while Thing and Thing.Parent do
			while self.Carried do
				task.wait(0.01)

				if not Thing or not Thing.Parent then return end
			end

			task.wait(1)

			if not Thing or not Thing.Parent then break end

			self.Time = (self.Time or 0) - 1

			if self.Time <= 0 then
				self:Destroy()

				break
			end

			ThingGui.Time.Text = Format.Time(self.Time)
		end
	end)

	ThingGui.Time.Visible = true
end

function Things:Destroy()
	local Thing = self.Thing
	if not Thing then return end

	ThingsData[Thing] = nil
	Thing:Destroy()
	self.Thing = nil
end

return Things

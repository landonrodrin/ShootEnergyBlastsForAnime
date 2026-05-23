return function(ctx)
	local ReplicatedStorage = ctx.ReplicatedStorage
	local PhysicsService = ctx.PhysicsService
	local ServerStorage = ctx.ServerStorage
	local Players = ctx.Players
	local PlayersModule = ctx.PlayersModule
	local SetProperties = ctx.SetProperties
	local Grounding = ctx.Grounding
	local FinishBarrier = ctx.FinishBarrier
	local PathUtils = ctx.PathUtils
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local AreasConfigurations = ctx.AreasConfigurations
	local ThingsConfigurations = ctx.ThingsConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RetrieveThingDataFunction = ctx.RetrieveThingDataFunction
	local CreateThingFunction = ctx.CreateThingFunction
	local AnimateThingEvent = ctx.AnimateThingEvent
	local DropEvent = ctx.DropEvent
	local Things = ctx.Things
	local ThingsData = ctx.ThingsData
	local FACING_TARGET_PATH = ctx.FACING_TARGET_PATH
	local DEFAULT_INITIAL_POPULATION = ctx.DEFAULT_INITIAL_POPULATION
	local DEFAULT_MAX_POPULATION = ctx.DEFAULT_MAX_POPULATION
	local DEFAULT_SPAWN_SPACING = ctx.DEFAULT_SPAWN_SPACING
	local DEFAULT_SPAWN_JITTER = ctx.DEFAULT_SPAWN_JITTER
	local DEFAULT_INITIAL_TIME_SCALE_MIN = ctx.DEFAULT_INITIAL_TIME_SCALE_MIN
	local DEFAULT_INITIAL_TIME_SCALE_MAX = ctx.DEFAULT_INITIAL_TIME_SCALE_MAX
	local DEFAULT_SPAWN_TIME_SCALE_MIN = ctx.DEFAULT_SPAWN_TIME_SCALE_MIN
	local DEFAULT_SPAWN_TIME_SCALE_MAX = ctx.DEFAULT_SPAWN_TIME_SCALE_MAX
	local THING_GUI_MAX_DISTANCE = ctx.THING_GUI_MAX_DISTANCE
	local THING_CARRY_HOLD_DURATION = ctx.THING_CARRY_HOLD_DURATION
	local PICK_UP_PROMPT_TEXT = ctx.PICK_UP_PROMPT_TEXT
	local CARRIED_THING_WELD_NAME = ctx.CARRIED_THING_WELD_NAME
	local CARRIED_FORWARD_OFFSET = ctx.CARRIED_FORWARD_OFFSET
	local CARRIED_BASE_VERTICAL_OFFSET = ctx.CARRIED_BASE_VERTICAL_OFFSET
	local CARRIED_STACK_PADDING = ctx.CARRIED_STACK_PADDING
	local CARRIED_PHYSICS_ATTRIBUTE_PREFIX = ctx.CARRIED_PHYSICS_ATTRIBUTE_PREFIX
	local getSpawnZone = ctx.getSpawnZone
	local getFacingTarget = ctx.getFacingTarget
	local getAreaThingConfiguration = ctx.getAreaThingConfiguration
	local getAreaThings = ctx.getAreaThings
	local getAreaThingCount = ctx.getAreaThingCount
	local canSpawnInArea = ctx.canSpawnInArea
	local getThingGui = ctx.getThingGui
	local refreshCarriedThingPositions = ctx.refreshCarriedThingPositions
	local getGridSpawnPosition = ctx.getGridSpawnPosition
	local getSpawnCFrame = ctx.getSpawnCFrame
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

	local ThingGui = ctx.Resources:WaitForChild("ThingGui")

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
end

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
	local AnimeConfigurations = ctx.AnimeConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RetrieveAnimeDataFunction = ctx.RetrieveAnimeDataFunction
	local CreateAnimeFunction = ctx.CreateAnimeFunction
	local AnimateAnimeEvent = ctx.AnimateAnimeEvent
	local DropEvent = ctx.DropEvent
	local AnimeModule = ctx.Anime
	local AnimeRegistry = ctx.AnimeData
	local FACING_TARGET_PATH = ctx.FACING_TARGET_PATH
	local DEFAULT_INITIAL_POPULATION = ctx.DEFAULT_INITIAL_POPULATION
	local DEFAULT_MAX_POPULATION = ctx.DEFAULT_MAX_POPULATION
	local DEFAULT_SPAWN_SPACING = ctx.DEFAULT_SPAWN_SPACING
	local DEFAULT_SPAWN_JITTER = ctx.DEFAULT_SPAWN_JITTER
	local DEFAULT_INITIAL_TIME_SCALE_MIN = ctx.DEFAULT_INITIAL_TIME_SCALE_MIN
	local DEFAULT_INITIAL_TIME_SCALE_MAX = ctx.DEFAULT_INITIAL_TIME_SCALE_MAX
	local DEFAULT_SPAWN_TIME_SCALE_MIN = ctx.DEFAULT_SPAWN_TIME_SCALE_MIN
	local DEFAULT_SPAWN_TIME_SCALE_MAX = ctx.DEFAULT_SPAWN_TIME_SCALE_MAX
	local ANIME_GUI_MAX_DISTANCE = ctx.ANIME_GUI_MAX_DISTANCE
	local ANIME_CARRY_HOLD_DURATION = ctx.ANIME_CARRY_HOLD_DURATION
	local PICK_UP_PROMPT_TEXT = ctx.PICK_UP_PROMPT_TEXT
	local CARRIED_ANIME_WELD_NAME = ctx.CARRIED_ANIME_WELD_NAME
	local CARRIED_FORWARD_OFFSET = ctx.CARRIED_FORWARD_OFFSET
	local CARRIED_BASE_VERTICAL_OFFSET = ctx.CARRIED_BASE_VERTICAL_OFFSET
	local CARRIED_STACK_PADDING = ctx.CARRIED_STACK_PADDING
	local CARRIED_PHYSICS_ATTRIBUTE_PREFIX = ctx.CARRIED_PHYSICS_ATTRIBUTE_PREFIX
	local getSpawnZone = ctx.getSpawnZone
	local getFacingTarget = ctx.getFacingTarget
	local getAreaAnimeConfiguration = ctx.getAreaAnimeConfiguration
	local getAreaAnime = ctx.getAreaAnime
	local getAreaAnimeCount = ctx.getAreaAnimeCount
	local canSpawnInArea = ctx.canSpawnInArea
	local getAnimeGui = ctx.getAnimeGui
	local refreshCarriedAnimePositions = ctx.refreshCarriedAnimePositions
	local getGridSpawnPosition = ctx.getGridSpawnPosition
	local getSpawnCFrame = ctx.getSpawnCFrame
local function findAnimeTemplate(Animes, Mutation, Area, Anime)
	local function findInMutation(MutationName)
		local MutationFolder = Animes and Animes:FindFirstChild(MutationName)
		local AreaFolder = MutationFolder and MutationFolder:FindFirstChild(Area)

		return AreaFolder and AreaFolder:FindFirstChild(Anime)
	end

	local AnimeTemplate = findInMutation(Mutation)
	if AnimeTemplate then
		return AnimeTemplate
	end

	if Mutation ~= "Default" then
		return findInMutation("Default")
	end
end

local function getMutationAuraParts(Anime)
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
		local Part = Anime:FindFirstChild(PartName, true)
		if Part and Part:IsA("BasePart") and Part.Transparency < 0.95 then
			table.insert(AuraParts, Part)
		end
	end

	if #AuraParts == 0 then
		for _, Descendant in ipairs(Anime:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end
			if Descendant == Anime.PrimaryPart then continue end
			if Descendant.Transparency >= 0.95 then continue end

			table.insert(AuraParts, Descendant)

			if #AuraParts >= 6 then break end
		end
	end

	if #AuraParts == 0 and Anime.PrimaryPart then
		table.insert(AuraParts, Anime.PrimaryPart)
	end

	return AuraParts
end

local function applyMutationAura(Anime, Mutation, MutationConfiguration)
	if not Mutation or Mutation == "Default" or not MutationConfiguration then return end

	local AuraConfiguration = MutationConfiguration.Aura
	if not AuraConfiguration then return end

	local HighlightConfiguration = AuraConfiguration.Highlight
	if HighlightConfiguration then
		local Highlight = Instance.new("Highlight")
		Highlight.Name = "MutationHighlight"
		Highlight.Adornee = Anime
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = HighlightConfiguration.FillColor or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Highlight.FillTransparency = HighlightConfiguration.FillTransparency or 0.65
		Highlight.OutlineColor = HighlightConfiguration.OutlineColor or Highlight.FillColor
		Highlight.OutlineTransparency = HighlightConfiguration.OutlineTransparency or 0.15
		Highlight.Parent = Anime
	end

	local ParticleConfiguration = AuraConfiguration.Particle
	if ParticleConfiguration then
		for _, AuraPart in ipairs(getMutationAuraParts(Anime)) do
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
	if LightConfiguration and Anime.PrimaryPart then
		local Light = Instance.new("PointLight")
		Light.Name = "MutationAuraLight"
		Light.Color = LightConfiguration.Color or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Light.Brightness = LightConfiguration.Brightness or 0.6
		Light.Range = LightConfiguration.Range or 8
		Light.Parent = Anime.PrimaryPart
	end
end

function AnimeModule.Create(Area, AreaConfiguration, Anime, AnimeConfiguration, Mutation, MutationConfiguration, Level)
	Level = Level or 1

	local Data = setmetatable({}, {__index = AnimeModule})

	local Animes = ServerStorage:FindFirstChild("Animes")
	local AnimeTemplate = findAnimeTemplate(Animes, Mutation, Area, Anime)

	if not AnimeTemplate then
		warn(string.format("Missing anime asset: %s.%s.%s or Default.%s.%s", tostring(Mutation), tostring(Area), tostring(Anime), tostring(Area), tostring(Anime)))
		return
	end

	if not AnimeTemplate.PrimaryPart then
		warn(string.format("%s anime has no primary part.", AnimeTemplate.Name))
		return
	end

	Anime = AnimeTemplate:Clone()
	applyMutationAura(Anime, Mutation, MutationConfiguration)

	Data.Anime = Anime
	Data.Mutation = Mutation
	Data.Level = Level
	Data.AnimationTracks = {}

	for _, Descendant in ipairs(Anime:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		Descendant.CollisionGroup = "Anime"

		if Descendant == Anime.PrimaryPart then
			Descendant.Anchored = true
		else
			Descendant.Anchored = false
		end
	end

	local AnimeAttachment = Instance.new("Attachment")
	AnimeAttachment.Name = "AnimeAttachment"
	AnimeAttachment.Parent = Anime.PrimaryPart

	local AnimeGui = ctx.Resources:WaitForChild("AnimeGui")

	AnimeGui = AnimeGui:Clone()

	AnimeGui.Time.LayoutOrder = 0
	AnimeGui.Mutation.LayoutOrder = 1
	AnimeGui.Area.LayoutOrder = 2
	AnimeGui.Anime.LayoutOrder = 3
	AnimeGui.Money.LayoutOrder = 4

	for _, LabelName in ipairs({"Mutation", "Anime", "Area", "Money", "Time"}) do
		local Label = AnimeGui:FindFirstChild(LabelName)
		if Label and Label:IsA("TextLabel") then
			Label.Size = UDim2.new(0.9, 0, Label.Size.Y.Scale, Label.Size.Y.Offset)
		end
	end

	AnimeGui.Anime.Text = string.format("%s (Lvl %s)", Anime.Name, Level)
	AnimeGui.Area.Text = Area

	local Multiplier = MutationConfiguration.Multiplier or 1

	AnimeGui.Money.Text = string.format("$%s/s", Format.Number((AnimeConfiguration.Levels[Level].Money or 0) * Multiplier))
	AnimeGui.Money.Visible = true

	AnimeGui.Area.TextColor3 = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

	if Mutation and Mutation ~= "Default" then
		AnimeGui.Mutation.Text = Mutation

		AnimeGui.Mutation.TextColor3 = MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)

		AnimeGui.Mutation.Visible = true
	end

	AnimeGui.Parent = AnimeAttachment
	AnimeGui.MaxDistance = ANIME_GUI_MAX_DISTANCE
	AnimeGui.Enabled = true

	AnimeAttachment.CFrame = CFrame.new(Vector3.new(0, AnimeConfiguration.YOffset + AnimeGui.Size.Y.Scale / 2 + 1, 0))

	AnimeRegistry[Anime] = Data

	return Anime
end
end

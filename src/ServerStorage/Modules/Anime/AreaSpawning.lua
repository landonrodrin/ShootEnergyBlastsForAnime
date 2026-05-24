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
	local RequestGuard = ctx.RequestGuard
	local RequestPolicy = ctx.RequestPolicy
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local AreasConfigurations = ctx.AreasConfigurations
	local AnimeConfigurations = ctx.AnimeConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RetrieveAnimeDataFunction = ctx.RetrieveAnimeDataFunction
	local CreateAnimeFunction = ctx.CreateAnimeFunction
	local AnimateAnimeEvent = ctx.AnimateAnimeEvent
	local DropEvent = ctx.DropEvent
	local Packets = ctx.Packets
	local AnimeModule = ctx.Anime
	local AnimeRegistry = ctx.AnimeData
	local SetupTrove = ctx.SetupTrove
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
	local NetworkListenersStarted = false
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

local function getAreaAnimeConfiguration(Anime)
	if not Anime or not Anime.Name then return end

	return AnimeConfigurations[Anime.Name]
end

local function getAreaAnime(Area)
	local AreaAnime = {}
	local AnimeFolder = workspace:FindFirstChild("Anime")
	if not AnimeFolder then return AreaAnime end

	for _, Anime in ipairs(AnimeFolder:GetChildren()) do
		local AnimeConfiguration = getAreaAnimeConfiguration(Anime)
		if AnimeConfiguration and AnimeConfiguration.Area == Area and Anime.PrimaryPart then
			table.insert(AreaAnime, Anime)
		end
	end

	return AreaAnime
end

local function getAreaAnimeCount(Area)
	return #getAreaAnime(Area)
end

local function canSpawnInArea(Area, AreaConfiguration)
	local MaxPopulation = AreaConfiguration.MaxPopulation or DEFAULT_MAX_POPULATION

	return getAreaAnimeCount(Area) < MaxPopulation
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

local function hasAnimeTemplate(Area, Anime, Mutation)
	local Animes = ServerStorage:FindFirstChild("Animes")

	local function hasInMutation(MutationName)
		local MutationFolder = Animes and Animes:FindFirstChild(MutationName)
		local AreaFolder = MutationFolder and MutationFolder:FindFirstChild(Area)

		return AreaFolder and AreaFolder:FindFirstChild(Anime) ~= nil
	end

	if hasInMutation(Mutation) then
		return true
	end

	return Mutation ~= "Default" and hasInMutation("Default")
end

local function areaHasSpawnableAnime(Area)
	for Anime, AnimeConfiguration in pairs(AnimeConfigurations) do
		if AnimeConfiguration.Area ~= Area then continue end

		for Mutation in pairs(MutationsConfigurations) do
			if hasAnimeTemplate(Area, Anime, Mutation) then
				return true
			end
		end

		if hasAnimeTemplate(Area, Anime, "Default") then
			return true
		end
	end

	return false
end

local function getRandomTimeScale(Range, DefaultMinimum, DefaultMaximum)
	local Minimum = Range and Range.Minimum or DefaultMinimum
	local Maximum = Range and Range.Maximum or DefaultMaximum

	if Maximum < Minimum then
		Maximum = Minimum
	end

	return Minimum + (math.random() * (Maximum - Minimum))
end

local function getRandomLevel(AnimeConfiguration)
	local MaximumConfiguredLevel = 1
	for Level in pairs(AnimeConfiguration.Levels or {}) do
		if Level > MaximumConfiguredLevel then
			MaximumConfiguredLevel = Level
		end
	end

	local LevelRange = AnimeConfiguration.Level or {}
	local Minimum = math.clamp(LevelRange.Minimum or 1, 1, MaximumConfiguredLevel)
	local Maximum = math.clamp(LevelRange.Maximum or MaximumConfiguredLevel, Minimum, MaximumConfiguredLevel)

	return math.random(Minimum, Maximum)
end

local function spawnRandomAnime(Area, AreaConfiguration, SpawnOptions)
	if not canSpawnInArea(Area, AreaConfiguration) then return end

	local Attempts = AreaConfiguration.SpawnAttempts or 30
	SpawnOptions = SpawnOptions or {}

	for _ = 1, Attempts do
		local Anime, AnimeConfiguration, Mutation, MutationConfiguration, Level = AnimeModule.Random(Area)
		if not Anime then return end
		if not hasAnimeTemplate(Area, Anime, Mutation) then continue end

		local CreatedAnime = AnimeModule.Create(Area, AreaConfiguration, Anime, AnimeConfiguration, Mutation, MutationConfiguration, Level)
		if CreatedAnime then
			local AnimeData = AnimeRegistry[CreatedAnime]
			if AnimeData then
				AnimeData.TimeScale = SpawnOptions.TimeScale or getRandomTimeScale(AreaConfiguration.SpawnTimeScale, DEFAULT_SPAWN_TIME_SCALE_MIN, DEFAULT_SPAWN_TIME_SCALE_MAX)
				AnimeData:Spawn()
			end

			if CreatedAnime.Parent then
				return CreatedAnime
			end
		end
	end
end

function AnimeModule.Setup()
	SetupTrove:Clean()

	local AnimeFolder = workspace:FindFirstChild("Anime") or Instance.new("Folder")
	AnimeFolder.Name = "Anime"
	AnimeFolder.Parent = workspace

	local ExistingAnimeData = {}
	for _, AnimeData in pairs(AnimeRegistry) do
		table.insert(ExistingAnimeData, AnimeData)
	end

	for _, AnimeData in ipairs(ExistingAnimeData) do
		if type(AnimeData) == "table" and AnimeData.Destroy then
			AnimeData:Destroy()
		end
	end

	AnimeFolder:ClearAllChildren()

	registerCollisionGroup("Anime")
	registerCollisionGroup("Players")
	setGroupsCollidable("Anime", "Players", false)
	setGroupsCollidable("Anime", "Anime", false)

	RetrieveAnimeDataFunction.OnInvoke = AnimeModule.Retrieve
	CreateAnimeFunction.OnInvoke = AnimeModule.Create

	SetupTrove:Connect(AnimateAnimeEvent.Event, AnimeModule.Animate)

	SetupTrove:Connect(Players.PlayerAdded, function(Player)
		SetupTrove:Connect(Player.CharacterRemoving, function()
			AnimeModule.Drop(Player)
		end)
	end)

	for _, Player in ipairs(Players:GetPlayers()) do
		SetupTrove:Connect(Player.CharacterRemoving, function()
			AnimeModule.Drop(Player)
		end)
	end

	if not NetworkListenersStarted then
		NetworkListenersStarted = true

		Packets.dropRequest.listen(function(_, Player)
			if not Player then return end
			local Carrying = PlayersModule.Retrieve(Player, "Carrying")
			if not Carrying or #Carrying == 0 then return end
			if not RequestGuard.Allow(Player, "dropRequest", RequestPolicy.Cooldowns.Drop) then return end

			AnimeModule.Drop(Player)
		end)
	end

	SetupTrove:Connect(Players.PlayerRemoving, function(Player)
		AnimeModule.Drop(Player)
	end)

	SetupTrove:Add(FinishBarrier.OnReturn(function(Player)
		AnimeModule.Zone(Player)
	end, 100))

	for Area, AreaConfiguration in pairs(AreasConfigurations) do
		if AreaConfiguration.Enabled == false then continue end
		if not areaHasSpawnableAnime(Area) then
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

			if not spawnRandomAnime(Area, AreaConfiguration, {TimeScale = TimeScale}) then
				break
			end
		end

		local SpawnLoopActive = true
		SetupTrove:Add(function()
			SpawnLoopActive = false
		end)

		SetupTrove:Add(task.spawn(function()
			local Minimum = AreaConfiguration.Rate and AreaConfiguration.Rate.Minimum and math.clamp(AreaConfiguration.Rate.Minimum, 0.01, math.huge) or 0.01
			local Maximum = AreaConfiguration.Rate and AreaConfiguration.Rate.Maximum and AreaConfiguration.Rate.Maximum or 5

			local Chance = AreaConfiguration.Chance or 1

			while SpawnLoopActive and task.wait(math.random(Minimum, Maximum)) do
				if not canSpawnInArea(Area, AreaConfiguration) then continue end
				if math.random() > Chance then continue end

				spawnRandomAnime(Area, AreaConfiguration)
			end
		end))

		if not AreaConfiguration.Guaranteed or AreaConfiguration.Guaranteed <= 0 then continue end

		local GuaranteedLoopActive = true
		SetupTrove:Add(function()
			GuaranteedLoopActive = false
		end)

		SetupTrove:Add(task.spawn(function()
			local GuaranteedArea = ctx.Resources:WaitForChild("GuaranteedArea")

			GuaranteedArea = GuaranteedArea:Clone()
			SetupTrove:Add(GuaranteedArea)

			local Colour = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

			Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)

			GuaranteedArea.Text = string.format("<font color=\"%s\">%s</font> appears in %s", Colour, Area, Format.Time(AreaConfiguration.Guaranteed))

			GuaranteedArea.Name = Area
			GuaranteedArea.Parent = workspace.GuaranteedAreas:WaitForChild("GuaranteedAreasGui")
			GuaranteedArea.Visible = true

			local Timer = tonumber(AreaConfiguration.Guaranteed)

			while GuaranteedLoopActive and task.wait(1) do
				Timer -= 1

				GuaranteedArea.Text = string.format("<font color=\"%s\">%s</font> appears in %s", Colour, Area, Format.Time(Timer))

				if Timer > 0 then continue end

				Timer = tonumber(AreaConfiguration.Guaranteed)
				if not canSpawnInArea(Area, AreaConfiguration) then continue end

				spawnRandomAnime(Area, AreaConfiguration)
			end
		end))
	end
end

function AnimeModule.Random(Area)
	local AreaAnime = {}

	local TotalChance = 0

	for Anime, AnimeConfiguration in pairs(AnimeConfigurations) do
		local AnimeArea = AnimeConfiguration.Area

		if not AnimeArea or AnimeArea ~= Area then continue end

		TotalChance += AnimeConfiguration.Chance or 1

		AreaAnime[Anime] = AnimeConfiguration
	end

	if TotalChance <= 0 then
		return
	end

	local RandomAnime = nil
	local RandomConfiguration = nil

	local Roll = math.random() * TotalChance
	local Sum = 0

	for Anime, AnimeConfiguration in pairs(AreaAnime) do
		Sum += AnimeConfiguration.Chance or 1

		if Roll > Sum then continue end

		RandomAnime = Anime
		RandomConfiguration = AnimeConfiguration

		break
	end

	if not RandomAnime then return end

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

	return RandomAnime, RandomConfiguration, RandomMutation, RandomMutationConfiguration, getRandomLevel(RandomConfiguration)
end
	ctx.getSpawnZone = getSpawnZone
	ctx.getFacingTarget = getFacingTarget
	ctx.getAreaAnimeConfiguration = getAreaAnimeConfiguration
	ctx.getAreaAnime = getAreaAnime
	ctx.getAreaAnimeCount = getAreaAnimeCount
	ctx.canSpawnInArea = canSpawnInArea
end

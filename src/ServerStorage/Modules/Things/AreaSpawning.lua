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
			local GuaranteedArea = ctx.Resources:WaitForChild("GuaranteedArea")

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
	ctx.getSpawnZone = getSpawnZone
	ctx.getFacingTarget = getFacingTarget
	ctx.getAreaThingConfiguration = getAreaThingConfiguration
	ctx.getAreaThings = getAreaThings
	ctx.getAreaThingCount = getAreaThingCount
	ctx.canSpawnInArea = canSpawnInArea
end

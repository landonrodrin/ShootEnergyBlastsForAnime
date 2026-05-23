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
end

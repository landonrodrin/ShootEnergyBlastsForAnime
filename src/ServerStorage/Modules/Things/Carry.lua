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
	ctx.getThingGui = getThingGui
	ctx.resetThingTimer = resetThingTimer
	ctx.refreshCarriedThingPositions = refreshCarriedThingPositions
end

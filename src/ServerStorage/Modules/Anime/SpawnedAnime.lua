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
	local Trove = ctx.Trove
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
function AnimeModule:Spawn()
	local Anime = self.Anime
	if not Anime then return end

	if self.Trove then
		self.Trove:Destroy()
	end

	self.Destroyed = false
	local SpawnTrove = Trove.new()
	self.Trove = SpawnTrove

	local AnimeConfiguration = AnimeConfigurations[Anime.Name]

	local AreaName = AnimeConfiguration.Area
	local AreaConfiguration = AreasConfigurations[AreaName]
	local SpawnZone = getSpawnZone(AreaName, AreaConfiguration)
	if not SpawnZone then
		self:Destroy()

		return
	end

	local Position = getGridSpawnPosition(AreaName, AreaConfiguration, AnimeConfiguration, SpawnZone)

	if not Position then
		self:Destroy()

		return
	end

	Anime.Parent = workspace:WaitForChild("Anime")

	local TargetCFrame = getSpawnCFrame(Position, AnimeConfiguration, SpawnZone)

	Anime:PivotTo(TargetCFrame)
	Grounding.AlignBottomToSurface(Anime, SpawnZone, AnimeConfiguration)

	local _IdleTrack = AnimeModule.Animate(Anime, AnimeConfiguration.AnimationsIds.Idle, true)
	Grounding.AlignBottomToSurfaceAfterAnimation(Anime, SpawnZone, AnimeConfiguration, SpawnTrove)

	local ProximityPrompt = SpawnTrove:Add(Instance.new("ProximityPrompt"))
	ProximityPrompt.Enabled = true
	ProximityPrompt.ActionText = PICK_UP_PROMPT_TEXT
	ProximityPrompt.HoldDuration = ANIME_CARRY_HOLD_DURATION
	ProximityPrompt.ObjectText = Anime.Name
	ProximityPrompt.RequiresLineOfSight = false
	ProximityPrompt.Parent = Anime.PrimaryPart

	SetProperties.AllClients(ProximityPrompt, {Enabled = true, ActionText = PICK_UP_PROMPT_TEXT})

	for _, Player in ipairs(Players:GetPlayers()) do
		local Carrying = PlayersModule.Retrieve(Player, "Carrying")
		if not Carrying then continue end

		if #Carrying < PlayersModule.Retrieve(Player, "Carry") then continue end

		SetProperties.Client(Player, ProximityPrompt, {Enabled = false, ActionText = PICK_UP_PROMPT_TEXT})
	end

	SpawnTrove:Connect(ProximityPrompt.Triggered, function(Player)
		if (self.Time or 0) < 1 then return end

		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			if OtherPlayer == Player then continue end

			local Carrying = PlayersModule.Retrieve(OtherPlayer, "Carrying")
			if not Carrying then continue end

			if table.find(Carrying, Anime) then return end
		end

		local Carrying = PlayersModule.Retrieve(Player, "Carrying")

		if Carrying and (table.find(Carrying, Anime) or #Carrying >= PlayersModule.Retrieve(Player, "Carry")) then
			AnimeModule.Drop(Player)

			return
		elseif not Carrying then
			Carrying = {}
		end

		table.insert(Carrying, Anime)

		PlayersModule.Replace(Player, "Carrying", Carrying)

		self.Carried = Player

		AnimeRegistry[Anime] = self

		PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.Carry, true)

		local AnimeGui = getAnimeGui(Anime)
		if AnimeGui and AnimeGui:FindFirstChild("Time") then
			AnimeGui.Time.Visible = false
		end

		for _, OtherAnime in ipairs(workspace.Anime:GetChildren()) do
			SpawnTrove:Add(task.spawn(function()
				if not OtherAnime.PrimaryPart then return end

				local OtherProximityPrompt = OtherAnime.PrimaryPart:FindFirstChild("ProximityPrompt")
				if not OtherProximityPrompt then return end

				if OtherProximityPrompt == ProximityPrompt then
					SetProperties.AllClients(OtherProximityPrompt, {Enabled = false, ActionText = PICK_UP_PROMPT_TEXT})

					return
				end

				if #Carrying < PlayersModule.Retrieve(Player, "Carry") then return end

				SetProperties.Client(Player, OtherProximityPrompt, {Enabled = false, ActionText = PICK_UP_PROMPT_TEXT})
			end))
		end

		refreshCarriedAnimePositions(Player, Carrying)

		Packets.dropState.sendTo({
			CanDrop = true,
		}, Player)
	end)

	local AnimeAttachment = Anime.PrimaryPart:WaitForChild("AnimeAttachment")
	local AnimeGui = AnimeAttachment:WaitForChild("AnimeGui")

	local BaseTime = AnimeConfiguration.Time or 10
	local TimeScale = self.TimeScale or 1
	self.Time = math.max(1, math.floor(BaseTime * TimeScale))

	AnimeGui.Time.Text = Format.Time(self.Time)

	local CountdownActive = true
	SpawnTrove:Add(function()
		CountdownActive = false
	end)

	SpawnTrove:Add(task.spawn(function()
		while CountdownActive and Anime and Anime.Parent and not self.Destroyed do
			while self.Carried do
				task.wait(0.01)

				if not CountdownActive or self.Destroyed or not Anime or not Anime.Parent then return end
			end

			task.wait(1)

			if not CountdownActive or self.Destroyed or not Anime or not Anime.Parent then break end

			self.Time = (self.Time or 0) - 1

			if self.Time <= 0 then
				self:Destroy()

				break
			end

			AnimeGui.Time.Text = Format.Time(self.Time)
		end
	end))

	AnimeGui.Time.Visible = true
end

function AnimeModule:Destroy()
	local Anime = self.Anime
	if not Anime then return end

	self.Destroyed = true
	if self.Trove then
		self.Trove:Destroy()
		self.Trove = nil
	end

	AnimeRegistry[Anime] = nil
	Anime:Destroy()
	self.Anime = nil
end
end

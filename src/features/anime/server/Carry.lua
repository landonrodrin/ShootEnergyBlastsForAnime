return function(ctx)
	local Players = ctx.Players
	local PlayersModule = ctx.PlayersModule
	local SetProperties = ctx.SetProperties
	local Grounding = ctx.Grounding
	local Format = ctx.Format
	local AnimeConfigurations = ctx.AnimeConfigurations
	local Packets = ctx.Packets
	local AnimeModule = ctx.Anime
	local AnimeRegistry = ctx.AnimeData
	local PICK_UP_PROMPT_TEXT = ctx.PICK_UP_PROMPT_TEXT
	local CARRIED_ANIME_WELD_NAME = ctx.CARRIED_ANIME_WELD_NAME
	local CARRIED_FORWARD_OFFSET = ctx.CARRIED_FORWARD_OFFSET
	local CARRIED_BASE_VERTICAL_OFFSET = ctx.CARRIED_BASE_VERTICAL_OFFSET
	local CARRIED_STACK_PADDING = ctx.CARRIED_STACK_PADDING
	local CARRIED_PHYSICS_ATTRIBUTE_PREFIX = ctx.CARRIED_PHYSICS_ATTRIBUTE_PREFIX
local function getAnimeGui(Anime)
	local PrimaryPart = Anime and Anime.PrimaryPart
	local AnimeAttachment = PrimaryPart and PrimaryPart:FindFirstChild("AnimeAttachment")
	return AnimeAttachment and AnimeAttachment:FindFirstChild("AnimeGui")
end

local function resetAnimeTimer(Anime, AnimeData, AnimeConfiguration)
	if not AnimeData or not AnimeConfiguration then return end

	local BaseTime = AnimeConfiguration.Time or 10
	local TimeScale = AnimeData.TimeScale or 1
	local Time = math.max(1, math.floor(BaseTime * TimeScale))
	AnimeData.Time = Time

	local AnimeGui = getAnimeGui(Anime)
	if AnimeGui and AnimeGui:FindFirstChild("Time") then
		AnimeGui.Time.Text = Format.Time(Time)
		AnimeGui.Time.Visible = true
	end
end

local function removeCarryWelds(Player, Anime)
	if Anime then
		for _, Descendant in ipairs(Anime:GetDescendants()) do
			if Descendant:IsA("WeldConstraint") and Descendant.Name == CARRIED_ANIME_WELD_NAME then
				Descendant:Destroy()
			end
		end
	end

	local Character = Player.Character
	local Root = Character and Character.PrimaryPart
	if Root then
		for _, Child in ipairs(Root:GetChildren()) do
			if Child:IsA("WeldConstraint") and Child.Name == CARRIED_ANIME_WELD_NAME then
				Child:Destroy()
			end
		end
	end
end

local function setCarriedPhysics(Anime)
	for _, Descendant in ipairs(Anime:GetDescendants()) do
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

local function restoreAnimePhysics(Anime)
	for _, Descendant in ipairs(Anime:GetDescendants()) do
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

		Descendant.CollisionGroup = "Anime"
	end
end

local function getCarryCFrame(Character, Anime, StackIndex)
	local Root = Character and Character.PrimaryPart
	if not Root then return end

	local _, Size = Anime:GetBoundingBox()
	local StackOffset = math.max(Size.Y * 0.55 + CARRIED_STACK_PADDING, 1.25) * math.max((StackIndex or 1) - 1, 0)
	local Position = (Root.CFrame * CFrame.new(0, CARRIED_BASE_VERTICAL_OFFSET + StackOffset, CARRIED_FORWARD_OFFSET)).Position

	return CFrame.lookAt(Position, Position + Root.CFrame.LookVector)
end

local function weldAnimeToPlayer(Player, Anime, StackIndex)
	local Character = Player.Character
	local Root = Character and Character.PrimaryPart
	if not Root or not Anime.PrimaryPart then return end

	removeCarryWelds(Player, Anime)
	setCarriedPhysics(Anime)

	local CarryCFrame = getCarryCFrame(Character, Anime, StackIndex)
	if CarryCFrame then
		Anime:PivotTo(CarryCFrame)
	end

	local WeldConstraint = Instance.new("WeldConstraint")
	WeldConstraint.Name = CARRIED_ANIME_WELD_NAME
	WeldConstraint.Part0 = Anime.PrimaryPart
	WeldConstraint.Part1 = Root
	WeldConstraint.Parent = Anime.PrimaryPart
end

local function refreshCarriedAnimePositions(Player, Carrying)
	for Index, Anime in ipairs(Carrying or {}) do
		if Anime and Anime.Parent and Anime.PrimaryPart then
			weldAnimeToPlayer(Player, Anime, Index)
		end
	end
end

local function alignDroppedAnimeToGround(Player, Anime, AnimeConfiguration)
	local Character = Player.Character
	local Root = Character and Character.PrimaryPart
	local Origin = (Anime:GetPivot().Position) + Vector3.new(0, 8, 0)
	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParameters.FilterDescendantsInstances = {Anime, Character}

	local Result = workspace:Raycast(Origin, Vector3.new(0, -80, 0), RaycastParameters)
	if Result then
		Grounding.AlignBottomToY(Anime, Result.Position.Y, AnimeConfiguration)
	elseif Root then
		Anime:PivotTo(CFrame.lookAt(Root.Position + Root.CFrame.LookVector * 2, Root.Position + Root.CFrame.LookVector * 3))
	end
end

function AnimeModule.Drop(Player, ResetTimers)
	if ResetTimers == nil then
		ResetTimers = true
	end

	local Carrying = PlayersModule.Retrieve(Player, "Carrying")

	if not Carrying then return end

	Packets.dropState.sendTo({
		CanDrop = false,
	}, Player)

	for _, Anime in ipairs(Carrying) do
		local AnimeConfiguration = AnimeConfigurations[Anime.Name]
		local AnimeData = AnimeRegistry[Anime]
		if not AnimeConfiguration or not AnimeData then continue end
		if not Anime.Parent or not Anime.PrimaryPart then
			AnimeRegistry[Anime] = nil
			continue
		end

		removeCarryWelds(Player, Anime)

		local AnimeFolder = workspace:FindFirstChild("Anime")
		if AnimeFolder then
			Anime.Parent = AnimeFolder
		end

		restoreAnimePhysics(Anime)
		alignDroppedAnimeToGround(Player, Anime, AnimeConfiguration)

		local ProximityPrompt = Anime.PrimaryPart:FindFirstChild("ProximityPrompt")
		if ProximityPrompt then
			SetProperties.AllClients(ProximityPrompt, {Enabled = true, ActionText = PICK_UP_PROMPT_TEXT})
		end

		local AnimeGui = getAnimeGui(Anime)
		if AnimeGui and AnimeGui:FindFirstChild("Carried") then
			AnimeGui.Carried.Visible = false
		end

		AnimeData.Carried = nil
		if ResetTimers then
			resetAnimeTimer(Anime, AnimeData, AnimeConfiguration)
		end
	end

	for _, Anime in ipairs(workspace.Anime:GetChildren()) do
		if not Anime.PrimaryPart then continue end

		local OtherProximityPrompt = Anime.PrimaryPart:FindFirstChild("ProximityPrompt")
		if not OtherProximityPrompt then continue end

		SetProperties.Client(Player, OtherProximityPrompt, {Enabled = true, ActionText = PICK_UP_PROMPT_TEXT})

		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			local Carrying = PlayersModule.Retrieve(OtherPlayer, "Carrying")
			if not Carrying then continue end

			if table.find(Carrying, Anime) then break end
		end
	end

	if Player:GetAttribute("HoldState") == "Carry" then
		Player:SetAttribute("HoldState", nil)
	end

	PlayersModule.Replace(Player, "Carrying", nil)
	PlayersModule.Replace(Player, "Carried", nil)
end

function AnimeModule.Zone(Player)
	local Carrying = PlayersModule.Retrieve(Player, "Carrying")
	if not Carrying then return end

	local ReturningAnime = {}
	for _, Anime in ipairs(Carrying) do
		local Name = Anime.Name
		local AnimeConfiguration = AnimeConfigurations[Name]
		local Data = AnimeRegistry[Anime]

		if AnimeConfiguration and Data then
			table.insert(ReturningAnime, {
				Anime = Anime,
				Name = Name,
				AnimeConfiguration = AnimeConfiguration,
				Mutation = Data.Mutation,
				Level = Data.Level or 1
			})
		end
	end

	AnimeModule.Drop(Player, false)

	for _, AnimeEntry in ipairs(ReturningAnime) do
		local Data = AnimeRegistry[AnimeEntry.Anime]
		if not Data then continue end

		Data:Destroy()

		PlayersModule.Tool(Player, AnimeEntry.Name, AnimeEntry.AnimeConfiguration, AnimeEntry.Mutation, AnimeEntry.Level, true)
	end
end
	ctx.getAnimeGui = getAnimeGui
	ctx.resetAnimeTimer = resetAnimeTimer
	ctx.refreshCarriedAnimePositions = refreshCarriedAnimePositions
end

return function(ctx)
	local DEFAULT_SPAWN_SPACING = ctx.DEFAULT_SPAWN_SPACING
	local DEFAULT_SPAWN_JITTER = ctx.DEFAULT_SPAWN_JITTER
	local getFacingTarget = ctx.getFacingTarget
	local getAreaAnimeConfiguration = ctx.getAreaAnimeConfiguration
	local getAreaAnime = ctx.getAreaAnime
local function getCandidateSpacing(AreaConfiguration, AnimeConfiguration)
	return math.max(
		AreaConfiguration.SpawnSpacing or DEFAULT_SPAWN_SPACING,
		(AnimeConfiguration.Distance or 0) * 3
	)
end

local function scoreSpawnCandidate(Area, AreaConfiguration, AnimeConfiguration, Candidate)
	local Spacing = getCandidateSpacing(AreaConfiguration, AnimeConfiguration)
	local RequiredSpacing = Spacing * 0.75
	local NearbyCount = 0
	local NearestDistance = math.huge

	for _, OtherAnime in ipairs(getAreaAnime(Area)) do
		local OtherConfiguration = getAreaAnimeConfiguration(OtherAnime)
		if not OtherConfiguration then continue end

		local RequiredDistance = math.max(
			RequiredSpacing,
			(AnimeConfiguration.Distance or 0) + (OtherConfiguration.Distance or 0)
		)
		local Delta = OtherAnime.PrimaryPart.Position - Candidate
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

local function getGridSpawnPosition(Area, AreaConfiguration, AnimeConfiguration, SpawnZone)
	local AreaCFrame = SpawnZone.CFrame
	local AreaSize = SpawnZone.Size
	local Spacing = getCandidateSpacing(AreaConfiguration, AnimeConfiguration)
	local Jitter = math.min(AreaConfiguration.SpawnJitter or DEFAULT_SPAWN_JITTER, Spacing * 0.35)

	local Padding = math.max(AnimeConfiguration.Distance or 0, 2)
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
			local Score = scoreSpawnCandidate(Area, AreaConfiguration, AnimeConfiguration, Candidate)
			if Score and (not BestScore or Score < BestScore) then
				BestPosition = Candidate
				BestScore = Score
			end
		end
	end

	return BestPosition
end

local function getSpawnCFrame(Position, AnimeConfiguration, SpawnZone)
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
	ctx.getCandidateSpacing = getCandidateSpacing
	ctx.scoreSpawnCandidate = scoreSpawnCandidate
	ctx.getGridSpawnPosition = getGridSpawnPosition
	ctx.getSpawnCFrame = getSpawnCFrame
end

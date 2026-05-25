return function(ctx)
	local AnimeModule = ctx.Anime
	local AnimeRegistry = ctx.AnimeData
function AnimeModule.Animate(Anime, AnimationId, Bool)
	if not AnimationId or AnimationId == "" then return end

	local Data = AnimeRegistry[Anime]

	if not Data then return end

	local AnimatorOwner = Anime:FindFirstChildOfClass("Humanoid")

	if not AnimatorOwner then
		AnimatorOwner = Anime:FindFirstChildOfClass("AnimationController")

		if not AnimatorOwner then
			AnimatorOwner = Instance.new("AnimationController")
			AnimatorOwner.Parent = Anime
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
end

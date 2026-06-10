local WallConfig = {}

WallConfig.DamagePerShot = 1
WallConfig.FireRate = 8
WallConfig.BeamWidth = 1
WallConfig.ShotRadius = 1
WallConfig.ShootAnimationId = "rbxassetid://100628853975469"
WallConfig.AnimationFadeTime = 0.12
WallConfig.AnimationFallbackChargeTime = 0.75
WallConfig.MaxRange = 600
WallConfig.OriginTolerance = 12
WallConfig.DebrisLifetime = 2.5
WallConfig.ResetCooldown = 1.5

WallConfig.Beam = {
	TemplatePath = { "Effects", "KamehamehaBeamTemplate" },
	PrimaryColor = Color3.fromRGB(80, 185, 255),
	SecondaryColor = Color3.fromRGB(190, 245, 255),
	UpdateRate = 0,
	EndAttachmentNames = { "End", "SphereEnd", "SpikesEnd" },
}

WallConfig.ClientDebris = {
	NormalCount = 8,
	VipCount = 4,
	MaxActive = 96,
	SpawnPerFrame = 4,
	PoolPrewarmCount = 24,
	Lifetime = 1.6,
	FadeDuration = 0.45,
	ShrinkScale = 0.18,
	MinSize = Vector3.new(2.4, 1.5, 2.4),
	MaxSize = Vector3.new(4.4, 2.9, 4.4),
	SpawnSpread = 0.85,
	SpawnRandomWeight = 0.7,
	SpawnForwardOffset = 1.2,
	LinearSpeedMin = 16,
	LinearSpeedMax = 24,
	UpwardSpeedMin = 34,
	UpwardSpeedMax = 42,
	AngularSpeedMin = 4,
	AngularSpeedMax = 8,
	SideJitter = 0.75,
	Density = 0.4,
	Friction = 0.8,
	Elasticity = 0.5,
	FrictionWeight = 0.75,
	ElasticityWeight = 2,
}

WallConfig.FinishLinePath = { "Map", "Finish Line" }
WallConfig.FinishBarrierPath = { "Map", "Finish Line", "AnimeReturnBarrier" }

WallConfig.Walls = {
	{
		Name = "Breakable Wall",
		MaxHP = 50,
	},
	{
		Name = "Vip Wall Left",
		MaxHP = 1,
	},
	{
		Name = "Vip Wall Right",
		MaxHP = 1,
	},
}

return WallConfig

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

WallConfig.ClientDebris = {
	NormalCount = 12,
	VipCount = 6,
	MaxActive = 200,
	Lifetime = WallConfig.DebrisLifetime,
	FadeDuration = 0.75,
	ShrinkScale = 0.15,
	MinSize = Vector3.new(2.8, 1.8, 2.8),
	MaxSize = Vector3.new(5.2, 3.4, 5.2),
	SpawnSpread = 1,
	SpawnRandomWeight = 0.75,
	SpawnForwardOffset = 1.5,
	LinearSpeedMin = 20,
	LinearSpeedMax = 30,
	UpwardSpeedMin = 45,
	UpwardSpeedMax = 50,
	AngularSpeedMin = 5,
	AngularSpeedMax = 10,
	SideJitter = 1,
	Density = 0.4,
	Friction = 0.8,
	Elasticity = 0.5,
	FrictionWeight = 0.75,
	ElasticityWeight = 2,
}

WallConfig.FinishLinePath = { "Map", "Finish Line" }

WallConfig.Walls = {
	{
		Id = "BreakableWall1",
		DisplayName = "Breakable Wall 1",
		Path = { "Strips", "Strip 1", "Breakable Wall 1" },
		MaxHP = 50,
	},
	{
		Id = "VipWallLeft1",
		DisplayName = "Vip Wall Left 1",
		Path = { "Strips", "Strip 1", "Vip Wall Left 1" },
		MaxHP = 1,
	},
	{
		Id = "VipWallRight1",
		DisplayName = "Vip Wall Right 1",
		Path = { "Strips", "Strip 1", "Vip Wall Right 1" },
		MaxHP = 1,
	},
}

return WallConfig

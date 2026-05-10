local ThingsConfigurations = {
	["Thing"] = {
		Area = "Common",
		
		Chance = 0.6,
		
		Distance = 2,
		YOffset = 3.5,
	
		Level = {Minimum = 1, Maximum = 2},
		
		Time = 60,
		
		Index = 0,

		Levels = {
			[1] = {
				Money = 1000,
				Sell = 4000
			},
			
			[2] = {
				Upgrade = 10000,
				Money = 2000,
				Sell = 40000
			}
		},
		
		Icons = {
			["Default"] = "rbxassetid://117078608491917",
			["Gold"] = "rbxassetid://85301753869108",
			["Diamond"] = "rbxassetid://109770601451203"
		},
		
		AnimationsIds = {
			Idle = "rbxassetid://507766666"
		}
	},
	
	["Common Lucky Block"] = {
		Area = "Common",

		Chance = 0.4,

		Distance = 2.2,
		YOffset = 3.05,

		Level = {Minimum = 1, Maximum = 3},

		Time = 60,

		Index = 1,
		
		LuckyBlock = true,

		Icons = {
			["Default"] = "rbxassetid://132340239905593",
			["Gold"] = "rbxassetid://106315601101573",
			["Diamond"] = "rbxassetid://92331474668057"
		},

		AnimationsIds = {
			Idle = "",
			Roll = ""
		}
	},
	
	["Human"] = {
		Area = "Rare",

		Chance = 0.7,

		Distance = 2,
		YOffset = 3.5,

		Level = {Minimum = 1, Maximum = 2},
		
		Time = 60,

		Index = 2,
		
		Levels = {
			[1] = {
				Money = 2500,
				Sell = 10000
			},

			[2] = {
				Upgrade = 25000,
				Money = 5000,
				Sell = 100000
			}
		},

		Icons = {
			["Default"] = "rbxassetid://136620372890578",
			["Gold"] = "rbxassetid://125682593726314",
			["Diamond"] = "rbxassetid://125850722679793"
		},
		
		AnimationsIds = {
			Idle = "rbxassetid://507766666"
		}
	},
	
	["Rare Lucky Block"] = {
		Area = "Rare",

		Chance = 0.3,

		Distance = 2.2,
		YOffset = 3.05,

		Level = {Minimum = 1, Maximum = 3},

		Time = 60,

		Index = 3,

		LuckyBlock = true,

		Icons = {
			["Default"] = "rbxassetid://132340239905593",
			["Gold"] = "rbxassetid://106315601101573",
			["Diamond"] = "rbxassetid://92331474668057"
		},

		AnimationsIds = {
			Idle = "",
			Roll = ""
		}
	},
	
	["Person"] = {
		Area = "Legendary",

		Chance = 0.8,

		Distance = 2,
		YOffset = 3.5,

		Level = {Minimum = 1, Maximum = 2},
		
		Time = 60,

		Index = 4,
		
		Levels = {
			[1] = {
				Money = 5000,
				Sell = 20000
			},

			[2] = {
				Upgrade = 50000,
				Money = 10000,
				Sell = 200000
			}
		},

		Icons = {
			["Default"] = "rbxassetid://119280591229874",
			["Gold"] = "rbxassetid://114437793440127",
			["Diamond"] = "rbxassetid://103527710225208"
		},
		
		AnimationsIds = {
			Idle = "rbxassetid://180435792"
		}
	},
	
	["Legendary Lucky Block"] = {
		Area = "Legendary",

		Chance = 0.2,

		Distance = 2.2,
		YOffset = 3.05,

		Level = {Minimum = 1, Maximum = 3},

		Time = 60,

		Index = 5,

		LuckyBlock = true,

		Icons = {
			["Default"] = "rbxassetid://132340239905593",
			["Gold"] = "rbxassetid://106315601101573",
			["Diamond"] = "rbxassetid://92331474668057"
		},

		AnimationsIds = {
			Idle = "",
			Roll = ""
		}
	}
}

return ThingsConfigurations

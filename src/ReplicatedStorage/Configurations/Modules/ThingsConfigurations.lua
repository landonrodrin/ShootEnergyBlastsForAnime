local ThingsConfigurations = {
	["Luffy"] = {
		Area = "Common",

		Chance = 0.33,

		Distance = 2,
		YOffset = 3.5,

		Level = {Minimum = 1, Maximum = 1},

		Time = 60,

		Index = 1,

		Levels = {
			[1] = {
				Money = 1200,
				Sell = 4800
			},

			[2] = {
				Upgrade = 12000,
				Money = 2400,
				Sell = 48000
			}
		},

		Icons = {
			["Default"] = "",
			["Gold"] = "",
			["Diamond"] = ""
		},

		AnimationsIds = {
			Idle = "rbxassetid://180435792"
		}
	},

	["Naruto"] = {
		Area = "Common",

		Chance = 0.33,

		Distance = 2,
		YOffset = 3.5,

		Level = {Minimum = 1, Maximum = 1},

		Time = 60,

		Index = 2,

		Levels = {
			[1] = {
				Money = 1350,
				Sell = 5400
			},

			[2] = {
				Upgrade = 13500,
				Money = 2700,
				Sell = 54000
			}
		},

		Icons = {
			["Default"] = "",
			["Gold"] = "",
			["Diamond"] = ""
		},

		AnimationsIds = {
			Idle = "rbxassetid://507766666"
		}
	},

	["Goku"] = {
		Area = "Common",

		Chance = 0.34,

		Distance = 2,
		YOffset = 3.5,

		Level = {Minimum = 1, Maximum = 1},

		Time = 60,

		Index = 3,

		Levels = {
			[1] = {
				Money = 1500,
				Sell = 6000
			},

			[2] = {
				Upgrade = 15000,
				Money = 3000,
				Sell = 60000
			}
		},

		Icons = {
			["Default"] = "",
			["Gold"] = "",
			["Diamond"] = ""
		},

		AnimationsIds = {
			Idle = "rbxassetid://180435792"
		}
	}
}

return ThingsConfigurations

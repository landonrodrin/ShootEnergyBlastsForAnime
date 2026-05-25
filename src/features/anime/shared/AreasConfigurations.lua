local AreasConfigurations = {
	["Common"] = {
		Enabled = true,
		SpawnZonePath = {"Strips", "Strip 1", "Floor"},
		InitialPopulation = 6,
		MaxPopulation = 12,
		SpawnSpacing = 18,
		SpawnJitter = 5,

		Rate = {Minimum = 1, Maximum = 5},
		
		Chance = 0.7,
		
		Colour = Color3.fromRGB(255, 255, 255)
	},
	
	["Rare"] = {
		Enabled = true,
		SpawnZonePath = {"Strips", "Strip 2", "Floor"},
		InitialPopulation = 6,
		MaxPopulation = 12,
		SpawnSpacing = 18,
		SpawnJitter = 5,

		Rate = {Minimum = 5, Maximum = 10},

		Chance = 0.5,

		Colour = Color3.fromRGB(0, 255, 0)
	},
	
	["Legendary"] = {
		Enabled = false,

		Rate = {Minimum = 10, Maximum = 15},

		Chance = 0.3,

		Guaranteed = 60,
		
		Colour = Color3.fromRGB(20, 70, 255)
	}
}

return AreasConfigurations

local AreasConfigurations = {
	["Common"] = {
		Rate = {Minimum = 1, Maximum = 5},
		
		Chance = 0.7,
		
		Colour = Color3.fromRGB(255, 255, 255)
	},
	
	["Rare"] = {
		Rate = {Minimum = 5, Maximum = 10},

		Chance = 0.5,

		Colour = Color3.fromRGB(0, 255, 0)
	},
	
	["Legendary"] = {
		Rate = {Minimum = 10, Maximum = 15},

		Chance = 0.3,

		Guaranteed = 60,
		
		Colour = Color3.fromRGB(20, 70, 255)
	}
}

return AreasConfigurations

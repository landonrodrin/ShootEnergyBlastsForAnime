local MutationsConfigurations = {
	["Default"] = {Chance = 0.5},
	
	["Gold"] = {
		Chance = 0.3,
		
		Colour = Color3.fromRGB(255, 215, 0),
		Gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(242, 242, 78)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 145, 10))}),
			
		Multiplier = 1.5,
		
		Index = 1
	},
	
	["Diamond"] = {
		Chance = 0.2,

		Colour = Color3.fromRGB(20, 70, 255),
		Gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 250, 246)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 105, 252))}),

		Multiplier = 2,
		
		Index = 2
	}
}

return MutationsConfigurations

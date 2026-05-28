local MutationsConfigurations = {
	["Default"] = {Chance = 0.5},
	
	["Gold"] = {
		Chance = 0.3,
		
		Colour = Color3.fromRGB(255, 215, 0),
		Gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(242, 242, 78)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 145, 10))}),
		Aura = {
			Highlight = {
				FillColor = Color3.fromRGB(255, 213, 74),
				FillTransparency = 0.65,
				OutlineColor = Color3.fromRGB(255, 244, 170),
				OutlineTransparency = 0.15
			},
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = ColorSequence.new(Color3.fromRGB(255, 221, 79), Color3.fromRGB(255, 156, 38)),
				LightEmission = 0.8,
				Rate = 28,
				Lifetime = NumberRange.new(1, 1.7),
				Speed = NumberRange.new(0.9, 1.9),
				SpreadAngle = Vector2.new(360, 360),
				Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.28),
					NumberSequenceKeypoint.new(0.5, 0.55),
					NumberSequenceKeypoint.new(1, 0)
				}),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.2),
					NumberSequenceKeypoint.new(0.7, 0.35),
					NumberSequenceKeypoint.new(1, 1)
				})
			},
			Light = {
				Color = Color3.fromRGB(255, 213, 74),
				Brightness = 1,
				Range = 10
			}
		},
			
		Multiplier = 1.5,
		
		Index = 1
	},
	
	["Diamond"] = {
		Chance = 0.2,

		Colour = Color3.fromRGB(75, 221, 255),
		Gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 250, 246)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 105, 252))}),
		Aura = {
			Highlight = {
				FillColor = Color3.fromRGB(75, 221, 255),
				FillTransparency = 0.62,
				OutlineColor = Color3.fromRGB(185, 247, 255),
				OutlineTransparency = 0.1
			},
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = ColorSequence.new(Color3.fromRGB(76, 244, 255), Color3.fromRGB(0, 105, 252)),
				LightEmission = 0.9,
				Rate = 32,
				Lifetime = NumberRange.new(1, 1.8),
				Speed = NumberRange.new(1, 2),
				SpreadAngle = Vector2.new(360, 360),
				Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.24),
					NumberSequenceKeypoint.new(0.5, 0.6),
					NumberSequenceKeypoint.new(1, 0)
				}),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.15),
					NumberSequenceKeypoint.new(0.75, 0.3),
					NumberSequenceKeypoint.new(1, 1)
				})
			},
			Light = {
				Color = Color3.fromRGB(76, 244, 255),
				Brightness = 1.1,
				Range = 11
			}
		},

		Multiplier = 2,
		
		Index = 2
	}
}

return MutationsConfigurations

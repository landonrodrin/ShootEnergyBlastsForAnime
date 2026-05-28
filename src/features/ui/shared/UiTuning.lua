local REFERENCE_RESOLUTION = Vector2.new(1920, 1080)

local UiTuning = {
	TextOutline = {
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 2,
		Transparency = 0,
	},

	HudRails = {
		DebugHudRails = false,
		ReferenceResolution = REFERENCE_RESOLUTION,
		Left = {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 50, 0.5, 0),
		},
		Right = {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -115, 0.5, 0),
		},
	},

	LeftRail = {
		IconSize = 60,
		RowHeight = 50,
		RowWidth = 200,
		TextWidth = 260,
		TextSize = 30,
		RowSpacing = 25,
	},

	RightRail = {
		IconSize = 140,
		ItemWidth = 140,
		ItemHeight = 140,
		RowSpacing = 185,
		LabelOffset = 120,
		LabelTextSize = 45,
		LabelWidth = 150,
		LabelHeight = 36,
	},

	Announcements = {
		MessageWidth = 560,
		MessageHeight = 64,
		MaxTextSize = 24,
		MessagePadding = 8,
	},

	AnimeUnlock = {
		CardWidth = 520,
		CardHeight = 116,
		PreviewSize = 88,
		PreviewScale = 1.3,
	},

	GameplayPanels = {
		DebugGameplayPanel = true,
		ReferenceResolution = REFERENCE_RESOLUTION,
		OpenOffset = UDim2.fromOffset(0, 120),
		OpenTweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		CloseTweenInfo = TweenInfo.new(0.01, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		Outer = {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.485),
			Size = UDim2.fromScale(0.615, 0.64),
			BackgroundColor3 = Color3.fromRGB(20, 22, 30),
			BackgroundTransparency = 0.08,
			CornerRadius = UDim.new(0, 8),
			StrokeThickness = 3,
			StrokeTransparency = 0.15,
		},
		Header = {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(1181, 61),
			TitlePosition = UDim2.fromOffset(41, 30),
			TitleSize = UDim2.fromOffset(768, 42),
			ClosePosition = UDim2.fromOffset(1145, 30),
			CloseSize = UDim2.fromOffset(54, 42),
			CloseText = "X",
			CloseMaxTextSize = 28,
			TitleMaxTextSize = 34,
		},
		EmptyState = {
			Position = UDim2.fromOffset(590, 378),
			Size = UDim2.fromOffset(1004, 176),
			MaxTextSize = 34,
		},

		Shop = {
			Title = "Shop",
			StrokeColor = Color3.fromRGB(255, 190, 46),
			EmptyText = "Coming Soon",
		},

		Index = {
			TitleFormat = "Index | %s",
			StrokeColor = Color3.fromRGB(110, 116, 255),
			Mutations = {
				Position = UDim2.fromOffset(21, 86),
				Size = UDim2.fromOffset(180, 620),
				ButtonSize = UDim2.fromOffset(170, 54),
				ButtonMaxTextSize = 22,
				Padding = UDim.new(0, 10),
				FillDirection = Enum.FillDirection.Vertical,
			},
			Anime = {
				Position = UDim2.fromOffset(220, 86),
				Size = UDim2.fromOffset(939, 600),
				ScrollBarThickness = 8,
				CellSize = UDim2.fromOffset(177, 187),
				CellPadding = UDim2.fromOffset(18, 18),
				PaddingTop = UDim.new(0, 20),
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
				CardSize = UDim2.fromOffset(177, 187),
				RarityPosition = UDim2.fromOffset(14, 8),
				RaritySize = UDim2.fromOffset(149, 26),
				RarityMaxTextSize = 30,
				PreviewPosition = UDim2.fromOffset(30, 39),
				PreviewSize = UDim2.fromOffset(118, 97),
				PreviewScale = 1.3,
				NamePosition = UDim2.fromOffset(14, 141),
				NameSize = UDim2.fromOffset(149, 36),
			},
		},

		Sell = {
			Title = "Sell Anime",
			StrokeColor = Color3.fromRGB(71, 210, 113),
			EmptyText = "No anime to sell.",
			List = {
				Position = UDim2.fromOffset(21, 80),
				Size = UDim2.fromOffset(1138, 556),
				ScrollBarThickness = 8,
				Padding = UDim.new(0, 8),
				RowSize = UDim2.fromOffset(1129, 101),
				PreviewPosition = UDim2.fromOffset(14, 13),
				PreviewSize = UDim2.fromOffset(85, 76),
				PreviewScale = 1.25,
				NamePosition = UDim2.fromOffset(116, 36),
				NameSize = UDim2.fromOffset(496, 36),
				MutationPosition = UDim2.fromOffset(116, 67),
				MutationSize = UDim2.fromOffset(496, 27),
				SellButtonPosition = UDim2.fromOffset(1112, 50),
				SellButtonSize = UDim2.fromOffset(177, 46),
				SellButtonMaxTextSize = 24,
			},
			SellAll = {
				Position = UDim2.fromOffset(590, 709),
				Size = UDim2.fromOffset(307, 50),
			},
			Confirm = {
				Size = UDim2.fromOffset(496, 189),
				MessagePosition = UDim2.fromOffset(28, 21),
				MessageSize = UDim2.fromOffset(439, 76),
				CancelPosition = UDim2.fromOffset(52, 118),
				CancelSize = UDim2.fromOffset(177, 46),
				ConfirmPosition = UDim2.fromOffset(267, 118),
				ConfirmSize = UDim2.fromOffset(177, 46),
			},
		},

		Rebirth = {
			Title = "Rebirth",
			StrokeColor = Color3.fromRGB(235, 77, 112),
			CurrentPosition = UDim2.fromOffset(35, 92),
			CurrentSize = UDim2.fromOffset(1110, 55),
			NextPosition = UDim2.fromOffset(35, 153),
			NextSize = UDim2.fromOffset(1110, 55),
			ProgressPosition = UDim2.fromOffset(47, 231),
			ProgressSize = UDim2.fromOffset(1086, 44),
			ProgressLabelPosition = UDim2.fromOffset(543, 22),
			ProgressLabelSize = UDim2.fromOffset(1032, 33),
			RebirthButtonPosition = UDim2.fromOffset(390, 329),
			RebirthButtonSize = UDim2.fromOffset(201, 57),
			SkipButtonPosition = UDim2.fromOffset(633, 329),
			SkipButtonSize = UDim2.fromOffset(201, 57),
		},

		Upgrades = {
			Title = "Upgrades",
			StrokeColor = Color3.fromRGB(255, 190, 46),
			List = {
				Position = UDim2.fromOffset(21, 80),
				Size = UDim2.fromOffset(1138, 636),
				Padding = UDim.new(0, 10),
				RowSize = UDim2.fromOffset(1129, 101),
				TitlePosition = UDim2.fromOffset(21, 31),
				TitleSize = UDim2.fromOffset(385, 34),
				ValuePosition = UDim2.fromOffset(21, 67),
				ValueSize = UDim2.fromOffset(385, 27),
				MoneyButtonPosition = UDim2.fromOffset(916, 50),
				MoneyButtonSize = UDim2.fromOffset(168, 46),
				RobuxButtonPosition = UDim2.fromOffset(1101, 50),
				RobuxButtonSize = UDim2.fromOffset(168, 46),
				ButtonMaxTextSize = 22,
			},
		},
	},
}

return UiTuning

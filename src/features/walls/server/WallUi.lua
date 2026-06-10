local WallUi = {}

local function warnAndRepairWallUi(wall, missingName)
	warn(string.format("Missing %s on %s; repairing wall HP UI.", missingName, wall:GetFullName()))
end

local function getHpBarColor(hpPercent)
	if hpPercent > 0.5 then
		return Color3.fromRGB(255, 220, 0):Lerp(Color3.fromRGB(0, 220, 80), (hpPercent - 0.5) * 2)
	end

	return Color3.fromRGB(220, 35, 35):Lerp(Color3.fromRGB(255, 220, 0), hpPercent * 2)
end

local function ensureHpLabel(state)
	local cached = state.hpUi
	if cached and cached.label and cached.label.Parent and cached.barFill and cached.barFill.Parent then
		return cached.label, cached.barFill
	end

	local wall = state.wall
	local gui = wall:FindFirstChild("WallHPText")
	if not gui then
		warnAndRepairWallUi(wall, "WallHPText")
		gui = Instance.new("SurfaceGui")
		gui.Name = "WallHPText"
		gui.Face = Enum.NormalId.Back
		gui.AlwaysOnTop = false
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.Parent = wall
	end

	gui.Enabled = true
	gui.Parent = wall

	local label = gui:FindFirstChild("HPLabel")
	if not label then
		warnAndRepairWallUi(wall, "HPLabel")
		label = Instance.new("TextLabel")
		label.Name = "HPLabel"
		label.Parent = gui

		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.Position = UDim2.fromScale(0.5, 0.27)
		label.Size = UDim2.fromScale(0.9, 0.26)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0
	end

	local barBackground = gui:FindFirstChild("HPBarBackground")
	if not barBackground then
		warnAndRepairWallUi(wall, "HPBarBackground")
		barBackground = Instance.new("Frame")
		barBackground.Name = "HPBarBackground"
		barBackground.AnchorPoint = Vector2.new(0.5, 0.5)
		barBackground.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		barBackground.BackgroundTransparency = 0.2
		barBackground.BorderSizePixel = 0
		barBackground.Position = UDim2.fromScale(0.5, 0.78)
		barBackground.Size = UDim2.fromScale(0.7, 0.09)
		barBackground.Parent = gui
	end

	local barFill = barBackground:FindFirstChild("HPBarFill")
	if not barFill then
		warnAndRepairWallUi(wall, "HPBarFill")
		barFill = Instance.new("Frame")
		barFill.Name = "HPBarFill"
		barFill.AnchorPoint = Vector2.new(0, 0.5)
		barFill.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
		barFill.BorderSizePixel = 0
		barFill.Position = UDim2.fromScale(0, 0.5)
		barFill.Size = UDim2.fromScale(1, 1)
		barFill.Parent = barBackground
	end

	state.hpUi = {
		gui = gui,
		label = label,
		barFill = barFill,
	}

	return label, barFill
end

function WallUi.SetEnabled(state, enabled)
	local cached = state.hpUi
	local gui = cached and cached.gui or state.wall:FindFirstChild("WallHPText")
	if gui then
		gui.Enabled = enabled
	end
end

function WallUi.UpdateHpLabel(state)
	local hpPercent = math.clamp(state.hp / state.maxHP, 0, 1)
	local hpText = string.format("%d/%d", state.hp, state.maxHP)

	if state.lastRenderedHpText == hpText and state.lastRenderedHpPercent == hpPercent then
		return
	end

	local label, barFill = ensureHpLabel(state)
	label.Text = hpText
	barFill.Size = UDim2.fromScale(hpPercent, 1)
	barFill.BackgroundColor3 = getHpBarColor(hpPercent)

	state.lastRenderedHpText = hpText
	state.lastRenderedHpPercent = hpPercent
end

return WallUi

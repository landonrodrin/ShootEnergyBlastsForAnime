local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AnimeConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AnimeConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))

local GenerateAnimeViewports = {}

local OUTPUT_FOLDER_NAME = "AnimeViewports"
local DEFAULT_MUTATION = "Default"
local VIEWPORT_SIZE = UDim2.fromScale(1, 1)
local VIEWPORT_AMBIENT = Color3.fromRGB(185, 185, 185)
local VIEWPORT_LIGHT_COLOR = Color3.fromRGB(255, 255, 255)
local VIEWPORT_LIGHT_DIRECTION = Vector3.new(-0.35, -0.8, -0.45)
local VIEWPORT_FIELD_OF_VIEW = 32
local VIEWPORT_FILL_RATIO = 0.72
local VIEWPORT_CAMERA_DIRECTION = -1
local VIEWPORT_YAW_DEGREES = 180
local VIEWPORT_TARGET_Y_OFFSET = 0.08
local VIEWPORT_BOUNDS_MODE = "Hybrid"
local VIEWPORT_BODY_BOUNDS_PADDING = 1.18
local VIEWPORT_HYBRID_WIDTH_SCALE = 1.35
local VIEWPORT_HYBRID_HEIGHT_SCALE = 1.75
local VIEWPORT_HYBRID_DEPTH_SCALE = 1.35
local VIEWPORT_HYBRID_CENTER_SHIFT_SCALE = 0.2
local VIEWPORT_NORMALIZE_CAMERA_SIZE = true
local SUPPORTED_OPTIONS = {
	Anime = true,
	Animes = true,
	ClearUnselected = true,
	Mutation = true,
	Mutations = true,
}
local BODY_BOUND_PARTS = {
	Head = true,
	HumanoidRootPart = true,
	LeftFoot = true,
	["Left Arm"] = true,
	["Left Leg"] = true,
	LeftHand = true,
	LeftLowerArm = true,
	LeftLowerLeg = true,
	LeftUpperArm = true,
	LeftUpperLeg = true,
	LowerTorso = true,
	RightFoot = true,
	["Right Arm"] = true,
	["Right Leg"] = true,
	RightHand = true,
	RightLowerArm = true,
	RightLowerLeg = true,
	RightUpperArm = true,
	RightUpperLeg = true,
	Torso = true,
	UpperTorso = true,
}

local function addFilterValues(Lookup, Values)
	if Values == nil then return end

	if type(Values) == "string" then
		Lookup[Values] = true
	elseif type(Values) == "table" then
		for _, Value in ipairs(Values) do
			if type(Value) == "string" then
				Lookup[Value] = true
			end
		end
	end
end

local function normalizeFilterList(...)
	local Lookup = {}
	local HasValues = false

	for _, Values in ipairs({...}) do
		if Values ~= nil then
			HasValues = true
			addFilterValues(Lookup, Values)
		end
	end

	if not HasValues then return nil end

	return Lookup
end

local function getSortedKeys(Dictionary)
	local Keys = {}
	for Key in pairs(Dictionary) do
		table.insert(Keys, Key)
	end
	table.sort(Keys)
	return Keys
end

local function getOrCreateFolder(Parent, Name)
	local Folder = Parent:FindFirstChild(Name)
	if Folder then return Folder end

	Folder = Instance.new("Folder")
	Folder.Name = Name
	Folder.Parent = Parent

	return Folder
end

local function formatSelection(Filter, AllLabel)
	if not Filter then return AllLabel end

	local Values = getSortedKeys(Filter)
	if #Values == 0 then return "none" end

	return table.concat(Values, ", ")
end

local function warnUnsupportedOptions(Options, Missing)
	for OptionName in pairs(Options) do
		if not SUPPORTED_OPTIONS[OptionName] then
			table.insert(Missing, string.format("unsupported option %q", OptionName))
		end
	end
end

local function findAnimeTemplate(Name, Mutation)
	local Animes = ServerStorage:FindFirstChild("Animes")
	if not Animes then return nil, nil end

	local AnimeConfiguration = AnimeConfigurations[Name]
	local Area = AnimeConfiguration and AnimeConfiguration.Area

	local function findInMutation(MutationName)
		local MutationFolder = Animes:FindFirstChild(MutationName)
		local AreaFolder = Area and MutationFolder and MutationFolder:FindFirstChild(Area)
		local Template = AreaFolder and AreaFolder:FindFirstChild(Name)
		if Template then return Template end

		return MutationFolder and MutationFolder:FindFirstChild(Name)
	end

	local MutationTemplate = findInMutation(Mutation)
	if MutationTemplate then
		return MutationTemplate, Mutation
	end

	local DefaultTemplate = findInMutation(DEFAULT_MUTATION)
	if DefaultTemplate then
		return DefaultTemplate, DEFAULT_MUTATION
	end

	return nil, nil
end

local function removeScripts(Model)
	for _, Descendant in ipairs(Model:GetDescendants()) do
		if Descendant:IsA("Script") or Descendant:IsA("LocalScript") then
			Descendant:Destroy()
		end
	end
end

local function prepareVisualModel(Model)
	removeScripts(Model)

	for _, Descendant in ipairs(Model:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			Descendant.Anchored = true
			Descendant.CanCollide = false
			Descendant.CanTouch = false
			Descendant.CanQuery = false
		end
	end
end

local function applyMutationAura(Model, Mutation)
	local MutationConfiguration = MutationsConfigurations[Mutation]
	if not MutationConfiguration or Mutation == DEFAULT_MUTATION then return end

	local AuraConfiguration = MutationConfiguration.Aura
	local HighlightConfiguration = AuraConfiguration and AuraConfiguration.Highlight

	if HighlightConfiguration then
		local Highlight = Instance.new("Highlight")
		Highlight.Name = "ViewportMutationHighlight"
		Highlight.Adornee = Model
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = HighlightConfiguration.FillColor or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Highlight.FillTransparency = HighlightConfiguration.FillTransparency or 0.65
		Highlight.OutlineColor = HighlightConfiguration.OutlineColor or Highlight.FillColor
		Highlight.OutlineTransparency = HighlightConfiguration.OutlineTransparency or 0.15
		Highlight.Parent = Model
	end

	local LightConfiguration = AuraConfiguration and AuraConfiguration.Light
	local LightPart = Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart", true)
	if LightConfiguration and LightPart then
		local Light = Instance.new("PointLight")
		Light.Name = "ViewportMutationAuraLight"
		Light.Color = LightConfiguration.Color or MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)
		Light.Brightness = LightConfiguration.Brightness or 0.6
		Light.Range = LightConfiguration.Range or 8
		Light.Parent = LightPart
	end
end

local function shouldUsePartForBounds(Part)
	if Part.Transparency >= 0.95 then
		return false
	end

	return true
end

local function getBounds(Model, ShouldUsePart, AllowFallback)
	local Min
	local Max

	for _, Descendant in ipairs(Model:GetDescendants()) do
		if not Descendant:IsA("BasePart") or not ShouldUsePart(Descendant) then continue end

		local HalfSize = Descendant.Size / 2
		for X = -1, 1, 2 do
			for Y = -1, 1, 2 do
				for Z = -1, 1, 2 do
					local Corner = Descendant.CFrame:PointToWorldSpace(Vector3.new(
						HalfSize.X * X,
						HalfSize.Y * Y,
						HalfSize.Z * Z
					))

					if Min then
						Min = Vector3.new(
							math.min(Min.X, Corner.X),
							math.min(Min.Y, Corner.Y),
							math.min(Min.Z, Corner.Z)
						)
						Max = Vector3.new(
							math.max(Max.X, Corner.X),
							math.max(Max.Y, Corner.Y),
							math.max(Max.Z, Corner.Z)
						)
					else
						Min = Corner
						Max = Corner
					end
				end
			end
		end
	end

	if not Min or not Max then
		if AllowFallback == false then
			return nil, nil
		end

		local BoundingCFrame, Size = Model:GetBoundingBox()
		return BoundingCFrame.Position, Size
	end

	return (Min + Max) / 2, Max - Min
end

local function getNumber(Value, Default)
	local Number = tonumber(Value)
	if Number == nil then
		return Default
	end

	return Number
end

local function getBoundsMode(Value)
	if Value == "Body" or Value == "Visual" or Value == "Hybrid" then
		return Value
	end

	return VIEWPORT_BOUNDS_MODE
end

local function vectorMin(First, Second)
	return Vector3.new(
		math.min(First.X, Second.X),
		math.min(First.Y, Second.Y),
		math.min(First.Z, Second.Z)
	)
end

local function vectorMax(First, Second)
	return Vector3.new(
		math.max(First.X, Second.X),
		math.max(First.Y, Second.Y),
		math.max(First.Z, Second.Z)
	)
end

local function vectorClamp(Value, Min, Max)
	return Vector3.new(
		math.clamp(Value.X, Min.X, Max.X),
		math.clamp(Value.Y, Min.Y, Max.Y),
		math.clamp(Value.Z, Min.Z, Max.Z)
	)
end

local function getExtents(Center, Size)
	local HalfSize = Size / 2
	return Center - HalfSize, Center + HalfSize
end

local function getVisualBounds(Model)
	return getBounds(Model, shouldUsePartForBounds, true)
end

local function shouldUsePartForBodyBounds(Part)
	if not shouldUsePartForBounds(Part) then
		return false
	end

	return BODY_BOUND_PARTS[Part.Name] == true
end

local function getBodyBounds(Model)
	return getBounds(Model, shouldUsePartForBodyBounds, false)
end

local function getHybridBounds(VisualCenter, VisualSize, BodyCenter, BodySize, AnimeConfiguration)
	local Padding = math.max(getNumber(AnimeConfiguration.ViewportBodyBoundsPadding, VIEWPORT_BODY_BOUNDS_PADDING), 1)
	local BodyPaddedSize = BodySize * Padding
	local BodyMin, BodyMax = getExtents(BodyCenter, BodyPaddedSize)
	local VisualMin, VisualMax = getExtents(VisualCenter, VisualSize)
	local CombinedMin = vectorMin(BodyMin, VisualMin)
	local CombinedMax = vectorMax(BodyMax, VisualMax)
	local CombinedCenter = (CombinedMin + CombinedMax) / 2
	local CombinedSize = CombinedMax - CombinedMin
	local WidthScale = math.max(getNumber(AnimeConfiguration.ViewportHybridWidthScale, VIEWPORT_HYBRID_WIDTH_SCALE), Padding)
	local HeightScale = math.max(getNumber(AnimeConfiguration.ViewportHybridHeightScale, VIEWPORT_HYBRID_HEIGHT_SCALE), Padding)
	local DepthScale = math.max(getNumber(AnimeConfiguration.ViewportHybridDepthScale, VIEWPORT_HYBRID_DEPTH_SCALE), Padding)
	local CenterShiftScale = math.max(getNumber(
		AnimeConfiguration.ViewportHybridCenterShiftScale,
		VIEWPORT_HYBRID_CENTER_SHIFT_SCALE
	), 0)
	local MaxSize = vectorMax(BodyPaddedSize, Vector3.new(
		BodySize.X * WidthScale,
		BodySize.Y * HeightScale,
		BodySize.Z * DepthScale
	))
	local HybridSize = vectorMin(vectorMax(CombinedSize, BodyPaddedSize), MaxSize)
	local MaxCenterShift = BodySize * CenterShiftScale
	local CenterOffset = vectorClamp(CombinedCenter - BodyCenter, -MaxCenterShift, MaxCenterShift)

	return BodyCenter + CenterOffset, HybridSize
end

local function getCameraBounds(Model, AnimeConfiguration)
	local VisualCenter, VisualSize = getVisualBounds(Model)
	local BodyCenter, BodySize = getBodyBounds(Model)
	local BoundsMode = getBoundsMode(AnimeConfiguration.ViewportBoundsMode)

	if BoundsMode == "Visual" or not BodyCenter or not BodySize then
		return VisualCenter, VisualSize, "Visual", BodySize, VisualSize
	end

	local Padding = math.max(tonumber(AnimeConfiguration.ViewportBodyBoundsPadding) or VIEWPORT_BODY_BOUNDS_PADDING, 1)
	if BoundsMode == "Body" then
		local CameraSize = BodySize * Padding
		return BodyCenter, CameraSize, "Body", BodySize, VisualSize
	end

	local HybridCenter, HybridSize = getHybridBounds(VisualCenter, VisualSize, BodyCenter, BodySize, AnimeConfiguration)
	return HybridCenter, HybridSize, "Hybrid", BodySize, VisualSize
end

local function shouldNormalizeCameraSize(AnimeConfiguration)
	if AnimeConfiguration.ViewportNormalizeSize == nil then
		return VIEWPORT_NORMALIZE_CAMERA_SIZE
	end

	return AnimeConfiguration.ViewportNormalizeSize == true
end

local function getNormalizedCameraSize(Size, ReferenceCameraSize, AnimeConfiguration)
	if not ReferenceCameraSize or not shouldNormalizeCameraSize(AnimeConfiguration) then
		return Size
	end

	return vectorMax(Size, ReferenceCameraSize)
end

local function setCamera(Viewport, Model, AnimeConfiguration, ReferenceCameraSize)
	AnimeConfiguration = AnimeConfiguration or {}

	local Camera = Instance.new("Camera")
	Camera.Name = "PreviewCamera"
	Camera.FieldOfView = VIEWPORT_FIELD_OF_VIEW
	Camera.Parent = Viewport
	Viewport.CurrentCamera = Camera

	local Center, RawCameraSize, BoundsMode, BodySize, VisualSize = getCameraBounds(Model, AnimeConfiguration)
	local Size = getNormalizedCameraSize(RawCameraSize, ReferenceCameraSize, AnimeConfiguration)
	local FieldOfView = math.rad(Camera.FieldOfView)
	local Zoom = math.max(getNumber(AnimeConfiguration.ViewportZoom, 1), 0.1)
	local FillRatio = math.clamp(VIEWPORT_FILL_RATIO * Zoom, 0.1, 0.95)
	local HeightDistance = (math.max(Size.Y, 1) / 2) / math.tan(FieldOfView / 2)
	local WidthDistance = (math.max(Size.X, 1) / 2) / math.tan(FieldOfView / 2)
	local Distance = math.max(HeightDistance, WidthDistance) / FillRatio + (Size.Z * 0.5)
	local Direction = getNumber(AnimeConfiguration.ViewportCameraDirection, VIEWPORT_CAMERA_DIRECTION)
	Direction = Direction >= 0 and 1 or -1
	local FallbackYawDegrees = Direction >= 0 and 0 or VIEWPORT_YAW_DEGREES
	local YawDegrees = getNumber(AnimeConfiguration.ViewportYawDegrees, FallbackYawDegrees)
	local YawRadians = math.rad(YawDegrees)
	local TargetYOffset = VIEWPORT_TARGET_Y_OFFSET + getNumber(AnimeConfiguration.ViewportYOffset, 0)
	local Target = Center + Vector3.new(0, Size.Y * TargetYOffset, 0)
	local CameraOffset = Vector3.new(
		math.sin(YawRadians) * Distance,
		Size.Y * 0.04,
		math.cos(YawRadians) * Distance
	)

	Camera.CFrame = CFrame.new(Target + CameraOffset, Target)

	return YawDegrees, BoundsMode, BodySize, VisualSize, Size, RawCameraSize
end

local function getTemplateCameraSize(Name)
	local Template = findAnimeTemplate(Name, DEFAULT_MUTATION)
	if not Template then return nil end

	local AnimeConfiguration = AnimeConfigurations[Name]
	local Model = Template:Clone()
	Model.Name = Name
	prepareVisualModel(Model)

	local _, Size = getCameraBounds(Model, AnimeConfiguration)
	Model:Destroy()

	return Size
end

local function getReferenceCameraSize()
	local ReferenceSize

	for _, Name in ipairs(getSortedKeys(AnimeConfigurations)) do
		local Size = getTemplateCameraSize(Name)
		if Size then
			ReferenceSize = ReferenceSize and vectorMax(ReferenceSize, Size) or Size
		end
	end

	return ReferenceSize
end

local function createViewport(Name, Mutation, Template, ShouldApplyAura, ReferenceCameraSize)
	local AnimeConfiguration = AnimeConfigurations[Name]
	local Viewport = Instance.new("ViewportFrame")
	Viewport.Name = Name
	Viewport.Size = VIEWPORT_SIZE
	Viewport.BackgroundTransparency = 1
	Viewport.Ambient = VIEWPORT_AMBIENT
	Viewport.LightColor = VIEWPORT_LIGHT_COLOR
	Viewport.LightDirection = VIEWPORT_LIGHT_DIRECTION

	local World = Instance.new("WorldModel")
	World.Name = "World"
	World.Parent = Viewport

	local Model = Template:Clone()
	Model.Name = Name
	prepareVisualModel(Model)

	if ShouldApplyAura then
		applyMutationAura(Model, Mutation)
	end

	Model.Parent = World
	local YawDegrees, BoundsMode, BodySize, VisualSize, CameraSize, RawCameraSize = setCamera(
		Viewport,
		Model,
		AnimeConfiguration,
		ReferenceCameraSize
	)

	Viewport:SetAttribute("GeneratedAnime", Name)
	Viewport:SetAttribute("GeneratedMutation", Mutation)
	Viewport:SetAttribute("GeneratedYawDegrees", YawDegrees)
	Viewport:SetAttribute("GeneratedBoundsMode", BoundsMode)
	Viewport:SetAttribute("GeneratedBodySize", BodySize)
	Viewport:SetAttribute("GeneratedVisualSize", VisualSize)
	Viewport:SetAttribute("GeneratedCameraSize", CameraSize)
	Viewport:SetAttribute("GeneratedRawCameraSize", RawCameraSize)
	Viewport:SetAttribute("GeneratedReferenceCameraSize", ReferenceCameraSize)
	Viewport:SetAttribute("GeneratedAt", os.time())

	return Viewport
end

function GenerateAnimeViewports.Run(Options)
	assert(RunService:IsStudio(), "GenerateAnimeViewports can only be run in Roblox Studio.")

	Options = Options or {}
	local AnimeFilter = normalizeFilterList(Options.Anime, Options.Animes)
	local MutationFilter = normalizeFilterList(Options.Mutation, Options.Mutations)
	local IsFiltered = AnimeFilter ~= nil or MutationFilter ~= nil
	local RunMode = IsFiltered and "filtered" or "full"

	local Missing = {}
	warnUnsupportedOptions(Options, Missing)

	if AnimeFilter then
		for Name in pairs(AnimeFilter) do
			if not AnimeConfigurations[Name] then
				table.insert(Missing, string.format("unknown anime %q", Name))
			end
		end
	end

	if MutationFilter then
		for Mutation in pairs(MutationFilter) do
			if not MutationsConfigurations[Mutation] then
				table.insert(Missing, string.format("unknown mutation %q", Mutation))
			end
		end
	end

	local Existing = ReplicatedStorage:FindFirstChild(OUTPUT_FOLDER_NAME)
	if Existing and not IsFiltered then
		Existing:Destroy()
		Existing = nil
	end

	local OutputFolder = Existing
	if not OutputFolder then
		OutputFolder = Instance.new("Folder")
		OutputFolder.Name = OUTPUT_FOLDER_NAME
		OutputFolder.Parent = ReplicatedStorage
	end

	local Generated = 0
	local ReplacedPaths = {}
	local ReferenceCameraSize = getReferenceCameraSize()

	for _, Mutation in ipairs(getSortedKeys(MutationsConfigurations)) do
		if MutationFilter and not MutationFilter[Mutation] then continue end

		local MutationFolder = getOrCreateFolder(OutputFolder, Mutation)

		if IsFiltered and Options.ClearUnselected == true then
			for _, ExistingViewport in ipairs(MutationFolder:GetChildren()) do
				if not ExistingViewport:IsA("ViewportFrame") then continue end
				if AnimeFilter and not AnimeFilter[ExistingViewport.Name] then
					ExistingViewport:Destroy()
				end
			end
		end

		for _, Name in ipairs(getSortedKeys(AnimeConfigurations)) do
			if AnimeFilter and not AnimeFilter[Name] then continue end

			local Template, TemplateMutation = findAnimeTemplate(Name, Mutation)
			if not Template then
				table.insert(Missing, string.format("missing source for %s (%s)", Name, Mutation))
				continue
			end

			local ShouldApplyAura = Mutation ~= DEFAULT_MUTATION and TemplateMutation == DEFAULT_MUTATION
			local Viewport = createViewport(Name, Mutation, Template, ShouldApplyAura, ReferenceCameraSize)
			local ExistingViewport = MutationFolder:FindFirstChild(Name)
			if ExistingViewport then
				ExistingViewport:Destroy()
			end
			Viewport:SetAttribute("GeneratedRunMode", RunMode)
			Viewport.Parent = MutationFolder
			Generated += 1
			table.insert(ReplacedPaths, string.format("%s/%s", Mutation, Name))
		end
	end

	if #Missing > 0 then
		warn(string.format("Anime viewport generation skipped %d item(s): %s", #Missing, table.concat(Missing, "; ")))
	end

	print(string.format(
		"Generated %d anime viewport preview(s) in ReplicatedStorage.%s (%s; anime: %s; mutations: %s)",
		Generated,
		OUTPUT_FOLDER_NAME,
		RunMode,
		formatSelection(AnimeFilter, "all"),
		formatSelection(MutationFilter, "all")
	))

	if IsFiltered and Options.ClearUnselected ~= true then
		print("Preserved existing unselected viewports.")
	end

	if #ReplacedPaths > 0 then
		print(string.format("Replaced viewport(s): %s", table.concat(ReplacedPaths, ", ")))
	end

	return OutputFolder
end

return GenerateAnimeViewports

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))

local GenerateAnimeViewports = {}

local OUTPUT_FOLDER_NAME = "AnimeViewports"
local DEFAULT_MUTATION = "Default"
local VIEWPORT_SIZE = UDim2.new(1, 0, 1, 0)
local VIEWPORT_AMBIENT = Color3.fromRGB(185, 185, 185)
local VIEWPORT_LIGHT_COLOR = Color3.fromRGB(255, 255, 255)
local VIEWPORT_LIGHT_DIRECTION = Vector3.new(-0.35, -0.8, -0.45)

local function findAnimeTemplate(Name, Mutation)
	local Animes = ServerStorage:FindFirstChild("Animes")
	if not Animes then return nil, nil end

	local ThingConfiguration = ThingsConfigurations[Name]
	local Area = ThingConfiguration and ThingConfiguration.Area

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

local function getAuraParts(Model)
	local AuraParts = {}

	for _, Descendant in ipairs(Model:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end
		if Descendant.Transparency >= 0.95 then continue end

		local LowerName = string.lower(Descendant.Name)
		if string.find(LowerName, "head") or string.find(LowerName, "torso") or string.find(LowerName, "humanoidrootpart") then
			table.insert(AuraParts, Descendant)
		end
	end

	if #AuraParts == 0 then
		for _, Descendant in ipairs(Model:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end
			if Descendant.Transparency >= 0.95 then continue end

			table.insert(AuraParts, Descendant)
			if #AuraParts >= 6 then break end
		end
	end

	if #AuraParts == 0 and Model.PrimaryPart then
		table.insert(AuraParts, Model.PrimaryPart)
	end

	return AuraParts
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

	local ParticleConfiguration = AuraConfiguration and AuraConfiguration.Particle
	if ParticleConfiguration then
		for _, AuraPart in ipairs(getAuraParts(Model)) do
			local AuraAttachment = Instance.new("Attachment")
			AuraAttachment.Name = "ViewportMutationAuraAttachment"
			AuraAttachment.Parent = AuraPart

			local Particle = Instance.new("ParticleEmitter")
			Particle.Name = "ViewportMutationAura"
			Particle.Texture = ParticleConfiguration.Texture or "rbxasset://textures/particles/sparkles_main.dds"
			Particle.Color = ParticleConfiguration.Color or ColorSequence.new(MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255))
			Particle.LightEmission = ParticleConfiguration.LightEmission or 0.75
			Particle.LightInfluence = ParticleConfiguration.LightInfluence or 0
			Particle.Rate = ParticleConfiguration.Rate or 12
			Particle.Lifetime = ParticleConfiguration.Lifetime or NumberRange.new(0.8, 1.3)
			Particle.Speed = ParticleConfiguration.Speed or NumberRange.new(0.5, 1.2)
			Particle.SpreadAngle = ParticleConfiguration.SpreadAngle or Vector2.new(360, 360)
			Particle.Size = ParticleConfiguration.Size or NumberSequence.new(0.25)
			Particle.Transparency = ParticleConfiguration.Transparency or NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.25),
				NumberSequenceKeypoint.new(1, 1)
			})
			Particle.Parent = AuraAttachment
		end
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

local function setCamera(Viewport, Model)
	local Camera = Instance.new("Camera")
	Camera.Name = "PreviewCamera"
	Camera.FieldOfView = 35
	Camera.Parent = Viewport
	Viewport.CurrentCamera = Camera

	local BoundingCFrame, Size = Model:GetBoundingBox()
	local MaxSize = math.max(Size.X, Size.Y, Size.Z, 1)
	local Center = BoundingCFrame.Position
	local CameraOffset = Vector3.new(0, Size.Y * 0.12, MaxSize * 2.35)

	Camera.CFrame = CFrame.new(Center + CameraOffset, Center)
end

local function createViewport(Name, Mutation, Template, ShouldApplyAura)
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
	setCamera(Viewport, Model)

	return Viewport
end

function GenerateAnimeViewports.Run()
	assert(RunService:IsStudio(), "GenerateAnimeViewports can only be run in Roblox Studio.")

	local Existing = ReplicatedStorage:FindFirstChild(OUTPUT_FOLDER_NAME)
	if Existing then
		Existing:Destroy()
	end

	local OutputFolder = Instance.new("Folder")
	OutputFolder.Name = OUTPUT_FOLDER_NAME
	OutputFolder.Parent = ReplicatedStorage

	local Generated = 0

	for Mutation in pairs(MutationsConfigurations) do
		local MutationFolder = Instance.new("Folder")
		MutationFolder.Name = Mutation
		MutationFolder.Parent = OutputFolder

		for Name in pairs(ThingsConfigurations) do
			local Template, TemplateMutation = findAnimeTemplate(Name, Mutation)
			if not Template then
				warn(string.format("No anime template found for %s (%s)", Name, Mutation))
				continue
			end

			local ShouldApplyAura = Mutation ~= DEFAULT_MUTATION and TemplateMutation == DEFAULT_MUTATION
			local Viewport = createViewport(Name, Mutation, Template, ShouldApplyAura)
			Viewport.Parent = MutationFolder
			Generated += 1
		end
	end

	print(string.format("Generated %d anime viewport previews in ReplicatedStorage.%s", Generated, OUTPUT_FOLDER_NAME))

	return OutputFolder
end

return GenerateAnimeViewports

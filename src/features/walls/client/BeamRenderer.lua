local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local WallConfig = require(ReplicatedStorage.Features.Walls.Shared:WaitForChild("WallConfig"))

local BeamRenderer = {}

local activeBeam = nil
local beamTrove = nil
local renderConnected = false
local renderOptions = nil
local lastRenderUpdateAt = 0
local lastOrigin = nil
local lastTargetPoint = nil
local POSITION_EPSILON = 0.03

local function getBeamConfig(options)
	options = options or {}
	local defaultConfig = WallConfig.Beam or {}
	local overrideConfig = options.Config
	if not overrideConfig then
		return defaultConfig
	end

	return {
		TemplatePath = overrideConfig.TemplatePath or defaultConfig.TemplatePath,
		PrimaryColor = overrideConfig.PrimaryColor or defaultConfig.PrimaryColor,
		SecondaryColor = overrideConfig.SecondaryColor or defaultConfig.SecondaryColor,
		UpdateRate = overrideConfig.UpdateRate or defaultConfig.UpdateRate,
		EndAttachmentNames = overrideConfig.EndAttachmentNames or defaultConfig.EndAttachmentNames,
	}
end

local function getBeamTemplate(config)
	if not config.TemplatePath or #config.TemplatePath == 0 then
		return nil
	end

	local current = ReplicatedStorage
	for _, name in ipairs(config.TemplatePath or {}) do
		current = current:FindFirstChild(name)
		if not current then
			return nil
		end
	end

	return current
end

local function getBeamColorSequence(config)
	local primaryColor = config.PrimaryColor or Color3.fromRGB(80, 185, 255)
	local secondaryColor = config.SecondaryColor or primaryColor
	return ColorSequence.new(primaryColor, secondaryColor)
end

local function applyConfiguredVisuals(instance, config)
	local colorSequence = getBeamColorSequence(config)
	local primaryColor = config.PrimaryColor or Color3.fromRGB(80, 185, 255)

	if instance:IsA("Beam") or instance:IsA("ParticleEmitter") then
		instance.Color = colorSequence
		instance.Enabled = true
	elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
		instance.Color = primaryColor
		instance.Enabled = true
	elseif instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
		instance.CanQuery = false
		instance.CanTouch = false
	end
end

local function disableEffects()
	if not activeBeam then
		return
	end

	for _, descendant in ipairs(activeBeam:GetDescendants()) do
		if descendant:IsA("Beam") or descendant:IsA("ParticleEmitter") or descendant:IsA("Light") then
			descendant.Enabled = false
		end
	end
end

local function ensureBeam(config)
	if activeBeam then
		return activeBeam
	end

	local template = getBeamTemplate(config)
	if not template then
		warn("Missing beam template for wall shooting.")
		return nil
	end

	activeBeam = template:Clone()
	activeBeam.Name = "ClientShotBeam"
	beamTrove = Trove.new()
	beamTrove:Add(activeBeam)
	beamTrove:Add(function()
		activeBeam = nil
		renderConnected = false
		renderOptions = nil
		lastRenderUpdateAt = 0
		lastOrigin = nil
		lastTargetPoint = nil
	end)

	applyConfiguredVisuals(activeBeam, config)
	for _, descendant in ipairs(activeBeam:GetDescendants()) do
		applyConfiguredVisuals(descendant, config)
	end

	if activeBeam:IsA("BasePart") then
		activeBeam.Transparency = 1
	end

	activeBeam.Parent = workspace
	return activeBeam
end

local function setAttachmentDistance(attachmentName, distance)
	if not activeBeam then
		return
	end

	local attachment = activeBeam:FindFirstChild(attachmentName, true)
	if attachment and attachment:IsA("Attachment") then
		attachment.Position = Vector3.new(attachment.Position.X, attachment.Position.Y, -distance)
	end
end

function BeamRenderer.Update(origin, targetPoint)
	if not origin or not targetPoint then
		return false
	end

	if lastOrigin and lastTargetPoint
		and (origin - lastOrigin).Magnitude < POSITION_EPSILON
		and (targetPoint - lastTargetPoint).Magnitude < POSITION_EPSILON
	then
		return true
	end

	local config = getBeamConfig(renderOptions)
	local direction = targetPoint - origin
	local distance = direction.Magnitude
	if distance < 0.1 then
		return false
	end

	local beam = ensureBeam(config)
	if not beam then
		return false
	end

	if beam:IsA("BasePart") then
		beam.CFrame = CFrame.lookAt(origin, targetPoint)
	end

	for _, attachmentName in ipairs(config.EndAttachmentNames or {}) do
		setAttachmentDistance(attachmentName, distance)
	end

	lastOrigin = origin
	lastTargetPoint = targetPoint

	return true
end

local function updateFromOptions()
	if not renderOptions then
		return
	end

	local getOrigin = renderOptions.GetOrigin
	local getTargetPoint = renderOptions.GetTargetPoint
	if type(getOrigin) ~= "function" or type(getTargetPoint) ~= "function" then
		return
	end

	BeamRenderer.Update(getOrigin(), getTargetPoint())
end

function BeamRenderer.Start(options)
	renderOptions = options or {}
	local config = getBeamConfig(renderOptions)
	ensureBeam(config)
	updateFromOptions()

	if not beamTrove or renderConnected then
		return
	end

	renderConnected = true
	beamTrove:Connect(RunService.RenderStepped, function()
		local updateRate = config.UpdateRate or 0
		if updateRate > 0 then
			local now = os.clock()
			if now - lastRenderUpdateAt < 1 / updateRate then
				return
			end
			lastRenderUpdateAt = now
		end

		updateFromOptions()
	end)
end

function BeamRenderer.Stop()
	if beamTrove then
		disableEffects()
		beamTrove:Destroy()
		beamTrove = nil
	else
		disableEffects()

		if activeBeam then
			activeBeam:Destroy()
		end
	end

	activeBeam = nil
	renderConnected = false
	renderOptions = nil
	lastRenderUpdateAt = 0
	lastOrigin = nil
	lastTargetPoint = nil
end

return BeamRenderer

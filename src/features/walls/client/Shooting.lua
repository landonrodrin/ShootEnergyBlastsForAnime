local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Trove = require(Shared:WaitForChild("Trove"))
local WallConfig = require(Shared:WaitForChild("WallConfig"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))

local Shooting = {}

local FIRE_RATE = WallConfig.FireRate
local SHOOT_ANIMATION_ID = WallConfig.ShootAnimationId
local ANIMATION_FADE_TIME = WallConfig.AnimationFadeTime
local ANIMATION_FALLBACK_CHARGE_TIME = WallConfig.AnimationFallbackChargeTime
local ANIMATION_HOLD_OFFSET = 0.04
local BEAM_TEMPLATE_PATH = { "Effects", "KamehamehaBeamTemplate" }

local started = false
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local mouseHeld = false
local charging = false
local firing = false
local fireLoopRunning = false
local activeBeam = nil
local beamTrove = nil
local beamRenderConnected = false
local statusLabel = nil
local animationCharacter = nil
local animationTrove = nil
local shootingAnimation = nil
local shootingTrack = nil
local chargeToken = 0
local fireToken = 0
local scriptTrove = Trove.new()

scriptTrove:Connect(script.Destroying, function()
	scriptTrove:Destroy()
end)

local function createHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("ShootDebugHud")
	if existing then
		return existing:WaitForChild("Status")
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ShootDebugHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.AnchorPoint = Vector2.new(1, 0)
	status.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	status.BackgroundTransparency = 0.2
	status.BorderSizePixel = 0
	status.Position = UDim2.new(1, -16, 0, 16)
	status.Size = UDim2.fromOffset(360, 44)
	status.Font = Enum.Font.GothamBold
	status.Text = "Shoot client loaded"
	status.TextColor3 = Color3.fromRGB(120, 255, 120)
	status.TextSize = 16
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = status

	return status
end

local function setStatus(text, color)
	if not statusLabel then
		return
	end

	statusLabel.Text = text
	statusLabel.TextColor3 = color or Color3.fromRGB(120, 255, 120)
end

local function getTargetPoint()
	local hit = mouse.Hit
	return hit and hit.Position or nil
end

local function getPartPosition(character, names)
	for _, name in ipairs(names) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part.Position
		end
	end

	return nil
end

local function getHandOrigin(character)
	local leftPosition = getPartPosition(character, { "LeftHand", "Left Arm", "LeftLowerArm", "LeftUpperArm" })
	local rightPosition = getPartPosition(character, { "RightHand", "Right Arm", "RightLowerArm", "RightUpperArm" })

	if leftPosition and rightPosition then
		return (leftPosition + rightPosition) * 0.5
	end

	return rightPosition or leftPosition
end

local function getCharacterShotOrigin(character)
	if not character then
		return nil
	end

	local handOrigin = getHandOrigin(character)
	if handOrigin then
		return handOrigin
	end

	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")
	local originPart = head or root
	return originPart and originPart.Position or nil
end

local function getBeamOrigin()
	return getCharacterShotOrigin(player.Character)
end

local function cleanupShootingAnimation()
	if shootingTrack then
		shootingTrack:Stop(0)
	end

	if animationTrove then
		animationTrove:Destroy()
		animationTrove = nil
	else
		if shootingTrack then
			shootingTrack:Destroy()
		end

		if shootingAnimation then
			shootingAnimation:Destroy()
		end
	end

	shootingTrack = nil
	shootingAnimation = nil
	animationCharacter = nil
end

local function createAnimationTrove()
	if animationTrove then
		animationTrove:Destroy()
	end

	animationTrove = Trove.new()
	animationTrove:Add(function()
		shootingTrack = nil
		shootingAnimation = nil
		animationCharacter = nil
	end)

	return animationTrove
end

local function stopShootingAnimation()
	if shootingTrack and shootingTrack.IsPlaying then
		shootingTrack:AdjustSpeed(1)
		shootingTrack:Stop(ANIMATION_FADE_TIME)
	end
end

local function cleanupBeam()
	if activeBeam then
		for _, descendant in ipairs(activeBeam:GetDescendants()) do
			if descendant:IsA("Beam") or descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end
	end
end

local function stopBeam()
	if beamTrove then
		cleanupBeam()
		beamTrove:Destroy()
		beamTrove = nil
	else
		cleanupBeam()

		if activeBeam then
			activeBeam:Destroy()
		end
	end

	activeBeam = nil
	beamRenderConnected = false
end

local function resetShootingState()
	mouseHeld = false
	charging = false
	firing = false
	chargeToken += 1
	fireToken += 1
	stopShootingAnimation()
	stopBeam()
end

local function cancelShooting()
	resetShootingState()
end

local function cleanupAllShooting()
	resetShootingState()
	cleanupShootingAnimation()
end

local function getShootingTrack()
	local character = player.Character
	if not character then
		return nil
	end

	if shootingTrack and animationCharacter == character then
		return shootingTrack
	end

	cleanupShootingAnimation()

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animationOwner = createAnimationTrove()
	shootingAnimation = animationOwner:Add(Instance.new("Animation"))
	shootingAnimation.Name = "KamehamehaShootAnimation"
	shootingAnimation.AnimationId = SHOOT_ANIMATION_ID

	shootingTrack = animationOwner:Add(animator:LoadAnimation(shootingAnimation))
	shootingTrack.Priority = Enum.AnimationPriority.Action
	shootingTrack.Looped = false
	animationCharacter = character

	return shootingTrack
end

local function getChargeDuration(track)
	local waitStartedAt = os.clock()
	while track.Length <= 0 and os.clock() - waitStartedAt < 0.25 do
		task.wait()
	end

	if track.Length > 0 then
		return math.max(track.Length - ANIMATION_HOLD_OFFSET, 0)
	end

	return ANIMATION_FALLBACK_CHARGE_TIME
end

local function holdFinalShootingPose(track)
	if track.Length > 0 then
		track.TimePosition = math.max(track.Length - ANIMATION_HOLD_OFFSET, 0)
	end

	track:AdjustSpeed(0)
end

local function playShootingAnimation()
	local track = getShootingTrack()
	if not track then
		return nil
	end

	track:Stop(0)
	track.TimePosition = 0
	track:AdjustSpeed(1)
	track:Play(ANIMATION_FADE_TIME)
	return track
end

local function getBeamTemplate()
	local current = ReplicatedStorage
	for _, name in ipairs(BEAM_TEMPLATE_PATH) do
		current = current:FindFirstChild(name)
		if not current then
			return nil
		end
	end

	return current
end

local function ensureBeam()
	if activeBeam then
		return activeBeam
	end

	local template = getBeamTemplate()
	if not template then
		setStatus("Missing KamehamehaBeamTemplate", Color3.fromRGB(255, 120, 120))
		return nil
	end

	activeBeam = template:Clone()
	activeBeam.Name = "ClientShotBlueBeam"
	beamTrove = Trove.new()
	beamTrove:Add(activeBeam)
	beamTrove:Add(function()
		activeBeam = nil
		beamRenderConnected = false
	end)

	if activeBeam:IsA("BasePart") then
		activeBeam.Anchored = true
		activeBeam.CanCollide = false
		activeBeam.CanQuery = false
		activeBeam.CanTouch = false
		activeBeam.Transparency = 1
	end

	for _, descendant in ipairs(activeBeam:GetDescendants()) do
		if descendant:IsA("Beam") or descendant:IsA("ParticleEmitter") then
			descendant.Enabled = true
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end

	activeBeam.Parent = workspace

	return activeBeam
end

local function setAttachmentDistance(attachmentName, distance)
	if not activeBeam then
		return
	end

	local attachment = activeBeam:FindFirstChild(attachmentName)
	if attachment and attachment:IsA("Attachment") then
		attachment.Position = Vector3.new(attachment.Position.X, attachment.Position.Y, -distance)
	end
end

local function updateBeam()
	local targetPoint = getTargetPoint()
	if not targetPoint then
		return
	end

	local origin = getBeamOrigin()
	if not origin then
		return
	end

	local direction = targetPoint - origin
	local distance = direction.Magnitude
	if distance < 0.1 then
		return
	end

	local beam = ensureBeam()
	if not beam then
		return
	end

	if beam:IsA("BasePart") then
		beam.CFrame = CFrame.lookAt(origin, targetPoint)
	end

	setAttachmentDistance("End", distance)
	setAttachmentDistance("SphereEnd", distance)
	setAttachmentDistance("SpikesEnd", distance)
end

local function startBeam()
	ensureBeam()
	updateBeam()

	if not beamTrove or beamRenderConnected then
		return
	end

	beamRenderConnected = true
	beamTrove:Connect(RunService.RenderStepped, function()
		if firing then
			updateBeam()
		end
	end)
end

local function sendShot()
	local targetPoint = getTargetPoint()
	if not targetPoint then
		setStatus("No cursor target", Color3.fromRGB(255, 210, 90))
		return
	end

	setStatus("Firing...", Color3.fromRGB(150, 220, 255))
	RequestController.Shoot(targetPoint)
end

local function startFiring()
	if fireLoopRunning then
		return
	end

	local currentFireToken = fireToken
	fireLoopRunning = true
	task.spawn(function()
		while firing and fireToken == currentFireToken do
			sendShot()
			task.wait(1 / FIRE_RATE)
		end
		fireLoopRunning = false
		if fireToken == currentFireToken then
			setStatus("Ready", Color3.fromRGB(120, 255, 120))
		end
	end)
end

local function beginActiveFiring()
	if not mouseHeld then
		return
	end

	charging = false
	firing = true
	fireToken += 1
	holdFinalShootingPose(shootingTrack)
	startBeam()
	startFiring()
end

local function startCharge()
	if mouseHeld then
		return
	end

	mouseHeld = true
	charging = true
	firing = false
	chargeToken += 1

	local currentChargeToken = chargeToken
	local track = playShootingAnimation()
	if not track then
		setStatus("Shot blocked: character not ready", Color3.fromRGB(255, 120, 120))
		mouseHeld = false
		charging = false
		return
	end

	setStatus("Charging...", Color3.fromRGB(150, 220, 255))

	task.spawn(function()
		task.wait(getChargeDuration(track))
		if not mouseHeld or not charging or chargeToken ~= currentChargeToken then
			return
		end

		beginActiveFiring()
	end)
end

local function onShootResult(result)
	if typeof(result) ~= "table" then
		return
	end

	if result.Hit then
		local suffix = result.Destroyed and " destroyed" or ""
		setStatus(
			string.format("Hit %s: %d/%d%s", result.WallName or "wall", result.Hp or 0, result.MaxHP or 0, suffix),
			result.Destroyed and Color3.fromRGB(255, 180, 80) or Color3.fromRGB(120, 255, 120)
		)
	elseif result.Reason == "walls_reset" then
		setStatus("Walls rebuilt", Color3.fromRGB(120, 255, 120))
	elseif result.Reason == "miss" or result.Reason == "not_wall" then
		setStatus("Miss", Color3.fromRGB(255, 210, 90))
	elseif result.Reason == "not_ready" then
		setStatus("Shot blocked: character not ready", Color3.fromRGB(255, 120, 120))
	else
		setStatus("Shot sent", Color3.fromRGB(150, 220, 255))
	end
end

function Shooting.Start()
	if started then
		return
	end
	started = true

	statusLabel = createHud()

	scriptTrove:Connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			startCharge()
		end
	end)

	scriptTrove:Connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			cancelShooting()
		end
	end)

	scriptTrove:Connect(player.CharacterRemoving, function()
		cleanupAllShooting()
	end)

	Packets.Listen(Packets.shootResult, onShootResult, scriptTrove)
	scriptTrove:Add(cleanupAllShooting)
	print("Wall shooting client ready")
end

return Shooting

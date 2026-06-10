local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local WallConfig = require(ReplicatedStorage.Features.Walls.Shared:WaitForChild("WallConfig"))
local BeamRenderer = require(script.Parent:WaitForChild("BeamRenderer"))
local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))

local Shooting = {}

local FIRE_RATE = WallConfig.FireRate
local SHOOT_ANIMATION_ID = WallConfig.ShootAnimationId
local ANIMATION_FADE_TIME = WallConfig.AnimationFadeTime
local ANIMATION_FALLBACK_CHARGE_TIME = WallConfig.AnimationFallbackChargeTime
local ANIMATION_HOLD_OFFSET = 0.04

local started = false
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local mouseHeld = false
local charging = false
local firing = false
local fireLoopRunning = false
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

local function resetShootingState()
	mouseHeld = false
	charging = false
	firing = false
	chargeToken += 1
	fireToken += 1
	stopShootingAnimation()
	BeamRenderer.Stop()
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

local function updateBeam()
	local targetPoint = getTargetPoint()
	if not targetPoint then
		return
	end

	local origin = getBeamOrigin()
	if not origin then
		return
	end

	BeamRenderer.Update(origin, targetPoint)
end

local function startBeam()
	BeamRenderer.Start({
		GetOrigin = getBeamOrigin,
		GetTargetPoint = getTargetPoint,
	})
	updateBeam()
end

local function sendShot()
	local targetPoint = getTargetPoint()
	if not targetPoint then
		return
	end

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
		mouseHeld = false
		charging = false
		return
	end

	task.spawn(function()
		task.wait(getChargeDuration(track))
		if not mouseHeld or not charging or chargeToken ~= currentChargeToken then
			return
		end

		beginActiveFiring()
	end)
end

function Shooting.Start()
	if started then
		return
	end
	started = true

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

	scriptTrove:Add(cleanupAllShooting)
	print("Wall shooting client ready")
end

return Shooting

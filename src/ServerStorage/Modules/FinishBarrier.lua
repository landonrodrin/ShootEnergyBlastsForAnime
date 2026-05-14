local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WallConfig = require(shared:WaitForChild("WallConfig"))
local PathUtils = require(shared:WaitForChild("PathUtils"))

local FinishBarrier = {}

local callbacks = {}
local playerTriggeredAt = {}
local started = false

local RETURN_DEBOUNCE = 0.75
local MIN_RETURN_SPEED = 2
local ANIME_SIDE_MIN_X = 0

local function getPlayerFromHit(hit)
	if not hit then
		return nil
	end

	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getFinishLine()
	return PathUtils.FindByPath(workspace, WallConfig.FinishLinePath)
end

local function getBarrier()
	return PathUtils.FindByPath(workspace, WallConfig.FinishBarrierPath)
end

local function isReturningFromAnimeSide(player, finishLine)
	local root = getCharacterRoot(player)
	if not root then
		return false
	end

	local localVelocity = finishLine.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
	if localVelocity.X > -MIN_RETURN_SPEED then
		return false
	end

	local localPosition = finishLine.CFrame:PointToObjectSpace(root.Position)

	return localPosition.X >= ANIME_SIDE_MIN_X
end

local function notifyReturn(player)
	for _, callback in ipairs(callbacks) do
		task.spawn(callback, player)
	end
end

function FinishBarrier.OnReturn(callback)
	assert(typeof(callback) == "function", "Finish barrier callback must be a function")

	table.insert(callbacks, callback)
	FinishBarrier.Start()
end

function FinishBarrier.Start()
	if started then
		return
	end
	started = true

	local finishLine = getFinishLine()
	if not finishLine or not finishLine:IsA("BasePart") then
		warn("Missing finish line:", table.concat(WallConfig.FinishLinePath, "."))
		return
	end

	local barrier = getBarrier()
	if not barrier or not barrier:IsA("BasePart") then
		warn("Missing anime return barrier:", table.concat(WallConfig.FinishBarrierPath, "."))
		return
	end

	barrier.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not isReturningFromAnimeSide(player, finishLine) then
			return
		end

		local now = os.clock()
		local lastTriggered = playerTriggeredAt[player]
		if lastTriggered and now - lastTriggered < RETURN_DEBOUNCE then
			return
		end

		playerTriggeredAt[player] = now
		notifyReturn(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	playerTriggeredAt[player] = nil
end)

return FinishBarrier

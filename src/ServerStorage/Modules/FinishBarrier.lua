local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WallConfig = require(shared:WaitForChild("WallConfig"))
local PathUtils = require(shared:WaitForChild("PathUtils"))
local Trove = require(shared:WaitForChild("Trove"))

local FinishBarrier = {}

local callbacks = {}
local playerCrossingStates = {}
local setupTrove = Trove.new()
local playerTroves = {}
local started = false

local ANIME_SIDE_MIN_X = 0
local ANIME_SIDE_RESET_X = 1
local DEFAULT_CALLBACK_PRIORITY = 0

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

local function getLocalX(player, finishLine)
	local root = getCharacterRoot(player)
	if not root then
		return nil
	end

	local localPosition = finishLine.CFrame:PointToObjectSpace(root.Position)

	return localPosition.X
end

local function initializePlayerCrossing(player, finishLine)
	local localX = getLocalX(player, finishLine)
	if not localX then return end

	playerCrossingStates[player] = {
		PreviousLocalX = localX,
		Armed = localX >= ANIME_SIDE_MIN_X
	}
end

local function cleanupPlayerCrossing(player)
	local playerTrove = playerTroves[player]
	if playerTrove then
		playerTrove:Destroy()
		playerTroves[player] = nil
	end

	playerCrossingStates[player] = nil
end

local function bindPlayerCrossing(player, finishLine)
	cleanupPlayerCrossing(player)

	local playerTrove = setupTrove:Extend()
	playerTroves[player] = playerTrove

	playerTrove:Add(function()
		if playerTroves[player] == playerTrove then
			playerTroves[player] = nil
		end

		playerCrossingStates[player] = nil
	end)

	if player.Character then
		task.defer(function()
			initializePlayerCrossing(player, finishLine)
		end)
	end

	playerTrove:Connect(player.CharacterAdded, function()
		task.defer(function()
			initializePlayerCrossing(player, finishLine)
		end)
	end)
end

local function notifyReturn(player)
	for _, callbackData in ipairs(callbacks) do
		local success, err = pcall(callbackData.Callback, player)
		if not success then
			warn(string.format("Finish barrier return callback failed for %s: %s", player.Name, tostring(err)))
		end
	end
end

local function updatePlayerCrossing(player, finishLine)
	local localX = getLocalX(player, finishLine)
	if not localX then
		playerCrossingStates[player] = nil
		return
	end

	local state = playerCrossingStates[player]
	if not state then
		initializePlayerCrossing(player, finishLine)
		return
	end

	if localX >= ANIME_SIDE_RESET_X then
		state.Armed = true
	end

	if state.Armed and localX < ANIME_SIDE_MIN_X then
		state.Armed = false
		notifyReturn(player)
	end

	state.PreviousLocalX = localX
end

function FinishBarrier.OnReturn(callback, priority)
	assert(typeof(callback) == "function", "Finish barrier callback must be a function")

	table.insert(callbacks, {
		Callback = callback,
		Priority = priority or DEFAULT_CALLBACK_PRIORITY
	})

	table.sort(callbacks, function(A, B)
		return A.Priority > B.Priority
	end)

	FinishBarrier.Start()

	return function()
		for index, callbackData in ipairs(callbacks) do
			if callbackData.Callback == callback then
				table.remove(callbacks, index)
				break
			end
		end
	end
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

	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayerCrossing(player, finishLine)
	end

	setupTrove:Connect(Players.PlayerAdded, function(player)
		bindPlayerCrossing(player, finishLine)
	end)

	setupTrove:Connect(RunService.Heartbeat, function()
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayerCrossing(player, finishLine)
		end
	end)

	setupTrove:Connect(Players.PlayerRemoving, cleanupPlayerCrossing)
end

return FinishBarrier

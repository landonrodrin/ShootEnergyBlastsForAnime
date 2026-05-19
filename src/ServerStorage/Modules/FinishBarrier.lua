local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WallConfig = require(shared:WaitForChild("WallConfig"))
local PathUtils = require(shared:WaitForChild("PathUtils"))

local FinishBarrier = {}

local callbacks = {}
local playerCrossingStates = {}
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

local function bindPlayerCrossing(player, finishLine)
	if player.Character then
		task.defer(function()
			initializePlayerCrossing(player, finishLine)
		end)
	end

	player.CharacterAdded:Connect(function()
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

	Players.PlayerAdded:Connect(function(player)
		bindPlayerCrossing(player, finishLine)
	end)

	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayerCrossing(player, finishLine)
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	playerCrossingStates[player] = nil
end)

return FinishBarrier

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local WallDamage = require(script.Parent:WaitForChild("WallDamage"))
local WallRegistry = require(script.Parent:WaitForChild("WallRegistry"))
local SharedModules = ServerStorage:WaitForChild("Shared")
local FinishBarrier = require(SharedModules:WaitForChild("FinishBarrier"))

local WallGameplay = {}

local started = false
local setupTrove = Trove.new()
local playerTroves = {}
local characterTroves = {}
local PLAYER_COLLISION_GROUP = "Players"
local LOCAL_DEBRIS_COLLISION_GROUP = "LocalWallDebris"

local function ensureCollisionGroup(name)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

local function setupCollisionGroups()
	ensureCollisionGroup(PLAYER_COLLISION_GROUP)
	ensureCollisionGroup(LOCAL_DEBRIS_COLLISION_GROUP)

	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(LOCAL_DEBRIS_COLLISION_GROUP, PLAYER_COLLISION_GROUP, false)
	end)
end

local function setPartCollisionGroup(part, groupName)
	pcall(function()
		part.CollisionGroup = groupName
	end)
end

local function assignCharacterCollisionGroup(character, characterTrove)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			setPartCollisionGroup(descendant, PLAYER_COLLISION_GROUP)
		end
	end

	characterTrove:Connect(character.DescendantAdded, function(descendant)
		if descendant:IsA("BasePart") then
			setPartCollisionGroup(descendant, PLAYER_COLLISION_GROUP)
		end
	end)
end

local function cleanupPlayerCollision(player)
	local playerTrove = playerTroves[player]
	if playerTrove then
		playerTrove:Destroy()
		playerTroves[player] = nil
	end

	characterTroves[player] = nil
end

local function setupCharacterCollision(player, character)
	local previousCharacterTrove = characterTroves[player]
	if previousCharacterTrove then
		previousCharacterTrove:Destroy()
	end

	local playerTrove = playerTroves[player]
	if not playerTrove then
		return
	end

	local characterTrove = playerTrove:Extend()
	characterTroves[player] = characterTrove

	characterTrove:Add(function()
		if characterTroves[player] == characterTrove then
			characterTroves[player] = nil
		end
	end)

	characterTrove:Connect(character.Destroying, function()
		characterTrove:Destroy()
	end)

	assignCharacterCollisionGroup(character, characterTrove)
end

local function setupPlayerCollision(player)
	cleanupPlayerCollision(player)

	local playerTrove = setupTrove:Extend()
	playerTroves[player] = playerTrove

	playerTrove:Add(function()
		if playerTroves[player] == playerTrove then
			playerTroves[player] = nil
		end
	end)

	if player.Character then
		setupCharacterCollision(player, player.Character)
	end

	playerTrove:Connect(player.CharacterAdded, function(character)
		setupCharacterCollision(player, character)
	end)
end

local function sendResetResult(player)
	if not player then
		return
	end

	Packets.shootResult.sendTo({
		Hit = false,
		Reason = "walls_reset",
	}, player)
end

function WallGameplay.Start()
	if started then
		return
	end
	started = true

	setupCollisionGroups()
	Packets.shootRequest.listen(function(data, player)
		if not player then return end
		WallDamage.OnShoot(player, data)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerCollision(player)
	end
	setupTrove:Connect(Players.PlayerAdded, setupPlayerCollision)

	setupTrove:Connect(Players.PlayerRemoving, function(player)
		cleanupPlayerCollision(player)
		WallDamage.ClearPlayer(player)
	end)

	WallRegistry.RegisterDamageableWalls()

	FinishBarrier.OnReturn(WallGameplay.ResetForFinishBarrier)
	print("Wall shooting server ready")
end

function WallGameplay.ResetForFinishBarrier(player)
	WallRegistry.ResetAllWalls()
	sendResetResult(player)
end

return WallGameplay

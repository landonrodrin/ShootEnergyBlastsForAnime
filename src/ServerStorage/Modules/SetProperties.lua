local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Shared:WaitForChild("Promise"))
local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))

local SetPropertiesEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("SetProperties")
local RETRY_INTERVAL = 0.5

local ConfirmedIdentifiers = {}

local PropertyCache = {}
local PlayerPropertyCache = {}
local PlayerTroves = {}
local ObjectTroves = setmetatable({}, {__mode = "k"})
local ModuleTrove = Trove.new()

ModuleTrove:Connect(SetPropertiesEvent.OnServerEvent, function(Player, Identifier)
	if not Identifier then return end
	
	ConfirmedIdentifiers[Identifier] = true
end)

local function getPlayerTrove(Player)
	local PlayerTrove = PlayerTroves[Player]
	if PlayerTrove then
		return PlayerTrove
	end

	PlayerTrove = ModuleTrove:Extend()
	PlayerTroves[Player] = PlayerTrove

	PlayerTrove:Add(function()
		if PlayerTroves[Player] == PlayerTrove then
			PlayerTroves[Player] = nil
		end

		PlayerPropertyCache[Player] = nil
	end)

	return PlayerTrove
end

local function getObjectTrove(Object)
	if typeof(Object) ~= "Instance" then
		return nil
	end

	local ObjectTrove = ObjectTroves[Object]
	if ObjectTrove then
		return ObjectTrove
	end

	ObjectTrove = ModuleTrove:Extend()
	ObjectTroves[Object] = ObjectTrove

	ObjectTrove:Add(function()
		if ObjectTroves[Object] == ObjectTrove then
			ObjectTroves[Object] = nil
		end

		PropertyCache[Object] = nil
		for _, Cache in pairs(PlayerPropertyCache) do
			Cache[Object] = nil
		end
	end)

	ObjectTrove:Connect(Object.Destroying, function()
		ObjectTrove:Destroy()
	end)

	return ObjectTrove
end

local function isValidTarget(Player, Object)
	if not Player or not Player.Parent then
		return false
	end

	if typeof(Object) == "Instance" and not Object:IsDescendantOf(game) then
		return false
	end

	return true
end

local function SetPropertiesUntilConfirmed(Player, Object, Properties)
	local Identifier = HttpService:GenerateGUID(false)
	local RequestTrove = Trove.new()
	local RetryPromise = nil
	local Cancelled = false
	
	ConfirmedIdentifiers[Identifier] = false

	RequestTrove:Add(function()
		Cancelled = true

		if RetryPromise then
			RetryPromise:cancel()
			RetryPromise = nil
		end

		ConfirmedIdentifiers[Identifier] = nil
	end)

	local PlayerTrove = getPlayerTrove(Player)
	PlayerTrove:Add(RequestTrove)

	local ObjectTrove = getObjectTrove(Object)
	if ObjectTrove then
		ObjectTrove:Add(RequestTrove)
	end

	local RequestPromise
	RequestPromise = Promise.new(function(resolve, _, onCancel)
		onCancel(function()
			RequestTrove:Destroy()
		end)

		local function retry()
			if Cancelled then
				resolve(false)
				return
			end

			if ConfirmedIdentifiers[Identifier] then
				resolve(true)
				return
			end

			if not isValidTarget(Player, Object) then
				resolve(false)
				return
			end

			SetPropertiesEvent:FireClient(Player, Identifier, Object, Properties)

			RetryPromise = Promise.delay(RETRY_INTERVAL):andThen(retry)
			RequestTrove:AddPromise(RetryPromise)
		end

		retry()
	end):finally(function()
		RequestTrove:Destroy()
	end)

	RequestTrove:AddPromise(RequestPromise)

	return RequestPromise
end

local SetProperties = {}

function SetProperties.Client(Player, Object, Properties)
	PlayerPropertyCache[Player] = PlayerPropertyCache[Player] or {}
	
	local Cache = PlayerPropertyCache[Player]
	
	Cache[Object] = Cache[Object] or {}

	for Property, Value in pairs(Properties) do
		Cache[Object][Property] = Value
	end

	return SetPropertiesUntilConfirmed(Player, Object, Properties)
end

function SetProperties.AllClients(Object, Properties)
	local Promises = {}

	for _, Player in ipairs(Players:GetPlayers()) do
		table.insert(Promises, SetPropertiesUntilConfirmed(Player, Object, Properties))
	end

	PropertyCache[Object] = PropertyCache[Object] or {}

	for Property, Value in pairs(Properties) do
		PropertyCache[Object][Property] = Value
	end

	if #Promises == 0 then
		return Promise.resolve({})
	end

	return Promise.all(Promises)
end

function SetProperties.AllClientsExcept(ExceptPlayer, Object, Properties)
	local Promises = {}

	for _, Player in ipairs(Players:GetPlayers()) do
		if Player == ExceptPlayer then continue end

		table.insert(Promises, SetPropertiesUntilConfirmed(Player, Object, Properties))
	end

	PropertyCache[Object] = PropertyCache[Object] or {}

	for Property, Value in pairs(Properties) do
		PropertyCache[Object][Property] = Value
	end

	if #Promises == 0 then
		return Promise.resolve({})
	end

	return Promise.all(Promises)
end

ModuleTrove:Connect(Players.PlayerAdded, function(Player)
	getPlayerTrove(Player)

	local PlayerCache = PlayerPropertyCache[Player] or {}

	for Object, Properties in pairs(PropertyCache) do
		if Object and Object:IsDescendantOf(game) then
			if not PlayerCache or not PlayerCache[Object] then
				SetPropertiesUntilConfirmed(Player, Object, Properties)
			end
		end
	end

	if not PlayerCache then return end

	for Object, Properties in pairs(PlayerCache) do
		if Object and Object:IsDescendantOf(game) then
			SetPropertiesUntilConfirmed(Player, Object, Properties)
		end
	end
end)

ModuleTrove:Connect(Players.PlayerRemoving, function(Player)
	local PlayerTrove = PlayerTroves[Player]
	if PlayerTrove then
		PlayerTrove:Destroy()
	end
end)

for _, Player in ipairs(Players:GetPlayers()) do
	getPlayerTrove(Player)
end

return SetProperties

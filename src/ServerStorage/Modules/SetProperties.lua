local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SetPropertiesEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("SetProperties")

local ConfirmedIdentifiers = {}

local PropertyCache = {}
local PlayerPropertyCache = {}

SetPropertiesEvent.OnServerEvent:Connect(function(Player, Identifier)
	if not Identifier then return end
	
	ConfirmedIdentifiers[Identifier] = true
end)

local function SetPropertiesUntilConfirmed(Player, Object, Properties)
	local Identifier = HttpService:GenerateGUID(false)
	
	ConfirmedIdentifiers[Identifier] = false

	while not ConfirmedIdentifiers[Identifier] do
		SetPropertiesEvent:FireClient(Player, Identifier, Object, Properties)
		
		task.wait(0.5)
	end

	ConfirmedIdentifiers[Identifier] = nil
end

local SetProperties = {}

function SetProperties.Client(Player, Object, Properties)
	task.spawn(SetPropertiesUntilConfirmed, Player, Object, Properties)

	PlayerPropertyCache[Player] = PlayerPropertyCache[Player] or {}
	
	local Cache = PlayerPropertyCache[Player]
	
	Cache[Object] = Cache[Object] or {}

	for Property, Value in pairs(Properties) do
		Cache[Object][Property] = Value
	end
end

function SetProperties.AllClients(Object, Properties)
	for _, Player in ipairs(Players:GetPlayers()) do
		task.spawn(SetPropertiesUntilConfirmed, Player, Object, Properties)
	end

	PropertyCache[Object] = PropertyCache[Object] or {}

	for Property, Value in pairs(Properties) do
		PropertyCache[Object][Property] = Value
	end
end

function SetProperties.AllClientsExcept(ExceptPlayer, Object, Properties)
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player == ExceptPlayer then continue end

		task.spawn(SetPropertiesUntilConfirmed, Player, Object, Properties)
	end

	PropertyCache[Object] = PropertyCache[Object] or {}

	for Property, Value in pairs(Properties) do
		PropertyCache[Object][Property] = Value
	end
end

Players.PlayerAdded:Connect(function(Player)
	local PlayerCache = PlayerPropertyCache[Player] or {}

	for Object, Properties in pairs(PropertyCache) do
		if Object and Object:IsDescendantOf(game) then
			if not PlayerCache or not PlayerCache[Object] then
				task.spawn(SetPropertiesUntilConfirmed, Player, Object, Properties)
			end
		end
	end

	if not PlayerCache then return end

	for Object, Properties in pairs(PlayerCache) do
		if Object and Object:IsDescendantOf(game) then
			task.spawn(SetPropertiesUntilConfirmed, Player, Object, Properties)
		end
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	PlayerPropertyCache[Player] = nil
end)

return SetProperties

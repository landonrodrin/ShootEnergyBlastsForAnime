local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))

local StatsController = {}

local ScriptTrove = Trove.new()
local ChangedEvent = Instance.new("BindableEvent")
local Started = false

local State = {
	Money = 0,
	Speed = GameConfigurations.Defaults.Speed,
	Carry = 0,
	Rebirths = 0,
}

StatsController.Changed = ChangedEvent.Event

local function setState(Name, Value)
	if State[Name] == Value then return end

	State[Name] = Value
	ChangedEvent:Fire(Name, Value)
end

function StatsController.Init() end

function StatsController.Start()
	if Started then return end
	Started = true

	ScriptTrove:Add(ChangedEvent)

	Packets.Listen(Packets.money, function(Money)
		setState("Money", tonumber(Money) or 0)
	end, ScriptTrove)

	Packets.Listen(Packets.speed, function(Speed)
		setState("Speed", tonumber(Speed) or State.Speed)
	end, ScriptTrove)

	Packets.Listen(Packets.carry, function(Carry)
		setState("Carry", tonumber(Carry) or 0)
	end, ScriptTrove)

	Packets.Listen(Packets.rebirth, function(Data)
		if typeof(Data) ~= "table" then return end

		setState("Rebirths", tonumber(Data.Rebirths) or 0)
		setState("Speed", tonumber(Data.Speed) or State.Speed)
	end, ScriptTrove)

	ScriptTrove:Connect(script.Destroying, function()
		ScriptTrove:Destroy()
	end)
end

function StatsController.Get(Name)
	return State[Name]
end

function StatsController.GetAll()
	return table.clone(State)
end

return StatsController

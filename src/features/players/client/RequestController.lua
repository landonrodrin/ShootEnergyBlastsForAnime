local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))

local RequestController = {}

local Started = false
local LastSentAt = {}

local REQUESTS = {
	IncrementSpeed = {
		Cooldown = 0.2,
		Send = function(Value)
			Packets.incrementSpeed.send(Value)
		end,
	},
	IncrementCarry = {
		Cooldown = 0.2,
		Send = function(Value)
			Packets.incrementCarry.send(Value)
		end,
	},
	Rebirth = {
		Cooldown = 0.75,
		Send = function()
			Packets.rebirthRequest.send(nil)
		end,
	},
	SellInventory = {
		Cooldown = 0.3,
		Send = function(Value)
			Packets.sellInventory.send(Value)
		end,
	},
	EquipInventory = {
		Cooldown = 0.12,
		Send = function(Value)
			Packets.equipInventory.send(Value)
		end,
	},
	UpdateHotbarSlot = {
		Cooldown = 0.12,
		Send = function(Value)
			Packets.updateHotbarSlot.send(Value)
		end,
	},
	IndexRequest = {
		Cooldown = 0.2,
		Send = function(Value)
			Packets.indexRequest.send(Value)
		end,
	},
	LevelRequest = {
		Cooldown = 0.3,
		Send = function(Value)
			Packets.levelRequest.send(Value)
		end,
	},
	Drop = {
		Cooldown = 0.25,
		Send = function()
			Packets.dropRequest.send(nil)
		end,
	},
	Shoot = {
		Cooldown = 0.03,
		Send = function(Value)
			Packets.shootRequest.send(Value)
		end,
	},
}

function RequestController.Init() end

function RequestController.Start()
	if Started then return end
	Started = true
end

function RequestController.CanSend(Name)
	local Definition = REQUESTS[Name]
	if not Definition then return false end

	local Now = os.clock()
	local LastSent = LastSentAt[Name] or 0
	return Now - LastSent >= Definition.Cooldown
end

function RequestController.Send(Name, Value)
	local Definition = REQUESTS[Name]
	if not Definition then
		warn(string.format("Unknown request action %q", tostring(Name)))
		return false
	end

	if not RequestController.CanSend(Name) then
		return false
	end

	LastSentAt[Name] = os.clock()
	Definition.Send(Value)
	return true
end

function RequestController.IncrementSpeed(Amount)
	return RequestController.Send("IncrementSpeed", Amount)
end

function RequestController.IncrementCarry(Amount)
	return RequestController.Send("IncrementCarry", Amount)
end

function RequestController.Rebirth()
	return RequestController.Send("Rebirth")
end

function RequestController.SellInventory(Mode, Id)
	return RequestController.Send("SellInventory", {
		Mode = Mode,
		Id = Id,
	})
end

function RequestController.EquipInventory(Id)
	return RequestController.Send("EquipInventory", {
		Id = Id,
	})
end

function RequestController.UpdateHotbarSlot(Slot, Id)
	return RequestController.Send("UpdateHotbarSlot", {
		Slot = Slot,
		Id = Id,
	})
end

function RequestController.IndexRequest(Mutation)
	return RequestController.Send("IndexRequest", {
		Mutation = Mutation,
	})
end

function RequestController.LevelRequest(Identifier)
	return RequestController.Send("LevelRequest", {
		Identifier = Identifier,
	})
end

function RequestController.Drop()
	return RequestController.Send("Drop")
end

function RequestController.Shoot(TargetPoint)
	return RequestController.Send("Shoot", {
		TargetPoint = TargetPoint,
	})
end

return RequestController

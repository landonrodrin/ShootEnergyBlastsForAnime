local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))

local InventoryController = {}

local ScriptTrove = Trove.new()
local ChangedEvent = Instance.new("BindableEvent")
local Started = false
local RequestController

local Inventory = {
	Items = {},
	EquippedId = nil,
	HotbarOrder = {},
	MaxHotbarSlots = 0,
}

local CanDrop = false

InventoryController.Changed = ChangedEvent.Event

local function getRequestController()
	if not RequestController then
		RequestController = require(script.Parent:WaitForChild("RequestController"))
		RequestController.Start()
	end

	return RequestController
end

local function fireChanged(Name, Value)
	ChangedEvent:Fire(Name, Value)
end

function InventoryController.Init(Controllers)
	RequestController = Controllers.RequestController
end

function InventoryController.Start()
	if Started then return end
	Started = true

	ScriptTrove:Add(ChangedEvent)

	Packets.Listen(Packets.inventorySync, function(Snapshot)
		Inventory = Packets.DecodeInventorySnapshot(Snapshot or Inventory)
		fireChanged("Inventory", InventoryController.GetSnapshot())
	end, ScriptTrove)

	Packets.Listen(Packets.dropState, function(Data)
		local NextCanDrop = Data and Data.CanDrop == true
		if CanDrop == NextCanDrop then return end

		CanDrop = NextCanDrop
		fireChanged("CanDrop", CanDrop)
	end, ScriptTrove)

	ScriptTrove:Connect(script.Destroying, function()
		ScriptTrove:Destroy()
	end)
end

function InventoryController.GetSnapshot()
	return {
		Items = table.clone(Inventory.Items or {}),
		EquippedId = Inventory.EquippedId,
		HotbarOrder = table.clone(Inventory.HotbarOrder or {}),
		MaxHotbarSlots = Inventory.MaxHotbarSlots or 0,
	}
end

function InventoryController.GetItems()
	return table.clone(Inventory.Items or {})
end

function InventoryController.GetEquippedId()
	return Inventory.EquippedId
end

function InventoryController.CanDrop()
	return CanDrop
end

function InventoryController.GetSellTotal()
	local Total = 0
	for _, Item in ipairs(Inventory.Items or {}) do
		Total += tonumber(Item.Sell) or 0
	end
	return Total
end

function InventoryController.SellSingle(Id)
	return getRequestController().SellInventory("Single", Id)
end

function InventoryController.SellAll()
	return getRequestController().SellInventory("All")
end

function InventoryController.Equip(Id)
	return getRequestController().EquipInventory(Id)
end

function InventoryController.UpdateHotbarSlot(Slot, Id)
	return getRequestController().UpdateHotbarSlot(Slot, Id)
end

function InventoryController.Drop()
	if not CanDrop then return false end

	return getRequestController().Drop()
end

return InventoryController

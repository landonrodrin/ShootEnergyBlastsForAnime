return function(ctx)
	local BASE_LEVEL_NAME = ctx.BASE_LEVEL_NAME
	local FLOORS_FOLDER_NAME = ctx.FLOORS_FOLDER_NAME
	local SLOTS_FOLDER_NAME = ctx.SLOTS_FOLDER_NAME
	local SLOT_SPAWN_NAME = ctx.SLOT_SPAWN_NAME
	local SLOT_LEVEL_NAME = ctx.SLOT_LEVEL_NAME
	local SLOT_MONEY_NAME = ctx.SLOT_MONEY_NAME
	local Bases = ctx.Bases
local function sortByNumericName(Instances)
	table.sort(Instances, function(A, B)
		local ANumber = tonumber(A.Name)
		local BNumber = tonumber(B.Name)

		if ANumber and BNumber then
			return ANumber < BNumber
		elseif ANumber then
			return true
		elseif BNumber then
			return false
		end

		return A.Name < B.Name
	end)
end

local function getBaseLevelPart(Base)
	local BaseLevel = Base and Base:FindFirstChild(BASE_LEVEL_NAME)
	if BaseLevel and BaseLevel:IsA("BasePart") then
		return BaseLevel
	end
end

local function getOrderedFloors(Base)
	local FloorsFolder = Base and Base:FindFirstChild(FLOORS_FOLDER_NAME)
	local Floors = FloorsFolder and FloorsFolder:GetChildren() or {}
	sortByNumericName(Floors)
	return Floors
end

local function getOrderedSlots(Base)
	local Slots = {}

	for _, Floor in ipairs(getOrderedFloors(Base)) do
		local SlotsFolder = Floor:FindFirstChild(SLOTS_FOLDER_NAME)
		if not SlotsFolder then continue end

		local FloorSlots = SlotsFolder:GetChildren()
		sortByNumericName(FloorSlots)

		for _, Slot in ipairs(FloorSlots) do
			table.insert(Slots, Slot)
		end
	end

	if #Slots == 0 then
		local LegacySlotsFolder = Base and Base:FindFirstChild(SLOTS_FOLDER_NAME)
		if LegacySlotsFolder then
			Slots = LegacySlotsFolder:GetChildren()
			sortByNumericName(Slots)
		end
	end

	return Slots
end

local function getSlotByName(Base, SlotName)
	SlotName = tostring(SlotName)

	for _, Slot in ipairs(getOrderedSlots(Base)) do
		if Slot.Name == SlotName then
			return Slot
		end
	end
end

local function getSlotSpawn(Slot)
	return Slot and Slot:FindFirstChild(SLOT_SPAWN_NAME)
end

local function getSlotLevel(Slot)
	return Slot and Slot:FindFirstChild(SLOT_LEVEL_NAME)
end

local function getSlotMoney(Slot)
	return Slot and Slot:FindFirstChild(SLOT_MONEY_NAME)
end

local function getSlotAttachment(Slot)
	local Spawn = getSlotSpawn(Slot)
	return Spawn and Spawn:FindFirstChild("Attachment")
end
function Bases.GetBaseLevelPart(Base)
	return getBaseLevelPart(Base)
end

function Bases.GetSlots(Base)
	return getOrderedSlots(Base)
end

function Bases.GetSlotByName(Base, SlotName)
	return getSlotByName(Base, SlotName)
end

function Bases.GetSlotSpawn(Slot)
	return getSlotSpawn(Slot)
end

function Bases.GetSlotLevel(Slot)
	return getSlotLevel(Slot)
end

function Bases.GetSlotMoney(Slot)
	return getSlotMoney(Slot)
end

function Bases.GetSlotAttachment(Slot)
	return getSlotAttachment(Slot)
end
	ctx.sortByNumericName = sortByNumericName
	ctx.getBaseLevelPart = getBaseLevelPart
	ctx.getOrderedFloors = getOrderedFloors
	ctx.getOrderedSlots = getOrderedSlots
	ctx.getSlotByName = getSlotByName
	ctx.getSlotSpawn = getSlotSpawn
	ctx.getSlotLevel = getSlotLevel
	ctx.getSlotMoney = getSlotMoney
	ctx.getSlotAttachment = getSlotAttachment
end

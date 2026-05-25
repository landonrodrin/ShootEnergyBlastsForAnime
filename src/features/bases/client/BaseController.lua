local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local BaseConfigurations = require(ReplicatedStorage.Features.Bases.Shared:WaitForChild("BaseConfigurations"))

local BaseController = {}

local LOCAL_PLAYER = Players.LocalPlayer

local BASES_FOLDER_NAME = "Bases"
local FLOORS_FOLDER_NAME = "Floors"
local SLOTS_FOLDER_NAME = "Slots"
local SLOT_SPAWN_NAME = "Spawn"

local PROMPT_NAMES = {
	Grab = "GrabProximityPrompt",
	Place = "PlaceProximityPrompt",
	Swap = "SwapProximityPrompt",
	Steal = "StealProximityPrompt",
	Sell = "SellProximityPrompt",
}

local ScriptTrove = Trove.new()
local ChangedEvent = Instance.new("BindableEvent")
local ConnectedPrompts = setmetatable({}, {__mode = "k"})
local RefreshQueued = false
local Started = false
local PlayerController
local OwnedBase = nil

BaseController.Changed = ChangedEvent.Event

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

local function getOrderedSlots(Base)
	local Slots = {}
	local FloorsFolder = Base and Base:FindFirstChild(FLOORS_FOLDER_NAME)
	local Floors = FloorsFolder and FloorsFolder:GetChildren() or {}
	sortByNumericName(Floors)

	for _, Floor in ipairs(Floors) do
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

local function getSlotAttachment(Slot)
	local Spawn = Slot and Slot:FindFirstChild(SLOT_SPAWN_NAME)
	return Spawn and Spawn:FindFirstChild("Attachment")
end

local function getPrompt(Attachment, Name)
	local Prompt = Attachment and Attachment:FindFirstChild(Name)
	if Prompt and Prompt:IsA("ProximityPrompt") then
		return Prompt
	end

	return nil
end

local function setPromptEnabled(Prompt, Enabled)
	if Prompt and Prompt.Enabled ~= Enabled then
		Prompt.Enabled = Enabled
	end
end

local function getUnlockedSlotCount(Base)
	local Level = Base:GetAttribute("Level") or 1
	local Configuration = BaseConfigurations[Level] or BaseConfigurations[1] or {}
	return Configuration.Slots or 0
end

local function applyOwnedSlotPrompts(Slot, HasEquippedAnime, UnlockedSlots)
	local Attachment = getSlotAttachment(Slot)
	if not Attachment then return end

	local GrabPrompt = getPrompt(Attachment, PROMPT_NAMES.Grab)
	local PlacePrompt = getPrompt(Attachment, PROMPT_NAMES.Place)
	local SwapPrompt = getPrompt(Attachment, PROMPT_NAMES.Swap)
	local StealPrompt = getPrompt(Attachment, PROMPT_NAMES.Steal)
	local SellPrompt = getPrompt(Attachment, PROMPT_NAMES.Sell)

	setPromptEnabled(GrabPrompt, false)
	setPromptEnabled(PlacePrompt, false)
	setPromptEnabled(SwapPrompt, false)
	setPromptEnabled(StealPrompt, false)
	setPromptEnabled(SellPrompt, false)

	local SlotNumber = tonumber(Slot.Name)
	if not SlotNumber or SlotNumber > UnlockedSlots then return end

	local Occupied = Slot:GetAttribute("Occupied") == true

	if HasEquippedAnime then
		if Occupied then
			setPromptEnabled(SwapPrompt, true)
		else
			setPromptEnabled(PlacePrompt, true)
		end
	elseif Occupied then
		setPromptEnabled(GrabPrompt, true)
		setPromptEnabled(SellPrompt, true)
	end
end

local function applyNonOwnedSlotPrompts(Slot)
	local Attachment = getSlotAttachment(Slot)
	if not Attachment then return end

	setPromptEnabled(getPrompt(Attachment, PROMPT_NAMES.Grab), false)
	setPromptEnabled(getPrompt(Attachment, PROMPT_NAMES.Place), false)
	setPromptEnabled(getPrompt(Attachment, PROMPT_NAMES.Swap), false)
	setPromptEnabled(getPrompt(Attachment, PROMPT_NAMES.Sell), false)
end

local function getBasesFolder()
	return workspace:FindFirstChild(BASES_FOLDER_NAME)
end

local function refreshPrompts()
	local BasesFolder = getBasesFolder()
	if not BasesFolder then return end

	local HasEquippedAnime = PlayerController and PlayerController.HasEquippedAnime() == true
	local NextOwnedBase = nil

	for _, Base in ipairs(BasesFolder:GetChildren()) do
		local IsOwned = Base:GetAttribute("OwnerUserId") == LOCAL_PLAYER.UserId
		local UnlockedSlots = IsOwned and getUnlockedSlotCount(Base) or 0

		if IsOwned then
			NextOwnedBase = Base
		end

		for _, Slot in ipairs(getOrderedSlots(Base)) do
			if IsOwned then
				applyOwnedSlotPrompts(Slot, HasEquippedAnime, UnlockedSlots)
			else
				applyNonOwnedSlotPrompts(Slot)
			end
		end
	end

	if OwnedBase ~= NextOwnedBase then
		OwnedBase = NextOwnedBase
		ChangedEvent:Fire("OwnedBase", OwnedBase)
	end
end

local function scheduleRefresh()
	if RefreshQueued then return end
	RefreshQueued = true

	task.defer(function()
		RefreshQueued = false
		refreshPrompts()
	end)
end

local function connectPrompt(Prompt, OwnerTrove)
	if not Prompt:IsA("ProximityPrompt") or ConnectedPrompts[Prompt] then return end

	ConnectedPrompts[Prompt] = true
	OwnerTrove:Connect(Prompt.Destroying, function()
		ConnectedPrompts[Prompt] = nil
	end)
end

local function connectSlot(Slot, OwnerTrove)
	OwnerTrove:Connect(Slot:GetAttributeChangedSignal("Occupied"), scheduleRefresh)
end

local function connectBase(Base)
	local BaseTrove = ScriptTrove:Extend()

	BaseTrove:Connect(Base:GetAttributeChangedSignal("OwnerUserId"), scheduleRefresh)
	BaseTrove:Connect(Base:GetAttributeChangedSignal("Level"), scheduleRefresh)
	BaseTrove:Connect(Base.DescendantAdded, function(Descendant)
		if Descendant:IsA("ProximityPrompt") then
			connectPrompt(Descendant, BaseTrove)
		elseif Descendant:GetAttribute("Occupied") ~= nil then
			connectSlot(Descendant, BaseTrove)
		end

		scheduleRefresh()
	end)
	BaseTrove:Connect(Base.Destroying, function()
		BaseTrove:Destroy()
		scheduleRefresh()
	end)

	for _, Slot in ipairs(getOrderedSlots(Base)) do
		connectSlot(Slot, BaseTrove)
	end

	for _, Descendant in ipairs(Base:GetDescendants()) do
		if Descendant:IsA("ProximityPrompt") then
			connectPrompt(Descendant, BaseTrove)
		end
	end

	scheduleRefresh()
end

function BaseController.Init(Controllers)
	PlayerController = Controllers.PlayerController
end

function BaseController.Start()
	if Started then return end
	Started = true

	ScriptTrove:Add(ChangedEvent)

	if PlayerController and PlayerController.EquippedAnimeChanged then
		ScriptTrove:Connect(PlayerController.EquippedAnimeChanged, scheduleRefresh)
	end

	local BasesFolder = workspace:WaitForChild(BASES_FOLDER_NAME)
	ScriptTrove:Connect(BasesFolder.ChildAdded, function(Base)
		connectBase(Base)
		scheduleRefresh()
	end)
	ScriptTrove:Connect(BasesFolder.ChildRemoved, scheduleRefresh)

	for _, Base in ipairs(BasesFolder:GetChildren()) do
		connectBase(Base)
	end

	ScriptTrove:Connect(script.Destroying, function()
		ScriptTrove:Destroy()
	end)
end

function BaseController.GetOwnedBase()
	return OwnedBase
end

function BaseController.GetOwnedSlots()
	if not OwnedBase then return {} end

	return getOrderedSlots(OwnedBase)
end

function BaseController.GetUnlockedSlotCount()
	if not OwnedBase then return 0 end

	return getUnlockedSlotCount(OwnedBase)
end

function BaseController.RefreshPrompts()
	scheduleRefresh()
end

return BaseController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))

local PlayerController = {}

local LOCAL_PLAYER = Players.LocalPlayer

local ScriptTrove = Trove.new()
local CharacterTrove = nil
local PlayerTroves = {}
local EquippedAnimeChangedEvent = Instance.new("BindableEvent")
local RefreshQueued = false
local HasEquippedAnime = false
local Started = false

PlayerController.EquippedAnimeChanged = EquippedAnimeChangedEvent.Event

local function getEquippedAnimeTool()
	local Character = LOCAL_PLAYER.Character
	local Tool = Character and Character:FindFirstChildOfClass("Tool")

	if Tool and Tool:GetAttribute("InventoryId") then
		return Tool
	end

	return nil
end

local function setPromptEnabled(Prompt, Enabled)
	if Prompt and Prompt:IsA("ProximityPrompt") and Prompt.Enabled ~= Enabled then
		Prompt.Enabled = Enabled
	end
end

local function getGivePrompt(Player)
	local Character = Player.Character
	local PrimaryPart = Character and Character.PrimaryPart
	local Prompt = PrimaryPart and PrimaryPart:FindFirstChild("ProximityPrompt")

	if Prompt and Prompt:IsA("ProximityPrompt") then
		return Prompt
	end

	return nil
end

local function refreshGivePrompts()
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player == LOCAL_PLAYER then continue end

		setPromptEnabled(getGivePrompt(Player), HasEquippedAnime)
	end
end

local function refreshEquippedAnime()
	local NextHasEquippedAnime = getEquippedAnimeTool() ~= nil
	local Changed = NextHasEquippedAnime ~= HasEquippedAnime
	HasEquippedAnime = NextHasEquippedAnime

	refreshGivePrompts()

	if Changed then
		EquippedAnimeChangedEvent:Fire(HasEquippedAnime)
	end
end

local function scheduleRefresh()
	if RefreshQueued then return end
	RefreshQueued = true

	task.defer(function()
		RefreshQueued = false
		refreshEquippedAnime()
	end)
end

local function watchPromptParent(Parent, OwnerTrove)
	if not Parent then return end

	OwnerTrove:Connect(Parent.ChildAdded, scheduleRefresh)
	OwnerTrove:Connect(Parent.ChildRemoved, scheduleRefresh)
end

local function connectPlayerCharacter(Character, OwnerTrove)
	if not Character then
		scheduleRefresh()
		return
	end

	OwnerTrove:Connect(Character.ChildAdded, function(Child)
		watchPromptParent(Child, OwnerTrove)
		scheduleRefresh()
	end)
	OwnerTrove:Connect(Character.ChildRemoved, scheduleRefresh)

	if Character.PrimaryPart then
		watchPromptParent(Character.PrimaryPart, OwnerTrove)
	end

	for _, Child in ipairs(Character:GetChildren()) do
		watchPromptParent(Child, OwnerTrove)
	end

	task.defer(scheduleRefresh)
end

local function setLocalCharacter(Character)
	if CharacterTrove then
		CharacterTrove:Destroy()
		CharacterTrove = nil
	end

	if not Character then
		scheduleRefresh()
		return
	end

	CharacterTrove = ScriptTrove:Extend()
	connectPlayerCharacter(Character, CharacterTrove)
	CharacterTrove:Connect(Character.Destroying, function()
		if CharacterTrove then
			CharacterTrove:Destroy()
			CharacterTrove = nil
		end

		scheduleRefresh()
	end)
end

local function connectPlayer(Player)
	if Player == LOCAL_PLAYER or PlayerTroves[Player] then return end

	local PlayerTrove = ScriptTrove:Extend()
	PlayerTroves[Player] = PlayerTrove

	PlayerTrove:Add(function()
		PlayerTroves[Player] = nil
	end)

	PlayerTrove:Connect(Player.CharacterAdded, function(Character)
		connectPlayerCharacter(Character, PlayerTrove)
	end)

	if Player.Character then
		connectPlayerCharacter(Player.Character, PlayerTrove)
	end

	PlayerTrove:Connect(Player.Destroying, function()
		PlayerTrove:Destroy()
		scheduleRefresh()
	end)
end

function PlayerController.Init() end

function PlayerController.Start()
	if Started then return end
	Started = true

	ScriptTrove:Add(EquippedAnimeChangedEvent)

	ScriptTrove:Connect(Players.PlayerAdded, function(Player)
		connectPlayer(Player)
		scheduleRefresh()
	end)
	ScriptTrove:Connect(Players.PlayerRemoving, scheduleRefresh)

	for _, Player in ipairs(Players:GetPlayers()) do
		connectPlayer(Player)
	end

	ScriptTrove:Connect(LOCAL_PLAYER.CharacterAdded, setLocalCharacter)
	ScriptTrove:Connect(LOCAL_PLAYER.CharacterRemoving, function()
		setLocalCharacter(nil)
	end)

	if LOCAL_PLAYER.Character then
		setLocalCharacter(LOCAL_PLAYER.Character)
	else
		scheduleRefresh()
	end

	ScriptTrove:Connect(script.Destroying, function()
		ScriptTrove:Destroy()
	end)
end

function PlayerController.HasEquippedAnime()
	return HasEquippedAnime
end

function PlayerController.GetEquippedAnimeTool()
	return getEquippedAnimeTool()
end

function PlayerController.RefreshPrompts()
	scheduleRefresh()
end

return PlayerController

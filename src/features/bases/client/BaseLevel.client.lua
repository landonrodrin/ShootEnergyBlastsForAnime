local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
RequestController.Start()

local ScriptTrove = Trove.new()
local trovesByIdentifier = {}
local identifiersByGui = setmetatable({}, {__mode = "k"})

ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

local function disconnectIdentifier(Identifier)
	local IdentifierTrove = trovesByIdentifier[Identifier]
	if not IdentifierTrove then return end

	trovesByIdentifier[Identifier] = nil
	IdentifierTrove:Destroy()
end

ScriptTrove:Add(function()
	for Identifier in pairs(trovesByIdentifier) do
		disconnectIdentifier(Identifier)
	end
end)

local function disconnectGui(Gui)
	local Identifier = identifiersByGui[Gui]
	if not Identifier then return end

	disconnectIdentifier(Identifier)
	identifiersByGui[Gui] = nil
end

Packets.Listen(Packets.levelBind, function(Data)
	local Gui = Data.Gui
	local Identifier = Data.Identifier

	if Gui then
		disconnectGui(Gui)
	end

	if not Identifier then return end
	if not Gui then return end

	local Button = Gui:FindFirstChild("Level", true)
	if not Button or not Button:IsA("GuiButton") then return end

	disconnectIdentifier(Identifier)

	local IdentifierTrove = Trove.new()
	trovesByIdentifier[Identifier] = IdentifierTrove
	identifiersByGui[Gui] = Identifier

	IdentifierTrove:Add(function()
		if identifiersByGui[Gui] == Identifier then
			identifiersByGui[Gui] = nil
		end
	end)

	IdentifierTrove:Connect(Gui.Destroying, function()
		disconnectIdentifier(Identifier)
	end)

	IdentifierTrove:Connect(Button.Activated, function()
		RequestController.LevelRequest(Identifier)
	end)
end, ScriptTrove)

Packets.Listen(Packets.levelPurchased, function(Data)
	local Identifier = Data and Data.Identifier
	if Identifier then
		disconnectIdentifier(Identifier)
	end
end, ScriptTrove)

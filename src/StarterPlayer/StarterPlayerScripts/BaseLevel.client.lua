local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local LevelEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Level")

local trovesByIdentifier = {}
local identifiersByGui = setmetatable({}, {__mode = "k"})

local function disconnectIdentifier(Identifier)
	local IdentifierTrove = trovesByIdentifier[Identifier]
	if not IdentifierTrove then return end

	trovesByIdentifier[Identifier] = nil
	IdentifierTrove:Destroy()
end

local function disconnectGui(Gui)
	local Identifier = identifiersByGui[Gui]
	if not Identifier then return end

	disconnectIdentifier(Identifier)
	identifiersByGui[Gui] = nil
end

LevelEvent.OnClientEvent:Connect(function(Gui, Identifier, Purchased)
	if Purchased then
		if Identifier then
			disconnectIdentifier(Identifier)
		end
		return
	end

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
		LevelEvent:FireServer(Identifier)
	end)
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Level")

local connectionsByIdentifier = {}
local identifiersByGui = setmetatable({}, {__mode = "k"})

local function disconnectIdentifier(Identifier)
	local Connection = connectionsByIdentifier[Identifier]
	if not Connection then return end

	Connection:Disconnect()
	connectionsByIdentifier[Identifier] = nil
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

	connectionsByIdentifier[Identifier] = Button.Activated:Connect(function()
		LevelEvent:FireServer(Identifier)
	end)
	identifiersByGui[Gui] = Identifier
end)

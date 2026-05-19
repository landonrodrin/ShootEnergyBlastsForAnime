local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Level")

local connections = {}

local function disconnect(Gui)
	local Connection = connections[Gui]
	if not Connection then return end

	Connection:Disconnect()
	connections[Gui] = nil
end

LevelEvent.OnClientEvent:Connect(function(Gui, Identifier, Purchased)
	if Purchased then
		for ExistingGui in pairs(connections) do
			disconnect(ExistingGui)
		end
		return
	end

	if not Gui then return end

	disconnect(Gui)

	if not Identifier then return end

	local Button = Gui:FindFirstChild("Level", true)
	if not Button or not Button:IsA("GuiButton") then return end

	connections[Gui] = Button.Activated:Connect(function()
		LevelEvent:FireServer(Identifier)
	end)
end)

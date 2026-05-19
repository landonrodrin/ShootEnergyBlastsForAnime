local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = require(ReplicatedStorage.Modules:WaitForChild("Animations"))
local AnimeViewports = require(ReplicatedStorage.Modules:WaitForChild("AnimeViewports"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))

local IndexEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Index")

local IndexGui = script.Parent

local IndexFrame = IndexGui:WaitForChild("IndexFrame")
local IndexButton = IndexGui:WaitForChild("IndexButton")

IndexFrame.Header.Close.Activated:Connect(function()
	Animations.ToggleFrame(IndexFrame)
end)

IndexButton.Button.Activated:Connect(function()
	Animations.ToggleFrame(IndexFrame)

	for _, MutationFrame in pairs(IndexFrame.Mutations:GetChildren()) do
		if not MutationFrame:IsA("Frame") then continue end

		if MutationFrame.Mutation.BorderUIStroke.Color == Color3.fromRGB(0, 255, 0) then return end
	end

	IndexEvent:FireServer("Default")
end)

local function applyFallbackIcon(IconObject, Icon, IsUnlocked)
	if not (IconObject and (IconObject:IsA("ImageLabel") or IconObject:IsA("ImageButton"))) then return end

	IconObject.Image = Icon or ""
	IconObject.ImageColor3 = IsUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
end

local function Things(Index, Mutation, Override)
	local MutationConfiguration = MutationsConfigurations[Mutation]
	if not MutationConfiguration then return end

	for _, MutationFrame in pairs(IndexFrame.Mutations:GetChildren()) do
		if not MutationFrame:IsA("Frame") then continue end

		if MutationFrame.Name == Mutation then
			if not Override and MutationFrame.Mutation.BorderUIStroke.Color == Color3.fromRGB(0, 255, 0) then return end

			MutationFrame.Mutation.BorderUIStroke.Color = Color3.fromRGB(0, 255, 0)
		else
			MutationFrame.Mutation.BorderUIStroke.Color = Color3.fromRGB(0, 0, 0)
		end
	end

	local Colour = MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)

	for _, ThingFrame in pairs(IndexFrame.Things:GetChildren()) do
		if not ThingFrame:IsA("Frame") then continue end

		ThingFrame:Destroy()
	end

	for Thing, ThingConfiguration in pairs(ThingsConfigurations) do
		task.spawn(function()
			local Icon = ThingConfiguration.Icons and ThingConfiguration.Icons[Mutation]
			local IsUnlocked = Index[Mutation] and Index[Mutation][Thing] == true

			local ThingFrame = script:WaitForChild("Thing")
			ThingFrame = ThingFrame:Clone()

			local IconObject = ThingFrame:FindFirstChild("Icon")
			local Viewport = AnimeViewports.Mount(IconObject, Thing, Mutation, {
				Silhouette = not IsUnlocked
			})

			if not Viewport then
				applyFallbackIcon(IconObject, Icon, IsUnlocked)
			end

			ThingFrame.Area.Text = ThingConfiguration.Area
			ThingFrame.Area.TextColor3 = AreasConfigurations[ThingConfiguration.Area].Colour or Color3.fromRGB(255, 255, 255)

			ThingFrame.Mutation.Text = Mutation
			ThingFrame.Mutation.TextColor3 = Colour

			ThingFrame.Thing.Text = IsUnlocked and Thing or "?"

			ThingFrame.LayoutOrder = ThingConfiguration.Index or 0

			ThingFrame.Name = Thing
			ThingFrame.Parent = IndexFrame:WaitForChild("Things")
			ThingFrame.Visible = true
		end)
	end

	Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)

	IndexFrame.Header.Index.Text = string.format("Index | <font color=\"%s\">%s</font>", Colour, Mutation)
end

IndexEvent.OnClientEvent:Connect(function(Index, Mutation)
	local Override = false

	if not Mutation then
		Override = true

		for _, MutationFrame in pairs(IndexFrame.Mutations:GetChildren()) do
			if not MutationFrame:IsA("Frame") then continue end

			if MutationFrame.Mutation.BorderUIStroke.Color == Color3.fromRGB(0, 0, 0) then continue end

			Mutation = MutationFrame.Name
		end
	end

	if not Mutation then Mutation = "Default" end

	Things(Index, Mutation, Override)
end)

for Mutation, MutationConfiguration in pairs(MutationsConfigurations) do
	local MutationFrame = script:WaitForChild("Mutation")

	MutationFrame = MutationFrame:Clone()

	MutationFrame.Mutation.Text = Mutation

	MutationFrame.UIGradient.Color = MutationConfiguration.Gradient or ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(222, 222, 222)), ColorSequenceKeypoint.new(1, Color3.fromRGB(122, 122, 122))})

	MutationFrame.LayoutOrder = MutationConfiguration.Index or 0

	MutationFrame.Mutation.Activated:Connect(function()
		if MutationFrame.Mutation.BorderUIStroke.Color == Color3.fromRGB(0, 255, 0) then return end

		IndexEvent:FireServer(Mutation)
	end)

	MutationFrame.Name = Mutation
	MutationFrame.Parent = IndexFrame:WaitForChild("Mutations")
	MutationFrame.Visible = true
end

Animations.Frame(IndexFrame)
Animations.Button(IndexButton, IndexButton.Button)

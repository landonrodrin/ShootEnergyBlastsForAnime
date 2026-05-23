local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Animations = require(ReplicatedStorage.Modules:WaitForChild("Animations"))
local AnimeViewports = require(ReplicatedStorage.Modules:WaitForChild("AnimeViewports"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))
local AnimeConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AnimeConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))

local IndexEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Index")

local IndexGui = script.Parent

local IndexFrame = IndexGui:WaitForChild("IndexFrame")
local IndexButton = IndexGui:WaitForChild("IndexButton")
local ScriptTrove = Trove.new()
local RedrawTrove = Trove.new()
ScriptTrove:Add(RedrawTrove)

ScriptTrove:Connect(IndexFrame.Header.Close.Activated, function()
	Animations.ToggleFrame(IndexFrame)
end)

ScriptTrove:Connect(IndexButton.Button.Activated, function()
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

local function Anime(Index, Mutation, Override)
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

	RedrawTrove:Clean()
	local RedrawActive = true
	RedrawTrove:Add(function()
		RedrawActive = false
	end)

	for _, AnimeFrame in pairs(IndexFrame.Anime:GetChildren()) do
		if not AnimeFrame:IsA("Frame") then continue end

		AnimeFrame:Destroy()
	end

	for Anime, AnimeConfiguration in pairs(AnimeConfigurations) do
		RedrawTrove:Add(task.spawn(function()
			if not RedrawActive then return end

			local Icon = AnimeConfiguration.Icons and AnimeConfiguration.Icons[Mutation]
			local IsUnlocked = Index[Mutation] and Index[Mutation][Anime] == true

			local AnimeFrame = script:WaitForChild("Anime")
			AnimeFrame = AnimeFrame:Clone()
			local RowTrove = RedrawTrove:Extend()
			RowTrove:Add(AnimeFrame)

			local IconObject = AnimeFrame:FindFirstChild("Icon")
			local Viewport = AnimeViewports.Mount(IconObject, Anime, Mutation, {
				Silhouette = not IsUnlocked
			})

			if not Viewport then
				applyFallbackIcon(IconObject, Icon, IsUnlocked)
			else
				RowTrove:Add(Viewport)
			end

			AnimeFrame.Area.Text = AnimeConfiguration.Area
			AnimeFrame.Area.TextColor3 = AreasConfigurations[AnimeConfiguration.Area].Colour or Color3.fromRGB(255, 255, 255)

			AnimeFrame.Mutation.Text = Mutation
			AnimeFrame.Mutation.TextColor3 = Colour

			AnimeFrame.Anime.Text = IsUnlocked and Anime or "?"

			AnimeFrame.LayoutOrder = AnimeConfiguration.Index or 0

			if not RedrawActive then
				RowTrove:Destroy()
				return
			end

			AnimeFrame.Name = Anime
			AnimeFrame.Parent = IndexFrame:WaitForChild("Anime")
			AnimeFrame.Visible = true
		end))
	end

	Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)

	IndexFrame.Header.Index.Text = string.format("Index | <font color=\"%s\">%s</font>", Colour, Mutation)
end

ScriptTrove:Connect(IndexEvent.OnClientEvent, function(Index, Mutation)
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

	Anime(Index, Mutation, Override)
end)

for Mutation, MutationConfiguration in pairs(MutationsConfigurations) do
	local MutationFrame = script:WaitForChild("Mutation")

	MutationFrame = MutationFrame:Clone()
	ScriptTrove:Add(MutationFrame)

	MutationFrame.Mutation.Text = Mutation

	MutationFrame.UIGradient.Color = MutationConfiguration.Gradient or ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(222, 222, 222)), ColorSequenceKeypoint.new(1, Color3.fromRGB(122, 122, 122))})

	MutationFrame.LayoutOrder = MutationConfiguration.Index or 0

	ScriptTrove:Connect(MutationFrame.Mutation.Activated, function()
		if MutationFrame.Mutation.BorderUIStroke.Color == Color3.fromRGB(0, 255, 0) then return end

		IndexEvent:FireServer(Mutation)
	end)

	MutationFrame.Name = Mutation
	MutationFrame.Parent = IndexFrame:WaitForChild("Mutations")
	MutationFrame.Visible = true
end

Animations.Frame(IndexFrame)
Animations.Button(IndexButton, IndexButton.Button)

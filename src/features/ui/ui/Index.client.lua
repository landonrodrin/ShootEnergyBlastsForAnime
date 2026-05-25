local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local Animations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("Animations"))
local AnimeViewports = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeViewports"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
RequestController.Start()

local IndexGui = script.Parent

local IndexFrame = IndexGui:WaitForChild("IndexFrame")
local IndexButton = IndexGui:WaitForChild("IndexButton")
local ScriptTrove = Trove.new()
local RedrawTrove = Trove.new()
ScriptTrove:Add(RedrawTrove)
ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

ScriptTrove:Connect(IndexFrame.Header.Close.Activated, function()
	Animations.ToggleFrame(IndexFrame)
end)

ScriptTrove:Connect(IndexButton.Button.Activated, function()
	Animations.ToggleFrame(IndexFrame)

	for _, MutationFrame in pairs(IndexFrame.Mutations:GetChildren()) do
		if not MutationFrame:IsA("Frame") then continue end

		if MutationFrame.Mutation.BorderUIStroke.Color == Color3.fromRGB(0, 255, 0) then return end
	end

	RequestController.IndexRequest("Default")
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

	for AnimeName, AnimeConfiguration in pairs(AnimeConfigurations) do
		RedrawTrove:Add(task.spawn(function()
			if not RedrawActive then return end

			local Icon = AnimeConfiguration.Icons and AnimeConfiguration.Icons[Mutation]
			local IsUnlocked = Index[Mutation] and Index[Mutation][AnimeName] == true

			local AnimeFrame = script:WaitForChild("Anime")
			AnimeFrame = AnimeFrame:Clone()
			local RowTrove = RedrawTrove:Extend()
			RowTrove:Add(AnimeFrame)

			local IconObject = AnimeFrame:FindFirstChild("Icon")
			local Viewport = AnimeViewports.Mount(IconObject, AnimeName, Mutation, {
				Scale = 1.3,
				Silhouette = not IsUnlocked
			})

			if not Viewport then
				applyFallbackIcon(IconObject, Icon, IsUnlocked)
			else
				RowTrove:Add(Viewport)
			end

			AnimeFrame.Area.Text = AnimeConfiguration.Area
			AnimeFrame.Area.TextColor3 = AreasConfigurations[AnimeConfiguration.Area].Colour or Color3.fromRGB(255, 255, 255)

			AnimeFrame.Anime.Text = IsUnlocked and AnimeName or "?"

			AnimeFrame.LayoutOrder = AnimeConfiguration.Index or 0

			if not RedrawActive then
				RowTrove:Destroy()
				return
			end

			AnimeFrame.Name = AnimeName
			AnimeFrame.Parent = IndexFrame:WaitForChild("Anime")
			AnimeFrame.Visible = true
		end))
	end

	Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)

	IndexFrame.Header.Index.Text = string.format("Index | <font color=\"%s\">%s</font>", Colour, Mutation)
end

Packets.Listen(Packets.indexSync, function(Data)
	local Index = Data.Index
	local Mutation = Data.Mutation
	local Override = false

	if not Mutation then
		Override = true

		for _, MutationFrame in pairs(IndexFrame.Mutations:GetChildren()) do
			if not MutationFrame:IsA("Frame") then continue end

			if MutationFrame.Mutation.BorderUIStroke.Color == Color3.fromRGB(0, 0, 0) then continue end

			Mutation = MutationFrame.Name
		end
	end

	if not Mutation then
		Mutation = "Default"
	end

	Anime(Index, Mutation, Override)
end, ScriptTrove)

for Mutation, MutationConfiguration in pairs(MutationsConfigurations) do
	local MutationFrame = script:WaitForChild("Mutation")

	MutationFrame = MutationFrame:Clone()
	ScriptTrove:Add(MutationFrame)

	MutationFrame.Mutation.Text = Mutation

	MutationFrame.UIGradient.Color = MutationConfiguration.Gradient or ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(222, 222, 222)), ColorSequenceKeypoint.new(1, Color3.fromRGB(122, 122, 122))})

	MutationFrame.LayoutOrder = MutationConfiguration.Index or 0

	ScriptTrove:Connect(MutationFrame.Mutation.Activated, function()
		if MutationFrame.Mutation.BorderUIStroke.Color == Color3.fromRGB(0, 255, 0) then return end

		RequestController.IndexRequest(Mutation)
	end)

	MutationFrame.Name = Mutation
	MutationFrame.Parent = IndexFrame:WaitForChild("Mutations")
	MutationFrame.Visible = true
end

Animations.Frame(IndexFrame)
Animations.Button(IndexButton, IndexButton.Button)

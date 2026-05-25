local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local UiAssets = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiAssets"))
local ReactUi = require(script.Parent:WaitForChild("ReactUi"))
local RightRailButton = require(script.Parent:WaitForChild("RightRailButton"))
local ViewportPreview = require(script.Parent:WaitForChild("ViewportPreview"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))

local function sortedEntries(Source)
	local Entries = {}
	for Name, Configuration in pairs(Source) do
		table.insert(Entries, {
			Name = Name,
			Configuration = Configuration,
		})
	end

	table.sort(Entries, function(Left, Right)
		local LeftIndex = Left.Configuration.Index or 0
		local RightIndex = Right.Configuration.Index or 0
		if LeftIndex == RightIndex then
			return Left.Name < Right.Name
		end

		return LeftIndex < RightIndex
	end)

	return Entries
end

local MutationEntries = sortedEntries(MutationsConfigurations)
local AnimeEntries = sortedEntries(AnimeConfigurations)

local function IndexApp(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local SelectedMutation, SetSelectedMutation = React.useState("Default")
	local IndexData, SetIndexData = React.useState({})
	local Open = if Props.SetActivePanel then Props.ActivePanel == "Index" else LocalOpen

	local function setOpen(NextOpen)
		if Props.SetActivePanel then
			Props.SetActivePanel(if NextOpen then "Index" else nil)
		else
			SetLocalOpen(NextOpen)
		end
	end

	React.useEffect(function()
		local Connection = Packets.Listen(Packets.indexSync, function(Data)
			local NextIndex = Data.Index or {}
			local NextMutation = Data.Mutation or SelectedMutation or "Default"

			SetIndexData(NextIndex)
			SetSelectedMutation(NextMutation)
		end)

		RequestController.IndexRequest("Default")

		return function()
			Connection()
		end
	end, {})

	local MutationChildren = {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for _, Entry in ipairs(MutationEntries) do
		local Mutation = Entry.Name
		local Configuration = Entry.Configuration
		local Colour = Configuration.Colour or ReactUi.Colours.Accent

		MutationChildren[Mutation] = React.createElement(ReactUi.Button, {
			BackgroundColor3 = SelectedMutation == Mutation and Colour or ReactUi.Colours.PanelLight,
			LayoutOrder = Configuration.Index or 0,
			MaxTextSize = 22,
			OnActivated = function()
				SetSelectedMutation(Mutation)
				RequestController.IndexRequest(Mutation)
			end,
			Size = UDim2.fromOffset(132, 40),
			StrokeColor = Colour,
			Text = Mutation,
		})
	end

	local AnimeChildren = {
		Grid = React.createElement("UIGridLayout", {
			CellPadding = UDim2.fromOffset(10, 10),
			CellSize = UDim2.fromOffset(150, 178),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for _, Entry in ipairs(AnimeEntries) do
		local AnimeName = Entry.Name
		local Configuration = Entry.Configuration
		local IsUnlocked = IndexData[SelectedMutation] and IndexData[SelectedMutation][AnimeName] == true
		local AreaConfiguration = AreasConfigurations[Configuration.Area] or {}
		local Accent = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

		AnimeChildren[AnimeName] = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Color3.fromRGB(24, 27, 36),
			LayoutOrder = Configuration.Index or 0,
			Size = UDim2.fromOffset(150, 178),
			StrokeColor = IsUnlocked and Accent or Color3.fromRGB(86, 91, 108),
			StrokeTransparency = IsUnlocked and 0.15 or 0.45,
		}, {
			Preview = React.createElement(ViewportPreview, {
				AnimeName = AnimeName,
				BackgroundColor3 = Accent,
				BackgroundTransparency = IsUnlocked and 0.62 or 0.85,
				Mutation = SelectedMutation,
				Position = UDim2.fromOffset(25, 12),
				Scale = 1.3,
				Silhouette = not IsUnlocked,
				Size = UDim2.fromOffset(100, 92),
				StrokeColor = Accent,
			}),
			Name = React.createElement(ReactUi.Text, {
				Position = UDim2.fromOffset(12, 108),
				Size = UDim2.fromOffset(126, 34),
				Text = IsUnlocked and AnimeName or "?",
				TextScaled = true,
			}),
			Area = React.createElement(ReactUi.Text, {
				Position = UDim2.fromOffset(12, 142),
				Size = UDim2.fromOffset(126, 24),
				Text = Configuration.Area or "",
				TextColor3 = Accent,
				TextScaled = true,
				TextStrokeTransparency = 0.7,
			}),
		})
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Button = React.createElement(RightRailButton, {
			BackgroundColor3 = Color3.fromRGB(110, 116, 255),
			Icon = UiAssets.Icons.Index,
			OnActivated = function()
				local NextOpen = not Open
				if NextOpen then
					RequestController.IndexRequest(SelectedMutation)
				end
				setOpen(NextOpen)
			end,
			Row = 2,
			Text = "Index",
		}),
		Panel = React.createElement(ReactUi.Panel, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(0.72, 0.72),
			StrokeColor = Color3.fromRGB(110, 116, 255),
			StrokeThickness = 3,
			Visible = Open,
		}, {
			Header = React.createElement(ReactUi.Header, {
				OnClose = function()
					setOpen(false)
				end,
				Title = string.format("Index | %s", SelectedMutation),
			}),
			Mutations = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 72),
				Size = UDim2.new(1, -36, 0, 44),
			}, MutationChildren),
			Anime = React.createElement("ScrollingFrame", {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, 0),
				Position = UDim2.fromOffset(18, 126),
				ScrollBarThickness = 8,
				Size = UDim2.new(1, -36, 1, -144),
			}, AnimeChildren),
		}),
	})
end

return IndexApp

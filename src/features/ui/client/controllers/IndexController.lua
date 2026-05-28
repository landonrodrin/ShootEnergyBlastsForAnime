local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local IndexPanelView = require(script.Parent.Parent.Views:WaitForChild("IndexPanelView"))
local ReactUi = require(script.Parent.Parent.Views:WaitForChild("ReactUi"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
local GAMEPLAY_PANELS = UiTuning.GameplayPanels

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

local function IndexController(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local SelectedMutation, SetSelectedMutation = React.useState("Default")
	local IndexData, SetIndexData = React.useState({})
	local ActivePanelRef = React.useRef(Props.ActivePanel)
	local Open = if Props.SetActivePanel then Props.ActivePanel == "Index" else LocalOpen

	React.useEffect(function()
		ActivePanelRef.current = Props.ActivePanel

		return nil
	end, { Props.ActivePanel })

	local function closeIfActive()
		if Props.SetActivePanel then
			if ActivePanelRef.current == "Index" then
				Props.SetActivePanel(nil)
			end
		else
			SetLocalOpen(false)
		end
	end

	React.useEffect(function()
		local Connection = Packets.Listen(Packets.indexSync, function(Data)
			local NextIndex = Data.Index or {}
			local NextMutation = Data.Mutation or SelectedMutation or "Default"

			SetIndexData(NextIndex)
			SetSelectedMutation(NextMutation)
		end)

		return function()
			Connection()
		end
	end, {})

	React.useEffect(function()
		if Open then
			RequestController.IndexRequest(SelectedMutation)
		end

		return nil
	end, { Open })

	local MutationRows = {}
	for _, Entry in ipairs(MutationEntries) do
		local Configuration = Entry.Configuration
		table.insert(MutationRows, {
			Colour = Configuration.Colour or ReactUi.Colours.Accent,
			LayoutOrder = Configuration.Index or 0,
			Name = Entry.Name,
		})
	end

	local AnimeRows = {}
	for _, Entry in ipairs(AnimeEntries) do
		local Configuration = Entry.Configuration
		local AreaName = Configuration.Area or ""
		local AreaConfiguration = AreasConfigurations[AreaName] or {}
		local AnimeName = Entry.Name

		table.insert(AnimeRows, {
			Accent = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255),
			Area = AreaName,
			IsUnlocked = IndexData[SelectedMutation] and IndexData[SelectedMutation][AnimeName] == true,
			LayoutOrder = Configuration.Index or 0,
			Name = AnimeName,
		})
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Panel = React.createElement(IndexPanelView, {
			Anime = AnimeRows,
			Mutations = MutationRows,
			OnClose = function()
				closeIfActive()
			end,
			OnSelectMutation = function(Mutation)
				SetSelectedMutation(Mutation)
				RequestController.IndexRequest(Mutation)
			end,
			SelectedMutation = SelectedMutation,
			SharedTuning = GAMEPLAY_PANELS,
			Tuning = GAMEPLAY_PANELS.Index,
			Visible = Open,
		}),
	})
end

return IndexController

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))

local GenerateHeldPreviewTemplates = {}

local OUTPUT_FOLDER_NAME = "PreviewTemplates"
local ANIME_FOLDER_NAME = "Animes"
local RESOURCES_FOLDER_NAME = "Resources"
local DEFAULT_MUTATION = "Default"
local SUPPORTED_OPTIONS = {
	Anime = true,
	Animes = true,
	ClearUnselected = true,
	Mutation = true,
	Mutations = true,
}

local REMOVE_CLASSES = {
	BillboardGui = true,
	ClickDetector = true,
	DragDetector = true,
	LocalScript = true,
	ModuleScript = true,
	ProximityPrompt = true,
	ScreenGui = true,
	Script = true,
	SurfaceGui = true,
	TouchTransmitter = true,
}

local REMOVE_NAMES = {
	AnimeGui = true,
	CarriedAnimeWeld = true,
	ClientHeldAnimeWeld = true,
	HeldAnimeWeld = true,
	MutationAura = true,
	MutationAuraAttachment = true,
	MutationAuraLight = true,
	MutationHighlight = true,
	ViewportMutationAura = true,
	ViewportMutationAuraAttachment = true,
	ViewportMutationAuraLight = true,
	ViewportMutationHighlight = true,
}

local function getOrCreateFolder(Parent, Name)
	local Folder = Parent:FindFirstChild(Name)
	if Folder then return Folder end

	Folder = Instance.new("Folder")
	Folder.Name = Name
	Folder.Parent = Parent

	return Folder
end

local function addFilterValues(Lookup, Values)
	if Values == nil then return end

	if type(Values) == "string" then
		Lookup[Values] = true
	elseif type(Values) == "table" then
		for _, Value in ipairs(Values) do
			if type(Value) == "string" then
				Lookup[Value] = true
			end
		end
	end
end

local function normalizeFilterList(...)
	local Lookup = {}
	local HasValues = false

	for _, Values in ipairs({...}) do
		if Values ~= nil then
			HasValues = true
			addFilterValues(Lookup, Values)
		end
	end

	if not HasValues then return nil end

	return Lookup
end

local function getSortedKeys(Dictionary)
	local Keys = {}
	for Key in pairs(Dictionary) do
		table.insert(Keys, Key)
	end
	table.sort(Keys)
	return Keys
end

local function formatSelection(Filter, AllLabel)
	if not Filter then return AllLabel end

	local Values = getSortedKeys(Filter)
	if #Values == 0 then return "none" end

	return table.concat(Values, ", ")
end

local function warnUnsupportedOptions(Options, Missing)
	for OptionName in pairs(Options) do
		if not SUPPORTED_OPTIONS[OptionName] then
			table.insert(Missing, string.format("unsupported option %q", OptionName))
		end
	end
end

local function findAnimeTemplate(Animes, Area, AnimeName, Mutation)
	local MutationFolder = Animes and Animes:FindFirstChild(Mutation)
	local AreaFolder = MutationFolder and MutationFolder:FindFirstChild(Area)
	local Template = AreaFolder and AreaFolder:FindFirstChild(AnimeName)
	if Template then return Template end

	return MutationFolder and MutationFolder:FindFirstChild(AnimeName)
end

local function findBaseAnimeTemplate(Animes, Area, AnimeName)
	local DefaultTemplate = findAnimeTemplate(Animes, Area, AnimeName, DEFAULT_MUTATION)
	if DefaultTemplate then return DefaultTemplate end

	for Mutation in pairs(MutationsConfigurations) do
		local Template = findAnimeTemplate(Animes, Area, AnimeName, Mutation)
		if Template then return Template end
	end
end

local function getModelPrimaryPart(Model)
	if Model.PrimaryPart then return Model.PrimaryPart end

	local PrimaryPart = Model:FindFirstChild("HumanoidRootPart") or Model:FindFirstChildWhichIsA("BasePart", true)
	if PrimaryPart then
		Model.PrimaryPart = PrimaryPart
	end

	return PrimaryPart
end

local function shouldRemoveDescendant(Descendant)
	return REMOVE_CLASSES[Descendant.ClassName] == true or REMOVE_NAMES[Descendant.Name] == true
end

local function sanitizeModel(Model)
	for _, Descendant in ipairs(Model:GetDescendants()) do
		if shouldRemoveDescendant(Descendant) then
			Descendant:Destroy()
		end
	end

	for _, Descendant in ipairs(Model:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		Descendant.Anchored = false
		Descendant.CanCollide = false
		Descendant.CanTouch = false
		Descendant.CanQuery = false
		Descendant.Massless = true
	end
end

local function addTemplate(SourceTemplate, ParentFolder, AnimeName, Area, Mutation, RunMode)
	if not SourceTemplate:IsA("Model") then
		return false, string.format("source for %s/%s/%s is %s, expected Model", Mutation, Area, AnimeName, SourceTemplate.ClassName)
	end

	local Template = SourceTemplate:Clone()
	Template.Name = AnimeName
	sanitizeModel(Template)

	if not getModelPrimaryPart(Template) then
		Template:Destroy()
		return false, string.format("template for %s/%s/%s has no PrimaryPart or BasePart", Mutation, Area, AnimeName)
	end

	local Existing = ParentFolder:FindFirstChild(AnimeName)
	if Existing then
		Existing:Destroy()
	end

	Template:SetAttribute("GeneratedAnime", AnimeName)
	Template:SetAttribute("GeneratedArea", Area)
	Template:SetAttribute("GeneratedMutation", Mutation)
	Template:SetAttribute("GeneratedAt", os.time())
	Template:SetAttribute("GeneratedRunMode", RunMode)
	Template.Parent = ParentFolder
	return true
end

local function copyAnimeGui(ResourcesFolder)
	local AnimeResources = ServerStorage.Features.Anime.Server:WaitForChild("Resources")
	local SourceGui = AnimeResources:FindFirstChild("AnimeGui")
	if not (SourceGui and SourceGui:IsA("BillboardGui")) then
		warn("Missing ServerStorage.Features.Anime.Server.Resources.AnimeGui; held preview UI resource was not generated.")
		return false
	end

	local Existing = ResourcesFolder:FindFirstChild("AnimeGui")
	if Existing then
		Existing:Destroy()
	end

	local Gui = SourceGui:Clone()
	Gui.Name = "AnimeGui"
	Gui.Enabled = false
	Gui.Parent = ResourcesFolder
	return true
end

local function clearUnselectedTemplates(ParentFolder, AnimeFilter)
	if not AnimeFilter then return end

	for _, ExistingTemplate in ipairs(ParentFolder:GetChildren()) do
		if not ExistingTemplate:IsA("Model") then continue end
		if AnimeFilter[ExistingTemplate.Name] then continue end

		ExistingTemplate:Destroy()
	end
end

function GenerateHeldPreviewTemplates.Run(Options)
	assert(RunService:IsStudio(), "GenerateHeldPreviewTemplates can only be run in Roblox Studio.")

	Options = Options or {}
	local AnimeFilter = normalizeFilterList(Options.Anime, Options.Animes)
	local MutationFilter = normalizeFilterList(Options.Mutation, Options.Mutations)
	local IsFiltered = AnimeFilter ~= nil or MutationFilter ~= nil
	local RunMode = IsFiltered and "filtered" or "full"

	local SourceAnimes = ServerStorage:FindFirstChild("Animes")
	if not SourceAnimes then
		warn("Missing ServerStorage.Animes; held preview templates were not generated.")
		return nil
	end

	local Missing = {}
	warnUnsupportedOptions(Options, Missing)

	if AnimeFilter then
		for AnimeName in pairs(AnimeFilter) do
			if not AnimeConfigurations[AnimeName] then
				table.insert(Missing, string.format("unknown anime %q", AnimeName))
			end
		end
	end

	if MutationFilter then
		for Mutation in pairs(MutationFilter) do
			if not MutationsConfigurations[Mutation] then
				table.insert(Missing, string.format("unknown mutation %q", Mutation))
			end
		end
	end

	local Existing = ReplicatedStorage:FindFirstChild(OUTPUT_FOLDER_NAME)
	if Existing and not IsFiltered then
		Existing:Destroy()
		Existing = nil
	end

	local OutputFolder = Existing
	if not OutputFolder then
		OutputFolder = Instance.new("Folder")
		OutputFolder.Name = OUTPUT_FOLDER_NAME
		OutputFolder.Parent = ReplicatedStorage
	end

	local AnimesFolder = getOrCreateFolder(OutputFolder, ANIME_FOLDER_NAME)
	local ResourcesFolder = getOrCreateFolder(OutputFolder, RESOURCES_FOLDER_NAME)

	if not copyAnimeGui(ResourcesFolder) then
		table.insert(Missing, "missing AnimeGui resource")
	end

	local Generated = 0
	local ReplacedPaths = {}

	for _, AnimeName in ipairs(getSortedKeys(AnimeConfigurations)) do
		if AnimeFilter and not AnimeFilter[AnimeName] then continue end

		local AnimeConfiguration = AnimeConfigurations[AnimeName]
		local Area = AnimeConfiguration.Area

		if not MutationFilter or MutationFilter[DEFAULT_MUTATION] then
			local AreaFolder = getOrCreateFolder(AnimesFolder, Area)
			if IsFiltered and Options.ClearUnselected == true then
				clearUnselectedTemplates(AreaFolder, AnimeFilter)
			end

			local SourceTemplate = findBaseAnimeTemplate(SourceAnimes, Area, AnimeName)
			if SourceTemplate then
				local Added, Reason = addTemplate(SourceTemplate, AreaFolder, AnimeName, Area, DEFAULT_MUTATION, RunMode)
				if Added then
					Generated += 1
					table.insert(ReplacedPaths, string.format("%s/%s", Area, AnimeName))
				else
					table.insert(Missing, Reason)
				end
			else
				table.insert(Missing, string.format("missing source for %s/%s", tostring(Area), AnimeName))
			end
		end

		for _, Mutation in ipairs(getSortedKeys(MutationsConfigurations)) do
			if Mutation == DEFAULT_MUTATION then continue end
			if MutationFilter and not MutationFilter[Mutation] then continue end

			local MutationTemplate = findAnimeTemplate(SourceAnimes, Area, AnimeName, Mutation)
			if not MutationTemplate then
				if MutationFilter then
					table.insert(Missing, string.format("missing source for %s/%s/%s", Mutation, tostring(Area), AnimeName))
				end
				continue
			end

			local MutationFolder = getOrCreateFolder(AnimesFolder, Mutation)
			local MutationAreaFolder = getOrCreateFolder(MutationFolder, Area)
			if IsFiltered and Options.ClearUnselected == true then
				clearUnselectedTemplates(MutationAreaFolder, AnimeFilter)
			end

			local Added, Reason = addTemplate(MutationTemplate, MutationAreaFolder, AnimeName, Area, Mutation, RunMode)
			if Added then
				Generated += 1
				table.insert(ReplacedPaths, string.format("%s/%s/%s", Mutation, Area, AnimeName))
			else
				table.insert(Missing, Reason)
			end
		end
	end

	if #Missing > 0 then
		warn(string.format(
			"Held preview template generation skipped %d item(s): %s",
			#Missing,
			table.concat(Missing, "; ")
		))
	end

	print(string.format(
		"Generated %d held anime preview template(s) in ReplicatedStorage.%s (%s; anime: %s; mutations: %s).",
		Generated,
		OUTPUT_FOLDER_NAME,
		RunMode,
		formatSelection(AnimeFilter, "all"),
		formatSelection(MutationFilter, "all")
	))

	if IsFiltered and Options.ClearUnselected ~= true then
		print("Preserved existing unselected preview templates.")
	end

	if #ReplacedPaths > 0 then
		print(string.format("Replaced preview template(s): %s", table.concat(ReplacedPaths, ", ")))
	end

	return OutputFolder
end

return GenerateHeldPreviewTemplates

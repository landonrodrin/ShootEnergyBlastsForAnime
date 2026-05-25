local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeConfigurations"))

local PreviewTemplates = {}

local OUTPUT_FOLDER_NAME = "PreviewTemplates"
local ANIME_FOLDER_NAME = "Animes"
local RESOURCES_FOLDER_NAME = "Resources"
local ANIME_GUI_NAME = "AnimeGui"

local function getPreviewTemplatesFolder()
	return ReplicatedStorage:FindFirstChild(OUTPUT_FOLDER_NAME)
end

local function getAnimeTemplatesFolder()
	local PreviewTemplatesFolder = getPreviewTemplatesFolder()
	return PreviewTemplatesFolder and PreviewTemplatesFolder:FindFirstChild(ANIME_FOLDER_NAME)
end

local function getResourcesFolder()
	local PreviewTemplatesFolder = getPreviewTemplatesFolder()
	return PreviewTemplatesFolder and PreviewTemplatesFolder:FindFirstChild(RESOURCES_FOLDER_NAME)
end

local function findPreviewTemplate(AnimeTemplates, Area, AnimeName)
	local AreaFolder = AnimeTemplates and AnimeTemplates:FindFirstChild(Area)
	local Template = AreaFolder and AreaFolder:FindFirstChild(AnimeName)
	if Template then return Template end

	local DefaultFolder = AnimeTemplates and AnimeTemplates:FindFirstChild("Default")
	local DefaultAreaFolder = DefaultFolder and DefaultFolder:FindFirstChild(Area)
	return DefaultAreaFolder and DefaultAreaFolder:FindFirstChild(AnimeName)
end

function PreviewTemplates.GetAnimeTemplatesFolder()
	return getAnimeTemplatesFolder()
end

function PreviewTemplates.GetResourcesFolder()
	return getResourcesFolder()
end

function PreviewTemplates.ValidateAnimeTemplates()
	local PreviewTemplatesFolder = getPreviewTemplatesFolder()
	if not PreviewTemplatesFolder then
		warn("Missing ReplicatedStorage.PreviewTemplates; run GenerateHeldPreviewTemplates in Studio before playtesting held previews.")
		return false
	end

	local AnimeTemplates = getAnimeTemplatesFolder()
	local Resources = getResourcesFolder()
	local AnimeGui = Resources and Resources:FindFirstChild(ANIME_GUI_NAME)
	local Valid = true

	if not AnimeTemplates then
		warn("Missing ReplicatedStorage.PreviewTemplates.Animes; run GenerateHeldPreviewTemplates in Studio.")
		Valid = false
	end

	if not (AnimeGui and AnimeGui:IsA("BillboardGui")) then
		warn("Missing ReplicatedStorage.PreviewTemplates.Resources.AnimeGui; run GenerateHeldPreviewTemplates in Studio.")
		Valid = false
	end

	if not AnimeTemplates then
		return false
	end

	local Missing = {}
	for AnimeName, AnimeConfiguration in pairs(AnimeConfigurations) do
		local Area = AnimeConfiguration.Area
		local Template = findPreviewTemplate(AnimeTemplates, Area, AnimeName)

		if not Template then
			table.insert(Missing, string.format("%s/%s", tostring(Area), AnimeName))
		end
	end

	if #Missing > 0 then
		warn(string.format(
			"Missing %d held preview template(s) under ReplicatedStorage.PreviewTemplates.Animes: %s",
			#Missing,
			table.concat(Missing, ", ")
		))
		Valid = false
	end

	return Valid
end

return PreviewTemplates

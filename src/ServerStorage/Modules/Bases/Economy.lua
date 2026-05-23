return function(ctx)
	local MarketplaceService = ctx.MarketplaceService
	local Players = ctx.Players
	local HttpService = ctx.HttpService
	local SetProperties = ctx.SetProperties
	local Grounding = ctx.Grounding
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local BaseConfigurations = ctx.BaseConfigurations
	local AreasConfigurations = ctx.AreasConfigurations
	local AnimeConfigurations = ctx.AnimeConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RebirthsConfigurations = ctx.RebirthsConfigurations
	local RetrieveAnimeDataFunction = ctx.RetrieveAnimeDataFunction
	local CreateAnimeFunction = ctx.CreateAnimeFunction
	local RetrievePlayerDataFunction = ctx.RetrievePlayerDataFunction
	local AnimateAnimeEvent = ctx.AnimateAnimeEvent
	local ReplacePlayerDataEvent = ctx.ReplacePlayerDataEvent
	local CreateToolEvent = ctx.CreateToolEvent
	local LevelEvent = ctx.LevelEvent
	local AnnouncementEvent = ctx.AnnouncementEvent
	local BASE_GUI_MAX_DISTANCE = ctx.BASE_GUI_MAX_DISTANCE
	local BASE_LEVEL_BIND_DELAY = ctx.BASE_LEVEL_BIND_DELAY
	local BASE_SLOT_PROMPT_HOLD_DURATION = ctx.BASE_SLOT_PROMPT_HOLD_DURATION
	local BASE_SLOT_PLACE_PROMPT_MAX_ACTIVATION_DISTANCE = ctx.BASE_SLOT_PLACE_PROMPT_MAX_ACTIVATION_DISTANCE
	local BASE_LEVEL_NAME = ctx.BASE_LEVEL_NAME
	local BASE_INFO_GUI_NAME = ctx.BASE_INFO_GUI_NAME
	local BASE_INFO_ANCHOR_NAME = ctx.BASE_INFO_ANCHOR_NAME
	local FLOORS_FOLDER_NAME = ctx.FLOORS_FOLDER_NAME
	local SLOTS_FOLDER_NAME = ctx.SLOTS_FOLDER_NAME
	local SLOT_SPAWN_NAME = ctx.SLOT_SPAWN_NAME
	local SLOT_LEVEL_NAME = ctx.SLOT_LEVEL_NAME
	local SLOT_MONEY_NAME = ctx.SLOT_MONEY_NAME
	local PICK_UP_PROMPT_TEXT = ctx.PICK_UP_PROMPT_TEXT
	local INSUFFICIENT_FUNDS_TEXT = ctx.INSUFFICIENT_FUNDS_TEXT
	local INSUFFICIENT_FUNDS_COLOUR = ctx.INSUFFICIENT_FUNDS_COLOUR
	local BasesData = ctx.BasesData
	local Bases = ctx.Bases
	local getOrderedSlots = ctx.getOrderedSlots
	local getOrderedFloors = ctx.getOrderedFloors
	local getSlotByName = ctx.getSlotByName
	local getSlotSpawn = ctx.getSlotSpawn
	local getSlotLevel = ctx.getSlotLevel
	local getSlotMoney = ctx.getSlotMoney
	local getSlotAttachment = ctx.getSlotAttachment
	local getBaseLevelPart = ctx.getBaseLevelPart
	local getUnlockedSlots = ctx.getUnlockedSlots
	local setSlotLevelVisible = ctx.setSlotLevelVisible
	local getPlayerRebirthMultiplier = ctx.getPlayerRebirthMultiplier
	local getBaseSellValue = ctx.getBaseSellValue
	local updateBaseAnimeMoneyText = ctx.updateBaseAnimeMoneyText
	local updateBaseSlotSellPrompt = ctx.updateBaseSlotSellPrompt
	local updateBaseInfoMoneyPerSecond = ctx.updateBaseInfoMoneyPerSecond
	local createBaseInfoGui = ctx.createBaseInfoGui
	local removeLegacyBaseInfoGuis = ctx.removeLegacyBaseInfoGuis
	local removeBaseLevelGuis = ctx.removeBaseLevelGuis
local function getPlayerRebirthMultiplier(Player)
	local Rebirths = RetrievePlayerDataFunction:Invoke(Player, "Rebirths") or 0
	local RebirthConfiguration = RebirthsConfigurations[Rebirths]
	return RebirthConfiguration and RebirthConfiguration.Multiplier or 1
end

local function getBaseIncomeValue(AnimeConfiguration, Level, Mutation, RebirthMultiplier)
	local LevelConfiguration = AnimeConfiguration and AnimeConfiguration.Levels and AnimeConfiguration.Levels[Level]
	if not LevelConfiguration then return 0 end

	local MutationConfiguration = MutationsConfigurations[Mutation] or {}
	local Multiplier = MutationConfiguration.Multiplier or 1
	RebirthMultiplier = RebirthMultiplier or 1

	return (LevelConfiguration.Money or 0) * Multiplier * RebirthMultiplier
end

local function getBaseSellValue(AnimeConfiguration, Level, Mutation, RebirthMultiplier)
	return math.round(getBaseIncomeValue(AnimeConfiguration, Level, Mutation, RebirthMultiplier) / 2)
end

local function getBaseSellPromptText(AnimeConfiguration, Level, Mutation, RebirthMultiplier)
	local Sell = getBaseSellValue(AnimeConfiguration, Level, Mutation, RebirthMultiplier)

	return string.format("Sell: $%s", Format.Number(Sell))
end

local function getAnimeGui(Anime)
	local PrimaryPart = Anime and Anime.PrimaryPart
	local AnimeAttachment = PrimaryPart and PrimaryPart:FindFirstChild("AnimeAttachment")
	return AnimeAttachment and AnimeAttachment:FindFirstChild("AnimeGui")
end
local function updateBaseAnimeMoneyText(Anime, AnimeConfiguration, Level, Mutation, RebirthMultiplier)
	local AnimeGui = getAnimeGui(Anime)
	if not (AnimeGui and AnimeGui:FindFirstChild("Money")) then return end

	local Money = getBaseIncomeValue(AnimeConfiguration, Level, Mutation, RebirthMultiplier)
	AnimeGui.Money.Text = string.format("$%s/s", Format.Number(Money))
	AnimeGui.Money.Visible = true
end

local function updateBaseSlotSellPrompt(Slot, AnimeConfiguration, Level, Mutation, RebirthMultiplier)
	local Attachment = getSlotAttachment(Slot)
	local SellProximityPrompt = Attachment and Attachment:FindFirstChild("SellProximityPrompt")
	if not SellProximityPrompt then return end

	SellProximityPrompt.ActionText = getBaseSellPromptText(AnimeConfiguration, Level, Mutation, RebirthMultiplier)
end

local function setSlotLevelVisible(Slot, Visible)
	local LevelPart = getSlotLevel(Slot)
	if not (LevelPart and LevelPart:IsA("BasePart")) then return end

	if Visible then
		local Transparency = LevelPart:GetAttribute("Transparency")
		if Transparency ~= nil then
			LevelPart.Transparency = Transparency
		end
	elseif LevelPart.Transparency < 1 then
		LevelPart:SetAttribute("Transparency", LevelPart.Transparency)
		LevelPart.Transparency = 1
	end
end
	ctx.getPlayerRebirthMultiplier = getPlayerRebirthMultiplier
	ctx.getBaseIncomeValue = getBaseIncomeValue
	ctx.getBaseSellValue = getBaseSellValue
	ctx.getBaseSellPromptText = getBaseSellPromptText
	ctx.getAnimeGui = getAnimeGui
	ctx.updateBaseAnimeMoneyText = updateBaseAnimeMoneyText
	ctx.updateBaseSlotSellPrompt = updateBaseSlotSellPrompt
	ctx.setSlotLevelVisible = setSlotLevelVisible
end

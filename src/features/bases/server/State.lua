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
function Bases.Retrieve(Base, Name)
	if not BasesData[Base] then return end

	if Name then
		return BasesData[Base][Name]
	else
		return BasesData[Base]
	end
end
end

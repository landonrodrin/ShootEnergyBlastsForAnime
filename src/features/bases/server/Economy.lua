return function(ctx)
	local Format = ctx.Format
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RebirthsConfigurations = ctx.RebirthsConfigurations
	local RetrievePlayerDataFunction = ctx.RetrievePlayerDataFunction
	local getSlotLevel = ctx.getSlotLevel
	local getSlotAttachment = ctx.getSlotAttachment
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

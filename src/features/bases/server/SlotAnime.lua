return function(ctx)
	local Players = ctx.Players
	local HttpService = ctx.HttpService
	local SetProperties = ctx.SetProperties
	local Grounding = ctx.Grounding
	local Trove = ctx.Trove
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local AreasConfigurations = ctx.AreasConfigurations
	local AnimeConfigurations = ctx.AnimeConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RetrieveAnimeDataFunction = ctx.RetrieveAnimeDataFunction
	local CreateAnimeFunction = ctx.CreateAnimeFunction
	local RetrievePlayerDataFunction = ctx.RetrievePlayerDataFunction
	local AnimateAnimeEvent = ctx.AnimateAnimeEvent
	local ReplacePlayerDataEvent = ctx.ReplacePlayerDataEvent
	local Packets = ctx.Packets
	local registerLevelRequest = ctx.registerLevelRequest
	local BASE_GUI_MAX_DISTANCE = ctx.BASE_GUI_MAX_DISTANCE
	local BASE_INFO_GUI_NAME = ctx.BASE_INFO_GUI_NAME
	local BASE_INFO_ANCHOR_NAME = ctx.BASE_INFO_ANCHOR_NAME
	local PICK_UP_PROMPT_TEXT = ctx.PICK_UP_PROMPT_TEXT
	local BasesData = ctx.BasesData
	local Bases = ctx.Bases
	local getOrderedSlots = ctx.getOrderedSlots
	local getSlotByName = ctx.getSlotByName
	local getSlotSpawn = ctx.getSlotSpawn
	local getSlotLevel = ctx.getSlotLevel
	local getSlotMoney = ctx.getSlotMoney
	local getSlotAttachment = ctx.getSlotAttachment
	local getUnlockedSlots = ctx.getUnlockedSlots
	local setSlotLevelVisible = ctx.setSlotLevelVisible
	local getPlayerRebirthMultiplier = ctx.getPlayerRebirthMultiplier
	local getPlayerPassiveIncomeMultiplier = ctx.getPlayerPassiveIncomeMultiplier
	local updateBaseAnimeMoneyText = ctx.updateBaseAnimeMoneyText
	local updateBaseSlotSellPrompt = ctx.updateBaseSlotSellPrompt
	local updateBaseInfoMoneyPerSecond = ctx.updateBaseInfoMoneyPerSecond
	local createBaseInfoGui = ctx.createBaseInfoGui
	local removeLegacyBaseInfoGuis = ctx.removeLegacyBaseInfoGuis
	local removeBaseLevelGuis = ctx.removeBaseLevelGuis

local function addOwnedDelay(OwnerTrove, Delay, Callback)
	local Thread = task.delay(Delay, Callback)
	if OwnerTrove then
		OwnerTrove:Add(Thread)
	end
	return Thread
end

local function refreshOccupiedSlotPrompts(Player, Base, Slot, Anime, AnimeConfiguration, Level, Mutation, RebirthMultiplier, OwnerTrove)
	local ApplyOccupiedSlotPromptState = ctx.applyOccupiedSlotPromptState
	if ApplyOccupiedSlotPromptState and ApplyOccupiedSlotPromptState(Player, Slot, AnimeConfiguration, Level, Mutation, RebirthMultiplier) then
		return true
	end

	addOwnedDelay(OwnerTrove, 0.25, function()
		local SlotData = BasesData[Base] and BasesData[Base].SlotsData[Slot.Name]
		if not SlotData or SlotData.Anime ~= Anime then return end

		local RetryApply = ctx.applyOccupiedSlotPromptState
		if RetryApply and RetryApply(Player, Slot, AnimeConfiguration, Level, Mutation, RebirthMultiplier) then
			return
		end

		addOwnedDelay(OwnerTrove, 1, function()
			local CurrentSlotData = BasesData[Base] and BasesData[Base].SlotsData[Slot.Name]
			if not CurrentSlotData or CurrentSlotData.Anime ~= Anime then return end

			local FinalApply = ctx.applyOccupiedSlotPromptState
			if FinalApply and FinalApply(Player, Slot, AnimeConfiguration, Level, Mutation, RebirthMultiplier) then
				return
			end

			warn(string.format("Unable to refresh occupied slot prompts for Base%s Slot%s.", Base.Name, Slot.Name))
		end)
	end)

	return false
end

local function refreshPlayerEconomy(Player, Base)
	if not BasesData[Base] or not Player then return end

	local MoneyPerSecond = 0

	for _, SlotData in pairs(BasesData[Base].SlotsData or {}) do
		local Anime = SlotData.Anime
		if not Anime then continue end

		local Name = Anime.Name
		local AnimeConfiguration = AnimeConfigurations[Name]
		if not AnimeConfiguration then continue end

		local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")
		local MutationConfiguration = MutationsConfigurations[Mutation] or {}
		local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level") or 1
		local LevelConfiguration = AnimeConfiguration.Levels[Level]
		if not LevelConfiguration then continue end

		local Multiplier = MutationConfiguration.Multiplier or 1

		MoneyPerSecond += LevelConfiguration.Money * Multiplier
	end

	MoneyPerSecond = MoneyPerSecond * getPlayerPassiveIncomeMultiplier(Player)

	ReplacePlayerDataEvent:Fire(Player, "MoneyPerSecond", MoneyPerSecond)

	updateBaseInfoMoneyPerSecond(Base, MoneyPerSecond)
end

local function scheduleEconomyRefresh(Player, Base, OwnerTrove)
	refreshPlayerEconomy(Player, Base)

	addOwnedDelay(OwnerTrove, 1, function()
		refreshPlayerEconomy(Player, Base)
	end)

	addOwnedDelay(OwnerTrove, 5, function()
		refreshPlayerEconomy(Player, Base)
	end)
end

function Bases.Create(PlayerData)
	local Player = PlayerData.Player

	local Data = setmetatable({}, {__index = Bases})

	Data.Player = Player
	Data.Trove = Trove.new()

	local Base

	for Index = 1, #workspace.Bases:GetChildren() do
		local PossibleBase = workspace.Bases[Index]
		local PossibleData = BasesData[PossibleBase]

		if PossibleData then continue end

		Base = PossibleBase

		break
	end

	Data.Base = Base
	Data.SlotsData = {}

	if Base then
		Base:SetAttribute("OwnerUserId", Player.UserId)
		Base:SetAttribute("Level", PlayerData.Level or 1)

		for _, Slot in ipairs(getOrderedSlots(Base)) do
			Slot:SetAttribute("Occupied", false)
		end
	end

	addOwnedDelay(Data.Trove, 1, function()
		Bases.Level(PlayerData, Base)
	end)

	addOwnedDelay(Data.Trove, 5, function()
		Bases.Level(PlayerData, Base)
	end)

	createBaseInfoGui(Player, Base)

	BasesData[Base] = Data

	for _, AnimeData in ipairs(PlayerData.Anime) do
		Data.Trove:Add(task.spawn(function()
			local Name = AnimeData.Name
			local Mutation = AnimeData.Mutation
			local Level = AnimeData.Level
			local Slot = AnimeData.Slot

			Slot = getSlotByName(Base, Slot)

			Bases.Add(Player, Base, Slot, Name, Mutation, Level)
		end))
	end

	addOwnedDelay(Data.Trove, 1, function()
		if BasesData[Base] and BasesData[Base].Player == Player then
			Bases.RefreshPlayerBasePrompts(Player)
		end
	end)

	return Data
end
function Bases.Add(Player, Base, Slot, Name, Mutation, Level, Money)
	local AnimeConfiguration = AnimeConfigurations[Name]

	local Area = AnimeConfiguration.Area

	local AreaConfiguration = AreasConfigurations[Area]
	local MutationConfiguration = MutationsConfigurations[Mutation]

	local BaseData = BasesData[Base]

	if not Slot then
		for _, PossibleSlot in ipairs(getOrderedSlots(Base)) do
			if BasesData[Base].SlotsData[PossibleSlot.Name] and BasesData[Base].SlotsData[PossibleSlot.Name].Anime then continue end

			if getUnlockedSlots(RetrievePlayerDataFunction:Invoke(Player, "Level")) < tonumber(PossibleSlot.Name) then continue end

			Slot = PossibleSlot

			break
		end

		if not Slot then
			local Text = string.format("Unable to find an available slot in Base%s!", Base.Name)

			Packets.announcement.sendTo({
				Text = Text,
				Colour = Packets.EncodeColour(Color3.fromRGB(255, 0, 0)),
			}, Player)

			return
		end
	end

	if BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Anime then return end
	if getUnlockedSlots(RetrievePlayerDataFunction:Invoke(Player, "Level")) < tonumber(Slot.Name) then return end

	local SlotSpawn = getSlotSpawn(Slot)
	local SlotMoney = getSlotMoney(Slot)
	local SlotLevel = getSlotLevel(Slot)
	if not (SlotSpawn and SlotSpawn:IsA("BasePart") and SlotMoney and SlotMoney:IsA("BasePart") and SlotLevel) then return end

	Money = Money or 0

	local Anime = CreateAnimeFunction:Invoke(Area, AreaConfiguration, Name, AnimeConfiguration, Mutation, MutationConfiguration, Level)

	local SavedAnime = RetrievePlayerDataFunction:Invoke(Player, "Anime")

	local AnimeEntry = {
		Name = Name,
		Mutation = Mutation,
		Level = Level,
		Slot = Slot.Name
	}

	local Exists = false
	for Index, Data in ipairs(SavedAnime) do
		if Data.Name ~= Anime.Name or Data.Mutation ~= Mutation or Data.Level ~= Level or Data.Slot ~= Slot.Name then continue end

		Exists = true
	end

	if not Exists then
		table.insert(SavedAnime, AnimeEntry)

		ReplacePlayerDataEvent:Fire(Player, "Anime", SavedAnime)
	end

	local SlotName = Slot.Name
	local SlotTrove = Trove.new()

	BasesData[Base].SlotsData[SlotName] = {
		Anime = Anime,
		Money = Money,
		Trove = SlotTrove
	}
	Slot:SetAttribute("Occupied", true)

	Anime.Parent = workspace

	local TargetCFrame = SlotSpawn.CFrame

	Anime:PivotTo(TargetCFrame)

	local RebirthMultiplier = getPlayerRebirthMultiplier(Player)
	local PassiveIncomeMultiplier = getPlayerPassiveIncomeMultiplier(Player)
	updateBaseAnimeMoneyText(Anime, AnimeConfiguration, Level, Mutation, PassiveIncomeMultiplier)

	AnimateAnimeEvent:Fire(Anime, AnimeConfiguration.AnimationsIds.Idle, true)
	Grounding.AlignBottomToSurfaceAfterAnimation(Anime, SlotSpawn, AnimeConfiguration, SlotTrove)

	local MoneyGui = ctx.Resources:WaitForChild("MoneyGui")

	MoneyGui = MoneyGui:Clone()

	MoneyGui.Money.Money.Text = string.format("$%s", Format.Number(Money))
	MoneyGui.MaxDistance = BASE_GUI_MAX_DISTANCE

	MoneyGui.Parent = SlotMoney
	MoneyGui.Enabled = true

	setSlotLevelVisible(Slot, true)

	local LevelGui = ctx.Resources:WaitForChild("LevelGui")

	LevelGui = LevelGui:Clone()
	LevelGui.LightInfluence = 0
	LevelGui.MaxDistance = BASE_GUI_MAX_DISTANCE
	LevelGui.Enabled = true

	if LevelGui.Level and LevelGui.Level:IsA("GuiObject") then
		LevelGui.Level.BackgroundTransparency = 0
	end

	local NextLevelConfiguration = AnimeConfiguration.Levels[Level + 1]

	if NextLevelConfiguration then
		LevelGui.Level.Money.Text = string.format("$%s", Format.Number(NextLevelConfiguration.Upgrade))
		LevelGui.Level.Level.Text = string.format("Lvl %s > Lvl %s", Level, Level + 1)

		LevelGui.Level.Money.Visible = true
		LevelGui.Level.Arrow.Visible = true
	else
		LevelGui.Level.Level.Text = string.format("Lvl %s (MAX)", Level)
	end

	LevelGui.Parent = SlotLevel

	SetProperties.Client(Player, LevelGui, {Enabled = true})

	if NextLevelConfiguration then
		local Identifier = HttpService:GenerateGUID(false)

		registerLevelRequest(Identifier, SlotTrove, function(EventPlayer)
			if EventPlayer ~= Player then return end

			local CurrentSlotData = BasesData[Base] and BasesData[Base].SlotsData[Slot.Name]
			if not CurrentSlotData or CurrentSlotData.Anime ~= Anime then return end

			local NextLevel = Level + 1

			if not AnimeConfiguration.Levels[NextLevel] then return end

			local UpgradeMoney = AnimeConfiguration.Levels[NextLevel].Upgrade

			if RetrievePlayerDataFunction:Invoke(Player, "Money") < UpgradeMoney then return end

			Packets.levelPurchased.sendTo({
				Identifier = Identifier,
			}, Player)

			ReplacePlayerDataEvent:Fire(Player, "Money", RetrievePlayerDataFunction:Invoke(Player, "Money") - UpgradeMoney)

			local SavedMoney = CurrentSlotData.Money

			Bases.Remove(Base, Slot)

			task.wait()

			Bases.Add(Player, Base, Slot, Name, Mutation, NextLevel, SavedMoney)
		end)

		local BindLevelGui = ctx.bindLevelGui
		if BindLevelGui then
			BindLevelGui(Player, LevelGui, Identifier, function()
				local CurrentSlotData = BasesData[Base] and BasesData[Base].SlotsData[Slot.Name]
				return CurrentSlotData and CurrentSlotData.Anime == Anime
			end, SlotTrove)
		else
			Packets.levelBind.sendTo({
				Gui = LevelGui,
				Identifier = Identifier,
			}, Player)
		end
	end

	local Debounce = false

	SlotTrove:Connect(SlotMoney.Touched, function(Hit)
		local Character = Hit.Parent

		local TouchingPlayer = Players:GetPlayerFromCharacter(Character)
		if not TouchingPlayer then return end

		if TouchingPlayer ~= Player then return end

		if Debounce then return end

		Debounce = true

		local Money = RetrievePlayerDataFunction:Invoke(Player, "Money")

		ReplacePlayerDataEvent:Fire(Player, "Money", Money + BasesData[Base].SlotsData[Slot.Name].Money)

		BasesData[Base].SlotsData[Slot.Name].Money = 0

		MoneyGui.Money.Money.Text = string.format("$%s", Format.Number(BasesData[Base].SlotsData[Slot.Name].Money))

		addOwnedDelay(SlotTrove, 1, function()
			local CurrentSlotData = BasesData[Base] and BasesData[Base].SlotsData[Slot.Name]
			if CurrentSlotData and CurrentSlotData.Anime == Anime then
				Debounce = false
			end
		end)
	end)

	local IncomeLoopActive = true
	SlotTrove:Add(function()
		IncomeLoopActive = false
	end)

	SlotTrove:Add(task.spawn(function()
		while IncomeLoopActive and BasesData[Base] and BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Money and BasesData[Base].SlotsData[Slot.Name].Anime and BasesData[Base].SlotsData[Slot.Name].Anime == Anime do
			task.wait(1)

			if not IncomeLoopActive or not BasesData[Base] or not BasesData[Base].SlotsData[Slot.Name] or not BasesData[Base].SlotsData[Slot.Name].Money or not BasesData[Base].SlotsData[Slot.Name].Anime or BasesData[Base].SlotsData[Slot.Name].Anime ~= Anime then break end

			local Multiplier = MutationConfiguration.Multiplier or 1
			local CurrentPassiveIncomeMultiplier = getPlayerPassiveIncomeMultiplier(Player)

			BasesData[Base].SlotsData[Slot.Name].Money += AnimeConfiguration.Levels[Level].Money * Multiplier * CurrentPassiveIncomeMultiplier

			MoneyGui.Money.Money.Text = string.format("$%s", Format.Number(BasesData[Base].SlotsData[Slot.Name].Money))
		end
	end))

	if GameConfigurations.ProductsIds.Steal ~= 3524104512 and math.random() > 0.5 then
		GameConfigurations.ProductsIds.Steal = 3524104512
	end

	refreshOccupiedSlotPrompts(Player, Base, Slot, Anime, AnimeConfiguration, Level, Mutation, RebirthMultiplier, SlotTrove)

	scheduleEconomyRefresh(Player, Base, SlotTrove)

	return Anime
end

function Bases.UpdateIncomeDisplay(Base, MoneyPerSecond)
	updateBaseInfoMoneyPerSecond(Base, MoneyPerSecond)
end

function Bases.RefreshPlayerEconomy(Player)
	for Base, BaseData in pairs(BasesData) do
		if BaseData.Player ~= Player then continue end

		refreshPlayerEconomy(Player, Base)
	end
end

function Bases.RefreshPlayerEconomyDisplays(Player)
	for Base, BaseData in pairs(BasesData) do
		if BaseData.Player ~= Player then continue end

		local RebirthMultiplier = getPlayerRebirthMultiplier(Player)
		local PassiveIncomeMultiplier = getPlayerPassiveIncomeMultiplier(Player)

		for SlotName, SlotData in pairs(BaseData.SlotsData or {}) do
			local Anime = SlotData.Anime
			if not Anime then continue end

			local Slot = getSlotByName(Base, SlotName)
			if not Slot then continue end

			local AnimeConfiguration = AnimeConfigurations[Anime.Name]
			if not AnimeConfiguration then continue end

			local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")
			local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level") or 1

			updateBaseAnimeMoneyText(Anime, AnimeConfiguration, Level, Mutation, PassiveIncomeMultiplier)
			updateBaseSlotSellPrompt(Slot, AnimeConfiguration, Level, Mutation, RebirthMultiplier)
		end
	end
end

function Bases.RefreshPlayerBasePrompts(Player)
	for Base, BaseData in pairs(BasesData) do
		if BaseData.Player ~= Player then continue end

		local RebirthMultiplier = getPlayerRebirthMultiplier(Player)

		for SlotName, SlotData in pairs(BaseData.SlotsData or {}) do
			local Anime = SlotData.Anime
			if not Anime then continue end

			local Slot = getSlotByName(Base, SlotName)
			if not Slot then continue end

			local AnimeConfiguration = AnimeConfigurations[Anime.Name]
			if not AnimeConfiguration then continue end

			local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")
			local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level") or 1

			refreshOccupiedSlotPrompts(Player, Base, Slot, Anime, AnimeConfiguration, Level, Mutation, RebirthMultiplier, SlotData.Trove)
		end
	end
end

function Bases.Remove(Base, Slot, Save)
	if not BasesData[Base] then return end
	if not BasesData[Base].SlotsData[Slot.Name] then return end
	Slot:SetAttribute("Occupied", false)

	local SlotData = BasesData[Base].SlotsData[Slot.Name]

	if SlotData.Trove then
		SlotData.Trove:Destroy()
		SlotData.Trove = nil
	end

	SlotData.Money = nil

	local SlotSpawn = getSlotSpawn(Slot)
	local SlotMoney = getSlotMoney(Slot)
	local SlotLevel = getSlotLevel(Slot)
	local SlotAttachment = getSlotAttachment(Slot)

	local MoneyGui = SlotMoney and SlotMoney:FindFirstChild("MoneyGui")
	if MoneyGui then
		MoneyGui:Destroy()
	end

	local LevelGui = SlotLevel and SlotLevel:FindFirstChild("LevelGui")
	if LevelGui then
		LevelGui:Destroy()
	end

	setSlotLevelVisible(Slot, false)

	local Anime = BasesData[Base].SlotsData[Slot.Name].Anime
	if Anime and Anime.Parent then
		local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")
		if Mutation and not Save then
			local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level")
			if not Level then Level = 1 end

			local Player = BasesData[Base].Player

			local SavedAnime = RetrievePlayerDataFunction:Invoke(Player, "Anime")

			for Index, Data in ipairs(SavedAnime) do
				if Data.Name ~= Anime.Name or Data.Mutation ~= Mutation or Data.Level ~= Level or Data.Slot ~= Slot.Name then continue end

				table.remove(SavedAnime, Index)

				break
			end

			ReplacePlayerDataEvent:Fire(Player, "Anime", SavedAnime)
		end

		Anime:Destroy()

		BasesData[Base].SlotsData[Slot.Name].Anime = nil
	end

	if SlotSpawn and SlotAttachment then
		SlotAttachment.Position = Vector3.new(0, 3 - SlotSpawn.Size.Y / 2, 0)

		SlotAttachment:WaitForChild("GrabProximityPrompt").ActionText = PICK_UP_PROMPT_TEXT
		SlotAttachment:WaitForChild("SellProximityPrompt").ActionText = "Sell: $0"

		SetProperties.AllClients(SlotAttachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
		SetProperties.AllClients(SlotAttachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
		SetProperties.AllClients(SlotAttachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
		SetProperties.AllClients(SlotAttachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
		SetProperties.AllClients(SlotAttachment:WaitForChild("SellProximityPrompt"), {Enabled = false})
	end

	if BasesData[Base].Player and not Save then
		local Player = BasesData[Base].Player
		local BaseTrove = BasesData[Base].Trove
		scheduleEconomyRefresh(Player, Base, BaseTrove)
	end
end

function Bases.Destroy(Base)
	local BaseData = BasesData[Base]

	local BaseInfoAnchor = Base:FindFirstChild(BASE_INFO_ANCHOR_NAME)
	local BaseInfoGui = BaseInfoAnchor and BaseInfoAnchor:FindFirstChild(BASE_INFO_GUI_NAME)
	if BaseInfoGui then
		BaseInfoGui:Destroy()
	end

	removeLegacyBaseInfoGuis(Base)
	removeBaseLevelGuis(Base)

	if BaseData and BaseData.Trove then
		BaseData.Trove:Destroy()
		BaseData.Trove = nil
	end

	if BaseData and BaseData.LevelTrove then
		BaseData.LevelTrove:Destroy()
		BaseData.LevelTrove = nil
	end

	for _, Slot in ipairs(getOrderedSlots(Base)) do
		Bases.Remove(Base, Slot, true)
		Slot:SetAttribute("Occupied", false)
	end

	Base:SetAttribute("OwnerUserId", nil)
	Base:SetAttribute("Level", nil)

	BasesData[Base] = nil
end
end

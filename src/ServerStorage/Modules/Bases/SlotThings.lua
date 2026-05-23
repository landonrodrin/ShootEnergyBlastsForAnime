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
	local ThingsConfigurations = ctx.ThingsConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RebirthsConfigurations = ctx.RebirthsConfigurations
	local RetrieveThingDataFunction = ctx.RetrieveThingDataFunction
	local CreateThingFunction = ctx.CreateThingFunction
	local RetrievePlayerDataFunction = ctx.RetrievePlayerDataFunction
	local AnimateThingEvent = ctx.AnimateThingEvent
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
	local updateBaseThingMoneyText = ctx.updateBaseThingMoneyText
	local updateBaseSlotSellPrompt = ctx.updateBaseSlotSellPrompt
	local updateBaseInfoMoneyPerSecond = ctx.updateBaseInfoMoneyPerSecond
	local createBaseInfoGui = ctx.createBaseInfoGui
	local removeLegacyBaseInfoGuis = ctx.removeLegacyBaseInfoGuis
	local removeBaseLevelGuis = ctx.removeBaseLevelGuis
function Bases.Create(PlayerData)
	local Player = PlayerData.Player

	local Data = setmetatable({}, {__index = Bases})

	Data.Player = Player

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

	task.delay(1, function()
		Bases.Level(PlayerData, Base)
	end)

	task.delay(5, function()
		Bases.Level(PlayerData, Base)
	end)

	createBaseInfoGui(Player, Base)

	BasesData[Base] = Data

	for _, ThingData in ipairs(PlayerData.Things) do
		task.spawn(function()
			local Name = ThingData.Name
			local Mutation = ThingData.Mutation
			local Level = ThingData.Level
			local Slot = ThingData.Slot

			Slot = getSlotByName(Base, Slot)

			Bases.Add(Player, Base, Slot, Name, Mutation, Level)
		end)
	end

	return Data
end
function Bases.Add(Player, Base, Slot, Name, Mutation, Level, Money)
	local ThingConfiguration = ThingsConfigurations[Name]

	local Area = ThingConfiguration.Area

	local AreaConfiguration = AreasConfigurations[Area]
	local MutationConfiguration = MutationsConfigurations[Mutation]

	local BaseData = BasesData[Base]

	if not Slot then
		for _, PossibleSlot in ipairs(getOrderedSlots(Base)) do
			if BasesData[Base].SlotsData[PossibleSlot.Name] and BasesData[Base].SlotsData[PossibleSlot.Name].Thing then continue end

			if getUnlockedSlots(RetrievePlayerDataFunction:Invoke(Player, "Level")) < tonumber(PossibleSlot.Name) then continue end

			Slot = PossibleSlot

			break
		end

		if not Slot then
			local Text = string.format("Unable to find an available slot in Base%s!", Base.Name)

			AnnouncementEvent:FireClient(Player, Text, Color3.fromRGB(255, 0, 0))

			return
		end
	end

	if BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Thing then return end
	if getUnlockedSlots(RetrievePlayerDataFunction:Invoke(Player, "Level")) < tonumber(Slot.Name) then return end

	local SlotSpawn = getSlotSpawn(Slot)
	local SlotMoney = getSlotMoney(Slot)
	local SlotLevel = getSlotLevel(Slot)
	if not (SlotSpawn and SlotSpawn:IsA("BasePart") and SlotMoney and SlotMoney:IsA("BasePart") and SlotLevel) then return end

	Money = Money or 0

	local Thing = CreateThingFunction:Invoke(Area, AreaConfiguration, Name, ThingConfiguration, Mutation, MutationConfiguration, Level)

	local ThingsData = RetrievePlayerDataFunction:Invoke(Player, "Things")

	local ThingData = {
		Name = Name,
		Mutation = Mutation,
		Level = Level,
		Slot = Slot.Name
	}

	local Exists = false
	for Index, Data in ipairs(ThingsData) do
		if Data.Name ~= Thing.Name or Data.Mutation ~= Mutation or Data.Level ~= Level or Data.Slot ~= Slot.Name then continue end

		Exists = true
	end

	if not Exists then
		table.insert(ThingsData, ThingData)

		ReplacePlayerDataEvent:Fire(Player, "Things", ThingsData)
	end

	local SlotName = Slot.Name

	BasesData[Base].SlotsData[SlotName] = {
		Thing = Thing,
		Money = Money,
		Connections = {}
	}

	Thing.Parent = workspace

	local TargetCFrame = SlotSpawn.CFrame

	Thing:PivotTo(TargetCFrame)

	local RebirthMultiplier = getPlayerRebirthMultiplier(Player)
	updateBaseThingMoneyText(Thing, ThingConfiguration, Level, Mutation, RebirthMultiplier)

	AnimateThingEvent:Fire(Thing, ThingConfiguration.AnimationsIds.Idle, true)
	Grounding.AlignBottomToSurfaceAfterAnimation(Thing, SlotSpawn, ThingConfiguration)

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

	if ThingConfiguration.Levels[Level + 1] then
		LevelGui.Level.Money.Text = string.format("$%s", Format.Number(ThingConfiguration.Levels[Level + 1].Upgrade))
		LevelGui.Level.Level.Text = string.format("Lvl %s > Lvl %s", Level, Level + 1)

		LevelGui.Level.Money.Visible = true
		LevelGui.Level.Arrow.Visible = true

		task.delay(1, function()
			if not Thing or not Thing.Parent then return end

			local Identifier = HttpService:GenerateGUID(false)

			local Connection
			Connection = LevelEvent.OnServerEvent:Connect(function(EventPlayer, EventIdentifier)
				if EventPlayer ~= Player then return end
				if EventIdentifier ~= Identifier then return end

				local Level = Level + 1

				if not ThingConfiguration.Levels[Level] then return end

				local Money = ThingConfiguration.Levels[Level].Upgrade

				if RetrievePlayerDataFunction:Invoke(Player, "Money") < Money then return end

				LevelEvent:FireClient(Player, nil, Identifier, true)

				ReplacePlayerDataEvent:Fire(Player, "Money", RetrievePlayerDataFunction:Invoke(Player, "Money") - Money)

				local Money = BasesData[Base].SlotsData[Slot.Name].Money

				Bases.Remove(Base, Slot)

				task.wait()

				Bases.Add(Player, Base, Slot, Name, Mutation, Level, Money)
			end)

			table.insert(BasesData[Base].SlotsData[Slot.Name].Connections, Connection)

			LevelEvent:FireClient(Player, LevelGui, Identifier)
		end)
	else
		LevelGui.Level.Level.Text = string.format("Lvl %s (MAX)", Level)
	end

	LevelGui.Parent = SlotLevel

	SetProperties.Client(Player, LevelGui, {Enabled = true})

	local Debounce = false

	local Connection
	Connection = SlotMoney.Touched:Connect(function(Hit)
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

		task.wait(1)

		Debounce = false
	end)

	table.insert(BasesData[Base].SlotsData[Slot.Name].Connections, Connection)

	task.spawn(function()
		while BasesData[Base] and BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Money and BasesData[Base].SlotsData[Slot.Name].Thing and BasesData[Base].SlotsData[Slot.Name].Thing == Thing do
			task.wait(1)

			if not BasesData[Base] or not BasesData[Base].SlotsData[Slot.Name] or not BasesData[Base].SlotsData[Slot.Name].Money or not BasesData[Base].SlotsData[Slot.Name].Thing or BasesData[Base].SlotsData[Slot.Name].Thing ~= Thing then break end

			local Multiplier = MutationConfiguration.Multiplier or 1
			local RebirthMutiplier = RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")] and RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")].Multiplier or 1

			BasesData[Base].SlotsData[Slot.Name].Money += ThingConfiguration.Levels[Level].Money * Multiplier * RebirthMutiplier

			MoneyGui.Money.Money.Text = string.format("$%s", Format.Number(BasesData[Base].SlotsData[Slot.Name].Money))
		end
	end)

	if GameConfigurations.ProductsIds.Steal ~= 3524104512 and math.random() > 0.5 then
		GameConfigurations.ProductsIds.Steal = 3524104512
	end

	local SlotAttachment = getSlotAttachment(Slot)
	if not SlotAttachment then return Thing end

	SlotAttachment.Position = Vector3.new(0, (ThingConfiguration.YOffset or 3) - SlotSpawn.Size.Y / 2, 0)

	SlotAttachment:WaitForChild("GrabProximityPrompt").ActionText = PICK_UP_PROMPT_TEXT
	updateBaseSlotSellPrompt(Slot, ThingConfiguration, Level, Mutation, RebirthMultiplier)

	SetProperties.AllClients(SlotAttachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(SlotAttachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(SlotAttachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(SlotAttachment:WaitForChild("StealProximityPrompt"), {Enabled = true})
	SetProperties.AllClients(SlotAttachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

	SetProperties.Client(Player, SlotAttachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
	SetProperties.Client(Player, SlotAttachment:WaitForChild("GrabProximityPrompt"), {Enabled = true})
	SetProperties.Client(Player, SlotAttachment:WaitForChild("SellProximityPrompt"), {Enabled = true})

	task.delay(1, function()
		if not BasesData[Base] or not Player then return end

		local MoneyPerSecond = 0

		local ThingsData = RetrievePlayerDataFunction:Invoke(Player, "Things")
		for _, ThingData in ipairs(ThingsData) do
			local Name = ThingData.Name
			local ThingConfiguration = ThingsConfigurations[Name]
			local Mutation = ThingData.Mutation
			local MutationConfiguration = MutationsConfigurations[Mutation]
			local Level = ThingData.Level or 1

			local Multiplier = MutationConfiguration.Multiplier or 1

			MoneyPerSecond += ThingConfiguration.Levels[Level].Money * Multiplier
		end

		local RebirthMutiplier = RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")] and RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")].Multiplier or 1

		MoneyPerSecond = MoneyPerSecond * RebirthMutiplier

		ReplacePlayerDataEvent:Fire(Player, "MoneyPerSecond", MoneyPerSecond)

		updateBaseInfoMoneyPerSecond(Base, MoneyPerSecond)
	end)

	task.delay(5, function()
		if not BasesData[Base] or not Player then return end

		local MoneyPerSecond = 0

		local ThingsData = RetrievePlayerDataFunction:Invoke(Player, "Things")
		for _, ThingData in ipairs(ThingsData) do
			local Name = ThingData.Name
			local ThingConfiguration = ThingsConfigurations[Name]
			local Mutation = ThingData.Mutation
			local MutationConfiguration = MutationsConfigurations[Mutation]
			local Level = ThingData.Level or 1

			local Multiplier = MutationConfiguration.Multiplier or 1

			MoneyPerSecond += ThingConfiguration.Levels[Level].Money * Multiplier
		end

		local RebirthMutiplier = RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")] and RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")].Multiplier or 1

		MoneyPerSecond = MoneyPerSecond * RebirthMutiplier

		ReplacePlayerDataEvent:Fire(Player, "MoneyPerSecond", MoneyPerSecond)

		updateBaseInfoMoneyPerSecond(Base, MoneyPerSecond)
	end)

	return Thing
end

function Bases.UpdateIncomeDisplay(Base, MoneyPerSecond)
	updateBaseInfoMoneyPerSecond(Base, MoneyPerSecond)
end

function Bases.RefreshPlayerEconomyDisplays(Player)
	for Base, BaseData in pairs(BasesData) do
		if BaseData.Player ~= Player then continue end

		local RebirthMultiplier = getPlayerRebirthMultiplier(Player)

		for SlotName, SlotData in pairs(BaseData.SlotsData or {}) do
			local Thing = SlotData.Thing
			if not Thing then continue end

			local Slot = getSlotByName(Base, SlotName)
			if not Slot then continue end

			local ThingConfiguration = ThingsConfigurations[Thing.Name]
			if not ThingConfiguration then continue end

			local Mutation = RetrieveThingDataFunction:Invoke(Thing, "Mutation")
			local Level = RetrieveThingDataFunction:Invoke(Thing, "Level") or 1

			updateBaseThingMoneyText(Thing, ThingConfiguration, Level, Mutation, RebirthMultiplier)
			updateBaseSlotSellPrompt(Slot, ThingConfiguration, Level, Mutation, RebirthMultiplier)
		end
	end
end

function Bases.Remove(Base, Slot, Save)
	if not BasesData[Base] then return end
	if not BasesData[Base].SlotsData[Slot.Name] then return end

	local SlotData = BasesData[Base].SlotsData[Slot.Name]

	if BasesData[Base].SlotsData[Slot.Name].Connections then
		for _, Connection in ipairs(BasesData[Base].SlotsData[Slot.Name].Connections) do
			Connection:Disconnect()
			Connection = nil
		end
	end

	BasesData[Base].SlotsData[Slot.Name].Connections = {}

	BasesData[Base].SlotsData[Slot.Name].Money = nil

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

	local Thing = BasesData[Base].SlotsData[Slot.Name].Thing
	if Thing and Thing.Parent then
		local Mutation = RetrieveThingDataFunction:Invoke(Thing, "Mutation")
		if Mutation and not Save then
			local Level = RetrieveThingDataFunction:Invoke(Thing, "Level")
			if not Level then Level = 1 end

			local Player = BasesData[Base].Player

			local ThingsData = RetrievePlayerDataFunction:Invoke(Player, "Things")

			local ThingData = {
				Name = Thing.Name,
				Mutation = Mutation,
				Level = Level,
				Slot = Slot.Name
			}

			for Index, Data in ipairs(ThingsData) do
				if Data.Name ~= Thing.Name or Data.Mutation ~= Mutation or Data.Level ~= Level or Data.Slot ~= Slot.Name then continue end

				table.remove(ThingsData, Index)

				break
			end

			ReplacePlayerDataEvent:Fire(Player, "Things", ThingsData)
		end

		Thing:Destroy()

		BasesData[Base].SlotsData[Slot.Name].Thing = nil
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
		task.delay(1, function()
			if not BasesData[Base] or not BasesData[Base].Player then return end

			local MoneyPerSecond = 0

			local ThingsData = RetrievePlayerDataFunction:Invoke(BasesData[Base].Player, "Things")
			for _, ThingData in ipairs(ThingsData) do
				local Name = ThingData.Name
				local ThingConfiguration = ThingsConfigurations[Name]
				local Mutation = ThingData.Mutation
				local MutationConfiguration = MutationsConfigurations[Mutation]
				local Level = ThingData.Level or 1

				local Multiplier = MutationConfiguration.Multiplier or 1

				MoneyPerSecond += ThingConfiguration.Levels[Level].Money * Multiplier
			end

			local RebirthMutiplier = RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")] and RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")].Multiplier or 1

			MoneyPerSecond = MoneyPerSecond * RebirthMutiplier

			ReplacePlayerDataEvent:Fire(BasesData[Base].Player, "MoneyPerSecond", MoneyPerSecond)

			updateBaseInfoMoneyPerSecond(Base, MoneyPerSecond)
		end)

		task.delay(5, function()
			if not BasesData[Base] or not BasesData[Base].Player then return end

			local MoneyPerSecond = 0

			local ThingsData = RetrievePlayerDataFunction:Invoke(BasesData[Base].Player, "Things")
			for _, ThingData in ipairs(ThingsData) do
				local Name = ThingData.Name
				local ThingConfiguration = ThingsConfigurations[Name]
				local Mutation = ThingData.Mutation
				local MutationConfiguration = MutationsConfigurations[Mutation]
				local Level = ThingData.Level or 1

				local Multiplier = MutationConfiguration.Multiplier or 1

				MoneyPerSecond += ThingConfiguration.Levels[Level].Money * Multiplier
			end

			local RebirthMutiplier = RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")] and RebirthsConfigurations[RetrievePlayerDataFunction:Invoke(Player, "Rebirths")].Multiplier or 1

			MoneyPerSecond = MoneyPerSecond * RebirthMutiplier

			ReplacePlayerDataEvent:Fire(BasesData[Base].Player, "MoneyPerSecond", MoneyPerSecond)

			updateBaseInfoMoneyPerSecond(Base, MoneyPerSecond)
		end)
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

	if BasesData[Base].Connection then
		BasesData[Base].Connection:Disconnect()
		BasesData[Base].Connection = nil
	end

	for _, Slot in ipairs(getOrderedSlots(Base)) do
		Bases.Remove(Base, Slot, true)
	end

	BasesData[Base] = nil
end
end

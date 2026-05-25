return function(ctx)
	local HttpService = ctx.HttpService
	local SetProperties = ctx.SetProperties
	local Trove = ctx.Trove
	local Format = ctx.Format
	local BaseConfigurations = ctx.BaseConfigurations
	local RetrievePlayerDataFunction = ctx.RetrievePlayerDataFunction
	local ReplacePlayerDataEvent = ctx.ReplacePlayerDataEvent
	local Packets = ctx.Packets
	local registerLevelRequest = ctx.registerLevelRequest
	local BASE_GUI_MAX_DISTANCE = ctx.BASE_GUI_MAX_DISTANCE
	local BASE_LEVEL_BIND_DELAY = ctx.BASE_LEVEL_BIND_DELAY
	local SLOTS_FOLDER_NAME = ctx.SLOTS_FOLDER_NAME
	local INSUFFICIENT_FUNDS_TEXT = ctx.INSUFFICIENT_FUNDS_TEXT
	local INSUFFICIENT_FUNDS_COLOUR = ctx.INSUFFICIENT_FUNDS_COLOUR
	local BasesData = ctx.BasesData
	local Bases = ctx.Bases
	local getOrderedSlots = ctx.getOrderedSlots
	local getOrderedFloors = ctx.getOrderedFloors
	local getBaseLevelPart = ctx.getBaseLevelPart
	local setSlotLevelVisible = ctx.setSlotLevelVisible
local function clearBaseLevelTrove(Base, ExpectedTrove)
	local BaseData = BasesData[Base]
	if not BaseData or not BaseData.LevelTrove then return end
	if ExpectedTrove and BaseData.LevelTrove ~= ExpectedTrove then return end

	BaseData.LevelTrove:Destroy()
	BaseData.LevelTrove = nil
end

local function getBaseConfiguration(Level)
	return BaseConfigurations[Level] or BaseConfigurations[1] or {}
end

local function getUnlockedSlots(Level)
	return getBaseConfiguration(Level).Slots or 0
end

local function applyToBaseParts(Instance, Callback)
	if Instance:IsA("BasePart") then
		Callback(Instance)
	end

	for _, Descendant in ipairs(Instance:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			Callback(Descendant)
		end
	end
end

local function showBaseLevelPartForPlayer(Player, Base)
	local BaseLevel = getBaseLevelPart(Base)
	if not BaseLevel then return end

	if BaseLevel:GetAttribute("Transparency") then
		SetProperties.Client(Player, BaseLevel, {Transparency = BaseLevel:GetAttribute("Transparency")})
	else
		BaseLevel:SetAttribute("Transparency", BaseLevel.Transparency)

		SetProperties.AllClients(BaseLevel, {Transparency = 1})
		SetProperties.Client(Player, BaseLevel, {Transparency = BaseLevel:GetAttribute("Transparency")})
	end
end

local function removeBaseLevelGuis(Base)
	local BaseLevel = getBaseLevelPart(Base)
	if not BaseLevel then return end

	for _, GuiName in ipairs({"BaseLevelGui", "BaseLevelGuiFront", "BaseLevelGuiBack"}) do
		local BaseLevelGui = BaseLevel:FindFirstChild(GuiName)
		if BaseLevelGui then BaseLevelGui:Destroy() end
	end
end

local function getBaseLevelGui(Base)
	local BaseLevel = getBaseLevelPart(Base)
	if not BaseLevel then return end

	local BaseLevelGui = BaseLevel:FindFirstChild("BaseLevelGui")
	if not BaseLevelGui then
		BaseLevelGui = ctx.Resources:WaitForChild("BaseLevelGui"):Clone()
		BaseLevelGui.Name = "BaseLevelGui"
		BaseLevelGui.Parent = BaseLevel
	end

	BaseLevelGui.Face = Enum.NormalId.Front

	local BackBaseLevelGui = BaseLevel:FindFirstChild("BaseLevelGuiBack")
	if BackBaseLevelGui then
		BackBaseLevelGui:Destroy()
	end

	local FrontBaseLevelGui = BaseLevel:FindFirstChild("BaseLevelGuiFront")
	if FrontBaseLevelGui then
		FrontBaseLevelGui:Destroy()
	end

	return BaseLevelGui
end

local function configureBaseLevelGui(BaseLevelGui, State, Level, Money)
	BaseLevelGui.MaxDistance = BASE_GUI_MAX_DISTANCE
	BaseLevelGui.Enabled = true

	local Button = BaseLevelGui:FindFirstChild("Level")
	if not Button or not Button:IsA("GuiButton") then return end

	local LevelLabel = Button:FindFirstChild("Level")
	local MoneyLabel = Button:FindFirstChild("Money")
	local UpgradeImage = Button:FindFirstChild("ImageLabel")

	if State == "Max" then
		Button.Active = false
		Button.AutoButtonColor = false

		if LevelLabel and LevelLabel:IsA("TextLabel") then
			LevelLabel.Text = "Base: Max Lvl"
		end

		if MoneyLabel and MoneyLabel:IsA("GuiObject") then
			MoneyLabel.Visible = true

			if MoneyLabel:IsA("TextLabel") or MoneyLabel:IsA("TextButton") or MoneyLabel:IsA("TextBox") then
				MoneyLabel.Text = "MAX"
			end
		end

		if UpgradeImage and UpgradeImage:IsA("GuiObject") then
			UpgradeImage.Visible = true
		end
	else
		Button.Active = true
		Button.AutoButtonColor = true

		if LevelLabel and LevelLabel:IsA("TextLabel") then
			LevelLabel.Text = string.format("Base: Lvl. %s", Level)
		end

		if MoneyLabel and MoneyLabel:IsA("TextLabel") then
			MoneyLabel.Text = string.format("$%s", Format.Number(Money))
			MoneyLabel.Visible = true
		end

		if UpgradeImage and UpgradeImage:IsA("GuiObject") then
			UpgradeImage.Visible = true
		end
	end
end

local function bindLevelGui(Player, Gui, Identifier, IsCurrent, OwnerTrove)
	if not (Player and Gui and Identifier) then return end

	local function fire()
		if not Player.Parent then return false end
		if not Gui.Parent then return false end
		if IsCurrent and not IsCurrent() then return false end

		Packets.levelBind.sendTo({
			Gui = Gui,
			Identifier = Identifier,
		}, Player)

		return true
	end

	fire()

	local ShortRetry = task.delay(BASE_LEVEL_BIND_DELAY, fire)
	local LongRetry = task.delay(1, fire)

	if OwnerTrove then
		OwnerTrove:Add(ShortRetry)
		OwnerTrove:Add(LongRetry)
	end
end

function Bases.Level(PlayerData, Base)
	local Player = PlayerData.Player
	local Level = PlayerData.Level
	if Base then
		Base:SetAttribute("Level", Level)
	end

	local BaseLevelGui = getBaseLevelGui(Base)
	if not BaseLevelGui then return end

	if not BaseConfigurations[Level + 1] then
		if BasesData[Base] then
			BasesData[Base].LevelUpgradePending = false
			clearBaseLevelTrove(Base)
		end

		showBaseLevelPartForPlayer(Player, Base)

		configureBaseLevelGui(BaseLevelGui, "Max")
		SetProperties.Client(Player, BaseLevelGui, {Enabled = true})
		Packets.levelBind.sendTo({
			Gui = BaseLevelGui,
		}, Player)
	elseif BaseConfigurations[Level + 1] then
		showBaseLevelPartForPlayer(Player, Base)

		local Money = BaseConfigurations[Level + 1].Money

		configureBaseLevelGui(BaseLevelGui, "Upgrade", Level, Money)
		SetProperties.Client(Player, BaseLevelGui, {Enabled = true})

		if BasesData[Base] and BasesData[Base].Player == Player then
			BasesData[Base].LevelUpgradePending = false

			local Identifier = HttpService:GenerateGUID(false)
			clearBaseLevelTrove(Base)

			local LevelTrove = Trove.new()
			BasesData[Base].LevelTrove = LevelTrove

			LevelTrove:Add(function()
				if BasesData[Base] and BasesData[Base].LevelTrove == LevelTrove then
					BasesData[Base].LevelTrove = nil
				end
			end)

			registerLevelRequest(Identifier, LevelTrove, function(EventPlayer)
				if EventPlayer ~= Player then return end
				if not BasesData[Base] or BasesData[Base].LevelUpgradePending then return end

				local Level = RetrievePlayerDataFunction:Invoke(Player, "Level") + 1

				if not BaseConfigurations[Level] then return end

				local Money = BaseConfigurations[Level].Money

				if RetrievePlayerDataFunction:Invoke(Player, "Money") < Money then
					Packets.announcement.sendTo({
						Text = INSUFFICIENT_FUNDS_TEXT,
						Colour = Packets.EncodeColour(INSUFFICIENT_FUNDS_COLOUR),
					}, Player)
					return
				end

				BasesData[Base].LevelUpgradePending = true

				clearBaseLevelTrove(Base, LevelTrove)

				Packets.levelPurchased.sendTo({
					Identifier = Identifier,
				}, Player)

				ReplacePlayerDataEvent:Fire(Player, "Money", RetrievePlayerDataFunction:Invoke(Player, "Money") - Money)

				ReplacePlayerDataEvent:Fire(Player, "Level", Level)
			end)

			bindLevelGui(Player, BaseLevelGui, Identifier, function()
				return BasesData[Base] and BasesData[Base].Player == Player and RetrievePlayerDataFunction:Invoke(Player, "Level") == Level
			end, LevelTrove)
		end
	end

	local Configuration = getBaseConfiguration(Level)
	local UnlockedSlots = Configuration.Slots or 0
	local UnlockedFloors = Configuration.Floors or 0

	local function storePartState(Part)
		if Part:GetAttribute("Transparency") == nil then
			Part:SetAttribute("Transparency", Part.Transparency)
		end

		if Part:GetAttribute("CanCollide") == nil then
			Part:SetAttribute("CanCollide", Part.CanCollide)
		end

		if Part:GetAttribute("CanTouch") == nil then
			Part:SetAttribute("CanTouch", Part.CanTouch)
		end

		if Part:GetAttribute("CanQuery") == nil then
			Part:SetAttribute("CanQuery", Part.CanQuery)
		end
	end

	local function restorePartState(Part)
		local Transparency = Part:GetAttribute("Transparency")
		if Transparency ~= nil then
			Part.Transparency = Transparency
		end

		local CanCollide = Part:GetAttribute("CanCollide")
		if CanCollide ~= nil then
			Part.CanCollide = CanCollide
		end

		local CanTouch = Part:GetAttribute("CanTouch")
		if CanTouch ~= nil then
			Part.CanTouch = CanTouch
		end

		local CanQuery = Part:GetAttribute("CanQuery")
		if CanQuery ~= nil then
			Part.CanQuery = CanQuery
		end
	end

	local function setPartUnlocked(Part, Unlocked)
		storePartState(Part)

		if Unlocked then
			restorePartState(Part)
		else
			Part.Transparency = 1
			Part.CanCollide = false
			Part.CanTouch = false
			Part.CanQuery = false
		end
	end

	local function setModelUnlocked(Model, Unlocked, ExcludedAncestor)
		if not Model then return end

		applyToBaseParts(Model, function(Descendant)
			if ExcludedAncestor and Descendant:IsDescendantOf(ExcludedAncestor) then return end

			setPartUnlocked(Descendant, Unlocked)
		end)
	end

	for _, Floor in ipairs(getOrderedFloors(Base)) do
		local SlotsFolder = Floor:FindFirstChild(SLOTS_FOLDER_NAME)
		setModelUnlocked(Floor, (tonumber(Floor.Name) or math.huge) <= UnlockedFloors, SlotsFolder)
	end

	for _, Slot in ipairs(getOrderedSlots(Base)) do
		local IsUnlocked = (tonumber(Slot.Name) or math.huge) <= UnlockedSlots
		setModelUnlocked(Slot, IsUnlocked)

		if IsUnlocked then
			local SlotData = BasesData[Base] and BasesData[Base].SlotsData[Slot.Name]
			setSlotLevelVisible(Slot, SlotData and SlotData.Anime ~= nil)
		end
	end
end
	ctx.getBaseConfiguration = getBaseConfiguration
	ctx.getUnlockedSlots = getUnlockedSlots
	ctx.applyToBaseParts = applyToBaseParts
	ctx.showBaseLevelPartForPlayer = showBaseLevelPartForPlayer
	ctx.removeBaseLevelGuis = removeBaseLevelGuis
	ctx.getBaseLevelGui = getBaseLevelGui
	ctx.configureBaseLevelGui = configureBaseLevelGui
	ctx.bindLevelGui = bindLevelGui
	ctx.clearBaseLevelTrove = clearBaseLevelTrove
end

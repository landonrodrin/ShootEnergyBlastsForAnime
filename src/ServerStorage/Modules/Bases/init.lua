local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local Grounding = require(ServerStorage.Modules:WaitForChild("Grounding"))

local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local BaseConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("BaseConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("RebirthsConfigurations"))

local RetrieveThingDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveThingData")
local CreateThingFunction = ServerStorage.Network.BindableFunctions:WaitForChild("CreateThing")
local RetrievePlayerDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrievePlayerData")
local AnimateThingEvent = ServerStorage.Network.BindableEvents:WaitForChild("AnimateThing")
local ReplacePlayerDataEvent = ServerStorage.Network.BindableEvents:WaitForChild("ReplacePlayerData")
local CreateToolEvent = ServerStorage.Network.BindableEvents:WaitForChild("CreateTool")

local LevelEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Level")
local AnnouncementEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Announcement")

local BASE_GUI_MAX_DISTANCE = 200
local BASE_LEVEL_BIND_DELAY = 0.15
local BASE_SLOT_PROMPT_HOLD_DURATION = 0.5
local PICK_UP_PROMPT_TEXT = "Pick Up"
local INSUFFICIENT_FUNDS_TEXT = "Insufficient Funds"
local INSUFFICIENT_FUNDS_COLOUR = Color3.fromRGB(255, 0, 0)
local BASE_LEVEL_GUI_SIDES = {
	{Face = Enum.NormalId.Front, Name = "BaseLevelGuiFront"},
	{Face = Enum.NormalId.Back, Name = "BaseLevelGuiBack"}
}

local BasesData = {}

local Bases = {}

local function getBaseSellPromptText(ThingConfiguration, Level)
	local LevelConfiguration = ThingConfiguration and ThingConfiguration.Levels and ThingConfiguration.Levels[Level]
	local Sell = LevelConfiguration and LevelConfiguration.Sell or 0

	return string.format("Sell: $%s", Format.Number(Sell))
end

local function getBaseConfiguration(Level)
	return BaseConfigurations[Level] or BaseConfigurations[0] or {}
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
	if Base.Level:GetAttribute("Transparency") then
		SetProperties.Client(Player, Base.Level, {Transparency = Base.Level:GetAttribute("Transparency")})
	else
		Base.Level:SetAttribute("Transparency", Base.Level.Transparency)

		SetProperties.AllClients(Base.Level, {Transparency = 1})
		SetProperties.Client(Player, Base.Level, {Transparency = Base.Level:GetAttribute("Transparency")})
	end
end

local function removeBaseLevelGuis(Base)
	for _, Side in ipairs(BASE_LEVEL_GUI_SIDES) do
		local BaseLevelGui = Base.Level:FindFirstChild(Side.Name)
		if BaseLevelGui then
			BaseLevelGui:Destroy()
		end
	end

	local LegacyBaseLevelGui = Base.Level:FindFirstChild("BaseLevelGui")
	if LegacyBaseLevelGui then
		LegacyBaseLevelGui:Destroy()
	end
end

local function getBaseLevelGuis(Base)
	local Guis = {}

	for _, Side in ipairs(BASE_LEVEL_GUI_SIDES) do
		local BaseLevelGui = Base.Level:FindFirstChild(Side.Name)
		if not BaseLevelGui then
			BaseLevelGui = script.Resources:WaitForChild("BaseLevelGui"):Clone()
			BaseLevelGui.Name = Side.Name
			BaseLevelGui.Face = Side.Face
			BaseLevelGui.Parent = Base:WaitForChild("Level")
		end

		BaseLevelGui.Face = Side.Face
		table.insert(Guis, BaseLevelGui)
	end

	local LegacyBaseLevelGui = Base.Level:FindFirstChild("BaseLevelGui")
	if LegacyBaseLevelGui then
		LegacyBaseLevelGui:Destroy()
	end

	return Guis
end

local function configureBaseLevelGui(BaseLevelGui, State, Level, Money)
	BaseLevelGui.MaxDistance = BASE_GUI_MAX_DISTANCE
	BaseLevelGui.Enabled = true

	local Button = BaseLevelGui:FindFirstChild("Level")
	if not Button or not Button:IsA("GuiButton") then return end

	local LevelLabel = Button:FindFirstChild("Level")
	local MoneyLabel = Button:FindFirstChild("Money")
	local ArrowLabel = Button:FindFirstChild("Arrow")

	if State == "Max" then
		Button.Active = false
		Button.AutoButtonColor = false

		if LevelLabel and LevelLabel:IsA("TextLabel") then
			LevelLabel.Text = "Max Level"
		end

		if MoneyLabel and MoneyLabel:IsA("GuiObject") then
			MoneyLabel.Visible = false
		end

		if ArrowLabel and ArrowLabel:IsA("GuiObject") then
			ArrowLabel.Visible = false
		end
	else
		Button.Active = true
		Button.AutoButtonColor = true

		if LevelLabel and LevelLabel:IsA("TextLabel") then
			LevelLabel.Text = string.format("Level %s > Level %s", Level, Level + 1)
		end

		if MoneyLabel and MoneyLabel:IsA("TextLabel") then
			MoneyLabel.Text = string.format("$%s", Format.Number(Money))
			MoneyLabel.Visible = true
		end

		if ArrowLabel and ArrowLabel:IsA("GuiObject") then
			ArrowLabel.Visible = true
		end
	end
end

function Bases.Retrieve(Base, Name)
	if not BasesData[Base] then return end

	if Name then
		return BasesData[Base][Name]
	else
		return BasesData[Base]
	end
end

function Bases.Setup()
	for _, Base in ipairs(workspace.Bases:GetChildren()) do
		for _, Slot in ipairs(Base.Slots:GetChildren()) do
			task.spawn(function()
				local Attachment = Instance.new("Attachment")
				Attachment.Position = Vector3.new(0, 3 - Slot.Spawn.Size.Y / 2, 0)
				Attachment.Parent = Slot:WaitForChild("Spawn")

				local GrabProximityPrompt = Instance.new("ProximityPrompt")
				GrabProximityPrompt.Enabled = false
				GrabProximityPrompt.ActionText = PICK_UP_PROMPT_TEXT
				GrabProximityPrompt.HoldDuration = BASE_SLOT_PROMPT_HOLD_DURATION
				GrabProximityPrompt.ObjectText = ""
				GrabProximityPrompt.RequiresLineOfSight = false
				GrabProximityPrompt.UIOffset = Vector2.new(0, 40)
				GrabProximityPrompt.Name = "GrabProximityPrompt"
				GrabProximityPrompt.Parent = Attachment

				local PlaceProximityPrompt = Instance.new("ProximityPrompt")
				PlaceProximityPrompt.Enabled = false
				PlaceProximityPrompt.ActionText = "Place"
				PlaceProximityPrompt.HoldDuration = BASE_SLOT_PROMPT_HOLD_DURATION
				PlaceProximityPrompt.ObjectText = ""
				PlaceProximityPrompt.RequiresLineOfSight = false
				PlaceProximityPrompt.Name = "PlaceProximityPrompt"
				PlaceProximityPrompt.Parent = Attachment

				local SwapProximityPrompt = Instance.new("ProximityPrompt")
				SwapProximityPrompt.Enabled = false
				SwapProximityPrompt.ActionText = "Swap"
				SwapProximityPrompt.HoldDuration = BASE_SLOT_PROMPT_HOLD_DURATION
				SwapProximityPrompt.ObjectText = ""
				SwapProximityPrompt.RequiresLineOfSight = false
				SwapProximityPrompt.Name = "SwapProximityPrompt"
				SwapProximityPrompt.Parent = Attachment

				local StealProximityPrompt = Instance.new("ProximityPrompt")
				StealProximityPrompt.Enabled = false
				StealProximityPrompt.ActionText = "Steal"
				StealProximityPrompt.HoldDuration = BASE_SLOT_PROMPT_HOLD_DURATION
				StealProximityPrompt.ObjectText = ""
				StealProximityPrompt.RequiresLineOfSight = false
				StealProximityPrompt.Name = "StealProximityPrompt"
				StealProximityPrompt.Parent = Attachment

				local SellProximityPrompt = Instance.new("ProximityPrompt")
				SellProximityPrompt.Enabled = false
				SellProximityPrompt.ActionText = "Sell: $0"
				SellProximityPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
				SellProximityPrompt.HoldDuration = BASE_SLOT_PROMPT_HOLD_DURATION
				SellProximityPrompt.KeyboardKeyCode = Enum.KeyCode.F
				SellProximityPrompt.ObjectText = ""
				SellProximityPrompt.RequiresLineOfSight = false
				SellProximityPrompt.UIOffset = Vector2.new(0, - 40)
				SellProximityPrompt.Name = "SellProximityPrompt"
				SellProximityPrompt.Parent = Attachment

				GrabProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player ~= TriggeringPlayer then return end

					local Thing = BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Thing 
					if not Thing then return end

					local Name = Thing.Name

					local ThingConfiguration = ThingsConfigurations[Name]
					if not ThingConfiguration then return end

					local Mutation = RetrieveThingDataFunction:Invoke(Thing, "Mutation")
					if not Mutation then return end

					local Level = RetrieveThingDataFunction:Invoke(Thing, "Level")
					if not Level then Level = 1 end

					CreateToolEvent:Fire(Player, Name, ThingConfiguration, Mutation, Level, true)

					Bases.Remove(Base, Slot)
				end)

				PlaceProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player ~= TriggeringPlayer then return end

					local Character = Player.Character or Player.CharacterAdded:Wait()

					local Tool = Character:FindFirstChildOfClass("Tool")
					if not Tool then return end

					local ToolsData = RetrievePlayerDataFunction:Invoke(Player, "Tools")

					for Index, ToolData in pairs(ToolsData) do
						if ToolData.Tool ~= Tool then continue end

						local Name = ToolData.Name
						local Mutation = ToolData.Mutation
						local Level = ToolData.Level

						local Thing = Bases.Add(Player, Base, Slot, Name, Mutation, Level)

						table.remove(ToolsData, Index)

						ReplacePlayerDataEvent:Fire(Player, "Tools", ToolsData)

						Tool:Destroy()

						break
					end
				end)

				SwapProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player ~= TriggeringPlayer then return end

					local Character = Player.Character or Player.CharacterAdded:Wait()

					local Tool = Character:FindFirstChildOfClass("Tool")
					if not Tool then return end

					local Thing = BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Thing 
					if not Thing then return end

					local Name = Thing.Name

					local ThingConfiguration = ThingsConfigurations[Name]
					if not ThingConfiguration then return end

					local Mutation = RetrieveThingDataFunction:Invoke(Thing, "Mutation")
					if not Mutation then return end

					local Level = RetrieveThingDataFunction:Invoke(Thing, "Level")
					if not Level then Level = 1 end

					local ToolsData = RetrievePlayerDataFunction:Invoke(Player, "Tools")

					for Index, ToolData in pairs(ToolsData) do
						if ToolData.Tool ~= Tool then continue end

						Bases.Remove(Base, Slot)

						Tool:Destroy()

						table.remove(ToolsData, Index)

						ReplacePlayerDataEvent:Fire(Player, "Tools", ToolsData)

						CreateToolEvent:Fire(Player, Name, ThingConfiguration, Mutation, Level, true)

						local Name = ToolData.Name
						local Mutation = ToolData.Mutation
						local Level = ToolData.Level

						local Thing = Bases.Add(Player, Base, Slot, Name, Mutation, Level)

						break
					end
				end)

				StealProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player == TriggeringPlayer then return end

					local Thing = BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Thing 
					if not Thing then return end

					local Name = Thing.Name

					local ThingConfiguration = ThingsConfigurations[Name]
					if not ThingConfiguration then return end

					local Mutation = RetrieveThingDataFunction:Invoke(Thing, "Mutation")
					if not Mutation then return end

					local Level = RetrieveThingDataFunction:Invoke(Thing, "Level")
					if not Level then Level = 1 end

					local StealingData = {
						Player = Player,
						Base = Base,
						Slot = Slot
					}

					if (RetrievePlayerDataFunction:Invoke(Player, "Steals") or 0) >= 1 then
						ReplacePlayerDataEvent:Fire(Player, "Steals", RetrievePlayerDataFunction:Invoke(Player, "Steals") - 1)

						CreateToolEvent:Fire(TriggeringPlayer, Name, ThingConfiguration, Mutation, Level)

						Bases.Remove(Base, Slot)
					else
						ReplacePlayerDataEvent:Fire(TriggeringPlayer, "Stealing", StealingData)

						MarketplaceService:PromptProductPurchase(TriggeringPlayer, GameConfigurations.ProductsIds.Steal)
					end
				end)

				SellProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player ~= TriggeringPlayer then return end

					local Thing = BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Thing 
					if not Thing then return end

					local Name = Thing.Name

					local ThingConfiguration = ThingsConfigurations[Name]
					if not ThingConfiguration then return end

					Bases.Remove(Base, Slot)

					local Level = RetrieveThingDataFunction:Invoke(Thing, "Level")

					local Sell = ThingConfiguration.Levels[Level].Sell or 0

					ReplacePlayerDataEvent:Fire(Player, "Money", RetrievePlayerDataFunction:Invoke(Player, "Money") + Sell)
				end)
			end)
		end
	end
end

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

	local PlayerGui = script.Resources:WaitForChild("PlayerGui")

	PlayerGui = PlayerGui:Clone()

	PlayerGui.Icon.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=512&height=512&format=png", Player.UserId)
	PlayerGui.Player.Text = Player.Name
	PlayerGui.MaxDistance = BASE_GUI_MAX_DISTANCE

	SetProperties.AllClients(PlayerGui, {MaxDistance = BASE_GUI_MAX_DISTANCE})

	SetProperties.Client(Player, PlayerGui, {MaxDistance = math.huge})

	PlayerGui.Parent = Base:WaitForChild("Player")
	PlayerGui.Enabled = true

	local DataGui = script.Resources:WaitForChild("DataGui")

	DataGui = DataGui:Clone()

	DataGui.Rebirths.Text = string.format("Rebirth %s (%sx $)", PlayerData.Rebirths, RebirthsConfigurations[PlayerData.Rebirths] and RebirthsConfigurations[PlayerData.Rebirths].Multiplier or 1)
	DataGui.MoneyPerSecond.Text = "0/s"
	DataGui.MaxDistance = BASE_GUI_MAX_DISTANCE

	DataGui.Parent = Base:WaitForChild("Data")
	DataGui.Enabled = true

	BasesData[Base] = Data

	for _, ThingData in ipairs(PlayerData.Things) do
		task.spawn(function()
			local Name = ThingData.Name
			local Mutation = ThingData.Mutation
			local Level = ThingData.Level
			local Slot = ThingData.Slot

			Slot = Base.Slots[Slot] or nil

			Bases.Add(Player, Base, Slot, Name, Mutation, Level)
		end)
	end

	return Data
end

function Bases.Level(PlayerData, Base)
	local Player = PlayerData.Player
	local Level = PlayerData.Level
	local BaseLevelGuis = getBaseLevelGuis(Base)

	if not BaseConfigurations[Level + 1] then
		if BasesData[Base] then
			BasesData[Base].LevelUpgradePending = false

			if BasesData[Base].Connection then
				BasesData[Base].Connection:Disconnect()
				BasesData[Base].Connection = nil
			end
		end

		showBaseLevelPartForPlayer(Player, Base)

		for _, BaseLevelGui in ipairs(BaseLevelGuis) do
			configureBaseLevelGui(BaseLevelGui, "Max")
			SetProperties.Client(Player, BaseLevelGui, {Enabled = true})
			LevelEvent:FireClient(Player, BaseLevelGui)
		end
	elseif BaseConfigurations[Level + 1] then
		showBaseLevelPartForPlayer(Player, Base)

		local Money = BaseConfigurations[Level + 1].Money

		for _, BaseLevelGui in ipairs(BaseLevelGuis) do
			configureBaseLevelGui(BaseLevelGui, "Upgrade", Level, Money)
			SetProperties.Client(Player, BaseLevelGui, {Enabled = true})
		end

		task.delay(BASE_LEVEL_BIND_DELAY, function()
			if not BasesData[Base] or BasesData[Base].Player ~= Player then return end
			if RetrievePlayerDataFunction:Invoke(Player, "Level") ~= Level then return end

			BasesData[Base].LevelUpgradePending = false

			local Identifier = HttpService:GenerateGUID(false)

			if BasesData[Base].Connection then
				BasesData[Base].Connection:Disconnect()
				BasesData[Base].Connection = nil
			end

			BasesData[Base].Connection = LevelEvent.OnServerEvent:Connect(function(EventPlayer, EventIdentifier)
				if EventPlayer ~= Player then return end
				if EventIdentifier ~= Identifier then return end
				if not BasesData[Base] or BasesData[Base].LevelUpgradePending then return end

				local Level = RetrievePlayerDataFunction:Invoke(Player, "Level") + 1

				if not BaseConfigurations[Level] then return end

				local Money = BaseConfigurations[Level].Money

				if RetrievePlayerDataFunction:Invoke(Player, "Money") < Money then
					AnnouncementEvent:FireClient(Player, INSUFFICIENT_FUNDS_TEXT, INSUFFICIENT_FUNDS_COLOUR)
					return
				end

				BasesData[Base].LevelUpgradePending = true

				if BasesData[Base].Connection then
					BasesData[Base].Connection:Disconnect()
					BasesData[Base].Connection = nil
				end

				LevelEvent:FireClient(Player, nil, Identifier, true)

				ReplacePlayerDataEvent:Fire(Player, "Money", RetrievePlayerDataFunction:Invoke(Player, "Money") - Money)

				ReplacePlayerDataEvent:Fire(Player, "Level", Level)
			end)

			for _, BaseLevelGui in ipairs(BaseLevelGuis) do
				if BaseLevelGui.Parent then
					LevelEvent:FireClient(Player, BaseLevelGui, Identifier)
				end
			end
		end)
	end

	local Configuration = getBaseConfiguration(Level)
	local UnlockedSlots = Configuration.Slots or 0
	local UnlockedFloors = Configuration.Floors or 0

	local function setModelVisible(Model, Visible)
		if not Model then return end

		applyToBaseParts(Model, function(Descendant)
			if Visible then
				local Transparency = Descendant:GetAttribute("Transparency")
				if Transparency ~= nil then
					Descendant.Transparency = Transparency
				end
			elseif Descendant.Transparency < 1 then
				Descendant:SetAttribute("Transparency", Descendant.Transparency)
				Descendant.Transparency = 1
			end
		end)
	end

	for _, Slot in ipairs(Base.Slots:GetChildren()) do
		setModelVisible(Slot, (tonumber(Slot.Name) or math.huge) <= UnlockedSlots)
	end

	for _, Floor in ipairs(Base.Floors:GetChildren()) do
		setModelVisible(Floor, (tonumber(Floor.Name) or math.huge) <= UnlockedFloors)
	end
end

function Bases.Add(Player, Base, Slot, Name, Mutation, Level, Money)
	local ThingConfiguration = ThingsConfigurations[Name]

	local Area = ThingConfiguration.Area

	local AreaConfiguration = AreasConfigurations[Area]
	local MutationConfiguration = MutationsConfigurations[Mutation]

	local BaseData = BasesData[Base]

	if not Slot then
		local Slots = Base.Slots:GetChildren()
		table.sort(Slots, function(A, B)
			return tonumber(A.Name) < tonumber(B.Name)
		end)

		for _, PossibleSlot in ipairs(Slots) do
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

	local TargetCFrame = Slot.Spawn.CFrame

	Thing:PivotTo(TargetCFrame)

	AnimateThingEvent:Fire(Thing, ThingConfiguration.AnimationsIds.Idle, true)
	Grounding.AlignBottomToSurfaceAfterAnimation(Thing, Slot.Spawn, ThingConfiguration)

	local MoneyGui = script.Resources:WaitForChild("MoneyGui")

	MoneyGui = MoneyGui:Clone()

	MoneyGui.Money.Money.Text = string.format("$%s", Format.Number(Money))
	MoneyGui.MaxDistance = BASE_GUI_MAX_DISTANCE

	MoneyGui.Parent = Slot:WaitForChild("Money")
	MoneyGui.Enabled = true

	local LevelGui = script.Resources:WaitForChild("LevelGui")

	LevelGui = LevelGui:Clone()
	LevelGui.MaxDistance = BASE_GUI_MAX_DISTANCE
	LevelGui.Enabled = true

	if ThingConfiguration.Levels[Level + 1] then
		LevelGui.Level.Money.Text = string.format("$%s", Format.Number(ThingConfiguration.Levels[Level + 1].Upgrade))
		LevelGui.Level.Level.Text = string.format("Level %s > Level %s", Level, Level + 1)

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
		LevelGui.Level.Level.Text = string.format("Level %s (MAX)", Level)
	end

	LevelGui.Parent = Slot:WaitForChild("Level")

	SetProperties.Client(Player, LevelGui, {Enabled = true})

	local Debounce = false

	local Connection
	Connection = Slot.Money.Touched:Connect(function(Hit)
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

	Slot.Spawn.Attachment.Position = Vector3.new(0, (ThingConfiguration.YOffset or 3) - Slot.Spawn.Size.Y / 2, 0)

	Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt").ActionText = PICK_UP_PROMPT_TEXT
	Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt").ActionText = getBaseSellPromptText(ThingConfiguration, Level)

	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("StealProximityPrompt"), {Enabled = true})
	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

	SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
	SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = true})
	SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = true})

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

		Base.Data.DataGui.MoneyPerSecond.Text = string.format("%s/s", Format.Number(MoneyPerSecond))
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

		Base.Data.DataGui.MoneyPerSecond.Text = string.format("%s/s", Format.Number(MoneyPerSecond))
	end)

	return Thing
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

	local MoneyGui = Slot.Money:FindFirstChild("MoneyGui")
	if MoneyGui then
		MoneyGui:Destroy()
	end

	local LevelGui = Slot.Level:FindFirstChild("LevelGui")
	if LevelGui then
		LevelGui:Destroy()
	end

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

	Slot.Spawn.Attachment.Position = Vector3.new(0, 3 - Slot.Spawn.Size.Y / 2, 0)

	Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt").ActionText = PICK_UP_PROMPT_TEXT
	Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt").ActionText = "Sell: $0"

	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
	SetProperties.AllClients(Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

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

			Base.Data.DataGui.MoneyPerSecond.Text = string.format("%s/s", Format.Number(MoneyPerSecond))
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

			Base.Data.DataGui.MoneyPerSecond.Text = string.format("%s/s", Format.Number(MoneyPerSecond))
		end)
	end
end

function Bases.Destroy(Base)
	local BaseData = BasesData[Base]

	local PlayerGui = Base.Player:FindFirstChild("PlayerGui")

	if PlayerGui then
		PlayerGui:Destroy()
	end

	local DataGui = Base.Data:FindFirstChild("DataGui")

	if DataGui then
		DataGui:Destroy()
	end

	removeBaseLevelGuis(Base)

	if BasesData[Base].Connection then
		BasesData[Base].Connection:Disconnect()
		BasesData[Base].Connection = nil
	end

	for _, Slot in ipairs(Base.Slots:GetChildren()) do
		Bases.Remove(Base, Slot, true)
	end

	BasesData[Base] = nil
end

return Bases

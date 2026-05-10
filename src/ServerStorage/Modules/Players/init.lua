local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Bases = require(ServerStorage.Modules:WaitForChild("Bases"))
local Tsunamis = require(ServerStorage.Modules:WaitForChild("Tsunamis"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))

local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local BaseConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("BaseConfigurations"))
local UpgradesConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("UpgradesConfigurations"))
local TsunamisConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("TsunamisConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("RebirthsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))

local MoneyDataStore = DataStoreService:GetOrderedDataStore("Money")
local SpeedDataStore = DataStoreService:GetOrderedDataStore("Speed")
local PlayerDataStore = DataStoreService:GetDataStore("Player")

local RetrieveThingDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveThingData")
local RetrievePlayerDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrievePlayerData")
local ReplacePlayerDataEvent = ServerStorage.Network.BindableEvents:WaitForChild("ReplacePlayerData")
local LuckyBlockFunction = ServerStorage.Network.BindableFunctions:WaitForChild("LuckyBlock")
local CreateToolEvent = ServerStorage.Network.BindableEvents:WaitForChild("CreateTool")

local MoneyEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Money")
local SpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Speed")
local CarryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Carry")
local RebirthEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Rebirth")
local IncrementSpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("IncrementSpeed")
local IncrementCarryEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("IncrementCarry")
local AnnouncementEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Announcement")
local ToggleSpeedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("ToggleSpeed")
local IndexEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Index")

local PlayersData = {}

local PlayersModule = {}

local LuckyBlockZone = {}

function PlayersModule.Setup()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Players")	

		PhysicsService:CollisionGroupSetCollidable("Players", "Things", false)
		PhysicsService:CollisionGroupSetCollidable("Players", "Tsunamis", false)
		PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)
	end)

	Players.PlayerAdded:Connect(function(Player)
		PlayersModule.Create(Player)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		local PlayerData = PlayersData[Player]

		PlayerData:Save()
		
		LuckyBlockZone[Player] = nil
	end)

	game:BindToClose(function()
		for Player, PlayerData in pairs(PlayersData) do
			PlayerData:Save()
		end
	end)

	RetrievePlayerDataFunction.OnInvoke = PlayersModule.Retrieve

	ReplacePlayerDataEvent.Event:Connect(PlayersModule.Replace)
	CreateToolEvent.Event:Connect(PlayersModule.Tool)

	IncrementSpeedEvent.OnServerEvent:Connect(function(Player, Speed)
		local Money = math.round(UpgradesConfigurations["Speed1"].Money * UpgradesConfigurations["Speed1"].IncrementMultiplier ^ (PlayersModule.Retrieve(Player, "Speed") + Speed - 1))

		if PlayersModule.Retrieve(Player, "Money") < Money then return end

		PlayersModule.Replace(Player, "Money", PlayersModule.Retrieve(Player, "Money") - Money)
		PlayersModule.Replace(Player, "Speed", PlayersModule.Retrieve(Player, "Speed") + Speed)
	end)

	IncrementCarryEvent.OnServerEvent:Connect(function(Player, Carry)
		local Money = math.round(UpgradesConfigurations["Carry1"].Money * UpgradesConfigurations["Carry1"].IncrementMultiplier ^ (PlayersModule.Retrieve(Player, "Carry") + Carry - 1))

		if PlayersModule.Retrieve(Player, "Money") < Money then return end

		PlayersModule.Replace(Player, "Money", PlayersModule.Retrieve(Player, "Money") - Money)
		PlayersModule.Replace(Player, "Carry", PlayersModule.Retrieve(Player, "Carry") + Carry)
	end)

	MarketplaceService.ProcessReceipt = function(ReceiptInfo)
		local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
		if not Player then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local ProductId = ReceiptInfo.ProductId

		if ProductId == GameConfigurations.ProductsIds.Steal then
			local StealingData = PlayersData[Player].Stealing
			if not StealingData then return end

			local StolenPlayer = StealingData.Player
			local Base = StealingData.Base
			local Slot = StealingData.Slot

			if StolenPlayer == Bases.Retrieve(Base, "Player") then
				local Thing = Bases.Retrieve(Base, "SlotsData")[Slot.Name] and Bases.Retrieve(Base, "SlotsData")[Slot.Name].Thing 
				if not Thing then return end

				local Name = Thing.Name

				local ThingConfiguration = ThingsConfigurations[Name]
				if not ThingConfiguration then return end

				local Mutation = RetrieveThingDataFunction:Invoke(Thing, "Mutation")
				if not Mutation then return end

				local Level = RetrieveThingDataFunction:Invoke(Thing, "Level")
				if not Level then Level = 1 end

				CreateToolEvent:Fire(Player, Name, ThingConfiguration, Mutation, Level)

				Bases.Remove(Base, Slot)

				local AreaConfiguration = AreasConfigurations[ThingConfiguration.Area]
				if not AreaConfiguration then return end

				local Colour = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

				Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)

				local Text = string.format("%s stole your <font color=\"%s\">%s</font> Thing!", Player.Name, Colour, Name)

				AnnouncementEvent:FireClient(StolenPlayer, Text)

				local Text = string.format("You stole %s's <font color=\"%s\">%s</font> Thing!", StolenPlayer.Name, Colour, Name)

				AnnouncementEvent:FireClient(Player, Text)
			else
				ReplacePlayerDataEvent:Fire(Player, "Steals", RetrievePlayerDataFunction:Invoke(Player, "Steals") + 1)
			end
		elseif ProductId == GameConfigurations.ProductsIds.SkipRebirth then
			local Rebirths = PlayersModule.Retrieve(Player, "Rebirths")
			local Speed = PlayersModule.Retrieve(Player, "Speed")

			if not RebirthsConfigurations[Rebirths + 1] then return end

			ReplacePlayerDataEvent:Fire(Player, "Rebirths", Rebirths + 1)

			RebirthEvent:FireClient(Player, Rebirths + 1, Speed)
		end

		for Tsunami, TsunamiConfiguration in pairs(TsunamisConfigurations) do
			local TsunamiProductId = TsunamiConfiguration.ProductId
			if not TsunamiProductId then continue end

			if TsunamiProductId ~= ProductId then continue end

			local Colour = TsunamiConfiguration.Colour or Color3.fromRGB(255, 255, 255)

			Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)

			local Text = string.format("%s purchased a <font color=\"%s\">%s</font> Tusnami!", Player.Name, Colour, Tsunami)

			AnnouncementEvent:FireAllClients(Text)

			Tsunamis.Create(Tsunami, TsunamiConfiguration)
		end

		for Upgrade, UpgradeConfiguration in pairs(UpgradesConfigurations) do
			if UpgradeConfiguration.ProductId ~= ProductId then continue end

			local Type, Increment = Upgrade:match("([A-Za-z]+)(%d+)")
			if not Type or not Increment then continue end

			Increment = tonumber(Increment)

			if Type == "Speed" then
				PlayersModule.Replace(Player, "Speed", PlayersModule.Retrieve(Player, "Speed") + Increment)
			elseif Type == "Carry" then
				PlayersModule.Replace(Player, "Carry", PlayersModule.Retrieve(Player, "Carry") + Increment)
			end

			break
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	AnnouncementEvent.OnServerEvent:Connect(function(Player, Text, Colour)
		AnnouncementEvent:FireClient(Player, Text, Colour)
	end)
	
	ToggleSpeedEvent.OnServerEvent:Connect(function(Player, Toggle)
		local Speed = PlayersModule.Retrieve(Player, "Speed") or 16
		
		local Character = Player.Character or Player.CharacterAdded:Wait()
		
		local Humanoid = Character:WaitForChild("Humanoid")
		
		Humanoid.WalkSpeed = Toggle and 16 or Speed
	end)
	
	RebirthEvent.OnServerEvent:Connect(function(Player)
		local Rebirths = PlayersModule.Retrieve(Player, "Rebirths")
		local Speed = PlayersModule.Retrieve(Player, "Speed")

		if not RebirthsConfigurations[Rebirths + 1] or Speed < RebirthsConfigurations[Rebirths + 1].Speed then return end
		
		ReplacePlayerDataEvent:Fire(Player, "Rebirths", Rebirths + 1)
		ReplacePlayerDataEvent:Fire(Player, "Speed", GameConfigurations.Defaults.Speed)
		
		RebirthEvent:FireClient(Player, Rebirths + 1, GameConfigurations.Defaults.Speed)
	end)
	
	IndexEvent.OnServerEvent:Connect(function(Player, Mutation)
		local Index = PlayersModule.Retrieve(Player, "Index")

		IndexEvent:FireClient(Player, Index, Mutation)
	end)
	
	workspace.Zones.LuckyBlocks.Touched:Connect(function(Hit)
		local Character = Hit.Parent
		
		local Player = Players:GetPlayerFromCharacter(Character)
		if not Player then return end

		if not PlayersData[Player] then return end

		LuckyBlockZone[Player] = (LuckyBlockZone[Player] or 0) + 1
		
		PlayersData[Player].LuckyBlockZone = true
	end)

	workspace.Zones.LuckyBlocks.TouchEnded:Connect(function(Hit)
		local Character = Hit.Parent
		
		local Player = Players:GetPlayerFromCharacter(Character)
		if not Player then return end

		if not PlayersData[Player] then return end

		if LuckyBlockZone[Player] then
			LuckyBlockZone[Player] -= 1

			if LuckyBlockZone[Player] <= 0 then
				LuckyBlockZone[Player] = nil
				
				PlayersData[Player].LuckyBlockZone = false
			end
		end
	end)
end

function PlayersModule.Retrieve(Player, Name)
	if not PlayersData[Player] then return end

	if Name then
		return PlayersData[Player][Name]
	else
		return PlayersData[Player]
	end
end

function PlayersModule.Replace(Player, Name, Value)
	local PlayerData = PlayersData[Player]

	if not PlayerData then return end

	for OtherName, _ in pairs(PlayerData) do
		if OtherName:lower() ~= Name:lower() then continue end
		
		Name = OtherName
		
		break
	end

	PlayerData[Name] = Value

	if Name == "Money" then
		local Leaderstats = Player:WaitForChild("leaderstats")
		local Money = Leaderstats:WaitForChild("Money")

		Money.Value = Format.Number(Value)

		MoneyEvent:FireClient(Player, Value)
	elseif Name == "MoneyPerSecond" then
		local Leaderstats = Player:WaitForChild("leaderstats")
		local MoneyPerSecond = Leaderstats:WaitForChild("$/s")

		MoneyPerSecond.Value = string.format("%s/s", Format.Number(PlayerData.MoneyPerSecond))
		
		local Character = Player.Character
		if not Character then return end
		
		local MoneyPerSecondAttachment = Character.PrimaryPart:FindFirstChild("MoneyPerSecondAttachment")
		local MoneyPerSecondGui = MoneyPerSecondAttachment and MoneyPerSecondAttachment:FindFirstChild("MoneyPerSecondGui")
		
		if not MoneyPerSecondGui then return end

		MoneyPerSecondGui.MoneyPerSecond.Text = MoneyPerSecond.Value
	elseif Name == "Speed" then
		SpeedEvent:FireClient(Player, Value)
		RebirthEvent:FireClient(Player, PlayerData.Rebirths, Value)
		
		ToggleSpeedEvent:FireClient(Player)
	elseif Name == "Carry" then
		CarryEvent:FireClient(Player, Value)
	elseif Name == "Rebirths" then
		RebirthEvent:FireClient(Player, Value, PlayerData.Speed)
		
		PlayerData.Base.Data.DataGui.Rebirths.Text = string.format("Rebirth %s (%sx $)", PlayerData.Rebirths, RebirthsConfigurations[PlayerData.Rebirths].Multiplier)
		
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

		local RebirthMutiplier = RebirthsConfigurations[Value] and RebirthsConfigurations[Value].Multiplier or 1

		MoneyPerSecond = MoneyPerSecond * RebirthMutiplier

		ReplacePlayerDataEvent:Fire(Player, "MoneyPerSecond", MoneyPerSecond)

		PlayerData.Base.Data.DataGui.MoneyPerSecond.Text = string.format("%s/s", Format.Number(MoneyPerSecond))
	elseif Name == "Level" then
		local Base = PlayerData.Base

		Bases.Level(PlayerData, Base)
	elseif Name == "Index" then
		IndexEvent:FireClient(Player, Value)
	end

	PlayersData[Player] = PlayerData
end

function PlayersModule.Animate(Player, AnimationId, Bool)
	local PlayerData = PlayersData[Player]

	if not PlayerData then return end

	local Character = Player.Character or Player.CharacterAdded:Wait()

	local Humanoid = Character:WaitForChild("Humanoid")

	PlayerData.AnimationTracks[Humanoid] = PlayerData.AnimationTracks[Humanoid] or {}

	local Tracks = PlayerData.AnimationTracks[Humanoid]

	local AnimationTrack = Tracks[AnimationId]

	if not AnimationTrack then
		local Animator = Humanoid:FindFirstChildOfClass("Animator")
		if not Animator then
			Animator = Instance.new("Animator")
			Animator.Parent = Humanoid
		end

		local Animation = Instance.new("Animation")
		Animation.AnimationId = AnimationId

		AnimationTrack = Animator:LoadAnimation(Animation)

		Tracks[AnimationId] = AnimationTrack
	end

	if Bool then
		AnimationTrack:Play()
	else
		AnimationTrack:Stop()
	end

	return AnimationTrack
end

function PlayersModule.Create(Player)
	local PlayerData = setmetatable({}, {__index = PlayersModule})

	PlayerData.Player = Player

	PlayerData.AnimationTracks = {}

	PlayerData:Load()

	local Leaderstats = Instance.new("Folder")
	Leaderstats.Name = "leaderstats"
	Leaderstats.Parent = Player

	local Money = Instance.new("StringValue")
	Money.Name = "Money"
	Money.Value = Format.Number(PlayerData.Money)
	Money.Parent = Leaderstats

	local MoneyPerSecond = Instance.new("StringValue")
	MoneyPerSecond.Name = "$/s"
	MoneyPerSecond.Value = string.format("%s/s", Format.Number(PlayerData.MoneyPerSecond))
	MoneyPerSecond.Parent = Leaderstats

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")

	Humanoid.WalkSpeed = PlayerData.Speed

	for _, Descendant in ipairs(Character:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		Descendant.CollisionGroup = "Players"
	end

	Player.CharacterAdded:Connect(function(Character)
		local Humanoid = Character:WaitForChild("Humanoid")

		Humanoid.WalkSpeed = PlayerData.Speed

		for _, Descendant in ipairs(Character:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end

			Descendant.CollisionGroup = "Players"
		end

		local Base = PlayersData[Player].Base
		if not Base then return end

		local YOffset = Character.Humanoid.HipHeight + Character.PrimaryPart.Size.Y / 2
		
		Character:PivotTo(Base.Spawn.CFrame + Vector3.new(0, YOffset, 0))
		
		local MoneyPerSecondAttachment = Instance.new("Attachment")
		MoneyPerSecondAttachment.Name = "MoneyPerSecondAttachment"
		MoneyPerSecondAttachment.Parent = Character.PrimaryPart
		
		local MoneyPerSecondGui = script.Resources:WaitForChild("MoneyPerSecondGui")
		
		MoneyPerSecondGui = MoneyPerSecondGui:Clone()
		
		MoneyPerSecondGui.MoneyPerSecond.Text = MoneyPerSecond.Value
		
		MoneyPerSecondGui.Parent = MoneyPerSecondAttachment
		MoneyPerSecondGui.Enabled = true
		
		MoneyPerSecondAttachment.Position = Vector3.new(0, YOffset + MoneyPerSecondGui.Size.Y.Scale / 2 + 1, 0)
		
		local ProximityPrompt = Instance.new("ProximityPrompt")
		ProximityPrompt.Enabled = false
		ProximityPrompt.ActionText = "Give"
		ProximityPrompt.HoldDuration = 1
		ProximityPrompt.ObjectText = ""
		ProximityPrompt.RequiresLineOfSight = false
		ProximityPrompt.Parent = Character.PrimaryPart

		ProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
			if Player == TriggeringPlayer then return end

			local Character = TriggeringPlayer.Character or TriggeringPlayer.CharacterAdded:Wait()

			local Tool = Character:FindFirstChildOfClass("Tool")
			if not Tool then return end

			local ToolsData = PlayersModule.Retrieve(TriggeringPlayer, "Tools")

			for Index, ToolData in pairs(ToolsData) do
				if ToolData.Tool ~= Tool then continue end

				local Name = ToolData.Name
				local Mutation = ToolData.Mutation
				local Level = ToolData.Level

				local ThingConfiguration = ThingsConfigurations[Name]
				if not ThingConfiguration then return end

				table.remove(ToolsData, Index)

				PlayersModule.Replace(TriggeringPlayer, "Tools", ToolsData)

				Tool:Destroy()

				PlayersModule.Tool(Player, Name, ThingConfiguration, Mutation, Level)

				break
			end
		end)
		
		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if Player == OtherPlayer then return end

				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local Tool = Character:FindFirstChildOfClass("Tool")
				if not Tool then return end

				SetProperties.Client(OtherPlayer, ProximityPrompt, {Enabled = true})
			end)
		end
	end)

	task.spawn(function()
		local BaseData = Bases.Create(PlayerData)

		local Base = BaseData.Base

		PlayersData[Player].Base = Base

		if not Player.Character then return end

		local YOffset = Character.Humanoid.HipHeight + Character.PrimaryPart.Size.Y / 2
		
		Character:PivotTo(Base.Spawn.CFrame + Vector3.new(0, YOffset, 0))
		
		local MoneyPerSecondAttachment = Instance.new("Attachment")
		MoneyPerSecondAttachment.Name = "MoneyPerSecondAttachment"
		MoneyPerSecondAttachment.Parent = Character.PrimaryPart

		local MoneyPerSecondGui = script.Resources:WaitForChild("MoneyPerSecondGui")

		MoneyPerSecondGui = MoneyPerSecondGui:Clone()

		MoneyPerSecondGui.MoneyPerSecond.Text = MoneyPerSecond.Value

		MoneyPerSecondGui.Parent = MoneyPerSecondAttachment
		MoneyPerSecondGui.Enabled = true
		
		MoneyPerSecondAttachment.Position = Vector3.new(0, YOffset + MoneyPerSecondGui.Size.Y.Scale / 2 + 1, 0)
		
		local ProximityPrompt = Instance.new("ProximityPrompt")
		ProximityPrompt.Enabled = false
		ProximityPrompt.ActionText = "Give"
		ProximityPrompt.HoldDuration = 1
		ProximityPrompt.ObjectText = ""
		ProximityPrompt.RequiresLineOfSight = false
		ProximityPrompt.Parent = Character.PrimaryPart

		ProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
			if Player == TriggeringPlayer then return end
			
			local Character = TriggeringPlayer.Character or TriggeringPlayer.CharacterAdded:Wait()

			local Tool = Character:FindFirstChildOfClass("Tool")
			if not Tool then return end

			local ToolsData = PlayersModule.Retrieve(TriggeringPlayer, "Tools")

			for Index, ToolData in pairs(ToolsData) do
				if ToolData.Tool ~= Tool then continue end

				local Name = ToolData.Name
				local Mutation = ToolData.Mutation
				local Level = ToolData.Level

				local ThingConfiguration = ThingsConfigurations[Name]
				if not ThingConfiguration then return end
				
				table.remove(ToolsData, Index)

				PlayersModule.Replace(TriggeringPlayer, "Tools", ToolsData)

				Tool:Destroy()
				
				PlayersModule.Tool(Player, Name, ThingConfiguration, Mutation, Level)
				
				break
			end
		end)
		
		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if Player == OtherPlayer then return end
				
				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local Tool = Character:FindFirstChildOfClass("Tool")
				if not Tool then return end

				SetProperties.Client(OtherPlayer, ProximityPrompt, {Enabled = true})
			end)
		end
	end)

	PlayersData[Player] = PlayerData

	return PlayerData
end

function PlayersModule.Tool(Player, Name, ThingConfiguration, Mutation, Level, Index, ToolData)
	local Data = {}

	local Tool = script.Resources:WaitForChild("Tool")

	Tool = Tool:Clone()

	Data.Tool = Tool
	Data.Name = Name
	Data.Mutation = Mutation
	Data.Level = Level or 1

	local Index = PlayersData[Player] and PlayersData[Player].Index
	if Index and Index[Mutation] and not Index[Mutation][Name] then
		PlayersData[Player].Index[Mutation][Name] = true
		
		IndexEvent:FireClient(Player, PlayersData[Player].Index)
	end
	
	Tool.Equipped:Connect(function()
		local Base = PlayersData[Player] and PlayersData[Player].Base
		if not Base then return end

		local SlotsData = Bases.Retrieve(Base, "SlotsData")
		if not SlotsData then return end

		for _, Slot in ipairs(Base.Slots:GetChildren()) do
			task.spawn(function()
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

				if ThingConfiguration.LuckyBlock then return end
				
				if BaseConfigurations[PlayersData[Player].Level].Slots < tonumber(Slot.Name) then return end

				if SlotsData[Slot.Name] and SlotsData[Slot.Name].Thing then
					SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = true})
				else
					SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = true})
				end
			end)
		end

		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if Player == OtherPlayer then return end
				
				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local ProximityPrompt = Character.PrimaryPart:FindFirstChild("ProximityPrompt")
				if not ProximityPrompt then return end

				SetProperties.Client(Player, ProximityPrompt, {Enabled = true})
			end)
		end
	end)

	if ThingConfiguration.LuckyBlock then
		Tool.Activated:Connect(function()
			local Area = ThingConfiguration.Area
			
			local AreaConfiguration = AreasConfigurations[Area]
			local MutationConfiguration = MutationsConfigurations[Mutation]
			
			LuckyBlockFunction:Invoke(Player, Area, AreaConfiguration, Name, ThingConfiguration, Mutation, MutationConfiguration, Level)
		end)
	end

	Tool.Unequipped:Connect(function()
		local Base = PlayersData[Player].Base
		if not Base then return end

		local SlotsData = Bases.Retrieve(Base, "SlotsData")
		if not SlotsData then return end

		for _, Slot in ipairs(Base.Slots:GetChildren()) do
			task.spawn(function()
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("PlaceProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SwapProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("StealProximityPrompt"), {Enabled = false})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = false})

				if not (SlotsData[Slot.Name] and SlotsData[Slot.Name].Thing) then return end
				if BaseConfigurations[PlayersData[Player].Level].Slots < tonumber(Slot.Name) then return end

				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("GrabProximityPrompt"), {Enabled = true})
				SetProperties.Client(Player, Slot.Spawn.Attachment:WaitForChild("SellProximityPrompt"), {Enabled = true})
			end)
		end
		
		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if Player == OtherPlayer then return end

				local Character = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()

				local ProximityPrompt = Character.PrimaryPart:FindFirstChild("ProximityPrompt")
				if not ProximityPrompt then return end

				SetProperties.Client(Player, ProximityPrompt, {Enabled = false})
			end)
		end
	end)

	Tool.Name = Name
	Tool.ToolTip = Name
	Tool.TextureId = ThingConfiguration.Icons[Mutation]

	if Index and ToolData then
		ToolData.Tool = Tool

		PlayersData[Player].Tools[Index] = ToolData
	else
		local Tools = PlayersData[Player].Tools
		if not Tools then Tools = {} end

		table.insert(Tools, Data)

		PlayersData[Player].Tools = Tools
	end

	Tool.Parent = Player.Backpack

	return Data
end

function PlayersModule:Load()
	local Player = self.Player
	local UserId = Player.UserId

	local Success, Money = pcall(function()
		return MoneyDataStore:GetAsync(UserId)
	end)

	if Success and Money then
		self.Money = Money
	else
		self.Money = GameConfigurations.Defaults.Money
	end

	task.delay(1, function()
		if not PlayersData[Player] then return end

		MoneyEvent:FireClient(Player, self.Money)
	end)

	task.delay(5, function()
		if not PlayersData[Player] then return end

		MoneyEvent:FireClient(Player, PlayersData[Player].Money)
	end)

	local Success, Speed = pcall(function()
		return SpeedDataStore:GetAsync(UserId)
	end)

	if Success and Speed then
		self.Speed = Speed
	else
		self.Speed = GameConfigurations.Defaults.Speed
	end

	task.delay(1, function()
		if not PlayersData[Player] then return end

		SpeedEvent:FireClient(Player, self.Speed)
	end)

	task.delay(5, function()
		if not PlayersData[Player] then return end

		SpeedEvent:FireClient(Player, PlayersData[Player].Speed)
	end)

	local Success, Data = pcall(function()
		return PlayerDataStore:GetAsync(UserId)
	end)

	if Success and Data then
		for Name, Value in pairs(Data) do
			self[Name] = Value
		end
	end

	self.MoneyPerSecond = 0
	
	if not self.Carry then self.Carry = GameConfigurations.Defaults.Carry end
	if not self.Tools then self.Tools = {} end
	if not self.Level then self.Level = 0 end
	if not self.Things then self.Things = {} end
	if not self.Steals then self.Steals = 0 end
	if not self.Rebirths then self.Rebirths = 0 end
	
	for Index, ToolConfiguration in pairs(self.Tools) do
		if ThingsConfigurations[ToolConfiguration.Name] then continue end
		
		table.remove(self.Tools, Index)
	end
	
	for Index, ThingConfiguration in pairs(self.Things) do
		if ThingsConfigurations[ThingConfiguration.Name] then continue end

		table.remove(self.Things, Index)
	end
	
	if not self.Index then
		local Index = {}

		for Mutation, MutationConfiguration in pairs(MutationsConfigurations) do
			Index[Mutation] = {}

			for Thing, ThingConfiguration in pairs(ThingsConfigurations) do
				Index[Mutation][Thing] = false
			end
		end
		
		self.Index = Index
	end
	
	task.delay(1, function()
		if not PlayersData[Player] then return end

		RebirthEvent:FireClient(Player, self.Rebirths, self.Speed)
	end)

	task.delay(5, function()
		if not PlayersData[Player] then return end

		RebirthEvent:FireClient(Player, self.Rebirths, self.Speed)
	end)
	
	task.delay(1, function()
		if not PlayersData[Player] then return end

		CarryEvent:FireClient(Player, self.Carry)
	end)

	task.delay(5, function()
		if not PlayersData[Player] then return end

		CarryEvent:FireClient(Player, PlayersData[Player].Carry)
	end)

	PlayersData[Player] = self

	task.spawn(function()
		for _, Tool in ipairs(Player.Backpack:GetChildren()) do
			if Tool:IsA("Tool") then
				Tool:Destroy()
			end
		end

		for Index, ToolData in ipairs(self.Tools) do
			task.spawn(function()
				local Thing = ToolData.Name
				local ThingConfiguration = ThingsConfigurations[Thing]

				PlayersModule.Tool(Player, Thing, ThingConfiguration, ToolData.Mutation, ToolData.Level, Index, ToolData)
			end)
		end

		Player.CharacterAdded:Connect(function()
			task.wait()

			local PlayerData = PlayersData[Player]
			if not PlayerData then return end

			for Index, ToolData in ipairs(PlayerData.Tools or {}) do
				task.spawn(function()
					local Thing = ToolData.Name
					local ThingConfiguration = ThingsConfigurations[Thing]

					PlayersModule.Tool(Player, Thing, ThingConfiguration, ToolData.Mutation, ToolData.Level, Index, ToolData)
				end)
			end
		end)
	end)

	if UpgradesConfigurations.Speed1.ProductId ~= 3525676618 and math.random() > 0.5 then
		UpgradesConfigurations.Speed1.ProductId = 3525676618
	end

	if UpgradesConfigurations.Speed10.ProductId ~= 3525677009 and math.random() > 0.5 then
		UpgradesConfigurations.Speed10.ProductId = 3525677009
	end

	if UpgradesConfigurations.Carry1.ProductId ~= 3525677349 and math.random() > 0.5 then
		UpgradesConfigurations.Carry1.ProductId = 3525677349
	end
end

function PlayersModule:Save()
	local Player = self.Player
	local UserId = Player.UserId

	pcall(function()
		MoneyDataStore:SetAsync(UserId, self.Money)
	end)

	pcall(function()
		SpeedDataStore:SetAsync(UserId, self.Speed)
	end)

	for Index, ToolData in ipairs(self.Tools) do
		if not ToolData.Tool then continue end

		ToolData.Tool = nil

		self.Tools[Index] = ToolData
	end

	local Data = {
		Carry = self.Carry,
		Tools = self.Tools,
		Level = self.Level,
		Things = self.Things,
		Steals = self.Steals,
		Rebirths = self.Rebirths,
		Index = self.Index
	}

	pcall(function()
		PlayerDataStore:SetAsync(UserId, Data)
	end)

	if PlayersData[Player] and PlayersData[Player].Base then
		Bases.Destroy(PlayersData[Player].Base)
	end

	PlayersData[Player] = nil
end

return PlayersModule
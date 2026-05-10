local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local PlayersModule = require(ServerStorage.Modules:WaitForChild("Players"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))

local Format = require(ReplicatedStorage.Modules:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))
local AreasConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("AreasConfigurations"))
local ThingsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("ThingsConfigurations"))
local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))

local RetrieveThingDataFunction = ServerStorage.Network.BindableFunctions:WaitForChild("RetrieveThingData")
local CreateThingFunction = ServerStorage.Network.BindableFunctions:WaitForChild("CreateThing")
local LuckyBlockFunction = ServerStorage.Network.BindableFunctions:WaitForChild("LuckyBlock")
local AnimateThingEvent = ServerStorage.Network.BindableEvents:WaitForChild("AnimateThing")

local DropEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Drop")

local Things = {}

local ThingsData = {}

function Things.Retrieve(Thing, Name)
	if not ThingsData[Thing] then return end

	if Name then
		return ThingsData[Thing][Name]
	else
		return ThingsData[Thing]
	end
end

function Things.Setup()
	local ThingsFolder = Instance.new("Folder")
	ThingsFolder.Name = "Things"
	ThingsFolder.Parent = workspace

	local LuckyBlocksFolder = Instance.new("Folder")
	LuckyBlocksFolder.Name = "LuckyBlocks"
	LuckyBlocksFolder.Parent = workspace
	
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Things")	

		PhysicsService:CollisionGroupSetCollidable("Things", "Players", false)
		PhysicsService:CollisionGroupSetCollidable("Things", "Things", false)
	end)

	RetrieveThingDataFunction.OnInvoke = Things.Retrieve
	CreateThingFunction.OnInvoke = Things.Create
	LuckyBlockFunction.OnInvoke = Things.LuckyBlock
	
	AnimateThingEvent.Event:Connect(Things.Animate)

	Players.PlayerAdded:Connect(function(Player)
		Player.CharacterRemoving:Connect(function()
			Things.Drop(Player)
		end)
	end)

	workspace.Zones.Zone.Touched:Connect(function(Hit)
		local Character = Hit.Parent
		if not Character then return end

		local Player = Players:GetPlayerFromCharacter(Character)
		if not Player then return end

		Things.Zone(Player)
	end)

	DropEvent.OnServerEvent:Connect(function(Player)
		Things.Drop(Player)
	end)
	
	Players.PlayerRemoving:Connect(function(Player)
		Things.Drop(Player)
	end)
	
	if GameConfigurations.LuckyBlockRollDelay < 0.5 then
		GameConfigurations.LuckyBlockRollDelay = 0.5
	end
	
	for Area, AreaConfiguration in pairs(AreasConfigurations) do
		task.spawn(function()
			local Minimum = AreaConfiguration.Rate and AreaConfiguration.Rate.Minimum and math.clamp(AreaConfiguration.Rate.Minimum, 0.01, math.huge) or 0.01
			local Maximum = AreaConfiguration.Rate and AreaConfiguration.Rate.Maximum and AreaConfiguration.Rate.Maximum or 5

			local Chance = AreaConfiguration.Chance or 1

			while task.wait(math.random(Minimum, Maximum)) do
				if math.random() > Chance then continue end

				local Thing, ThingConfiguration, Mutation, MutationConfiguration, Level = Things.Random(Area)
				if not Thing then continue end

				local Thing = Things.Create(Area, AreaConfiguration, Thing, ThingConfiguration, Mutation, MutationConfiguration, Level)

				ThingsData[Thing]:Spawn()
			end
		end)
		
		if not AreaConfiguration.Guaranteed or AreaConfiguration.Guaranteed <= 0 then continue end
		
		task.spawn(function()
			local GuaranteedArea = script.Resources:WaitForChild("GuaranteedArea")

			GuaranteedArea = GuaranteedArea:Clone()

			local Colour = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

			Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)
			
			GuaranteedArea.Text = string.format("<font color=\"%s\">%s</font> appears in %s", Colour, Area, Format.Time(AreaConfiguration.Guaranteed))
			
			GuaranteedArea.Name = Area
			GuaranteedArea.Parent = workspace.GuaranteedAreas:WaitForChild("GuaranteedAreasGui")
			GuaranteedArea.Visible = true
			
			local Timer = tonumber(AreaConfiguration.Guaranteed)
			
			while task.wait(1) do
				Timer -= 1
				
				GuaranteedArea.Text = string.format("<font color=\"%s\">%s</font> appears in %s", Colour, Area, Format.Time(Timer))
			
				if Timer > 0 then continue end
				
				Timer = tonumber(AreaConfiguration.Guaranteed)
				
				local Thing, ThingConfiguration, Mutation, MutationConfiguration, Level = Things.Random(Area)
				if not Thing then continue end
				
				local Thing = Things.Create(Area, AreaConfiguration, Thing, ThingConfiguration, Mutation, MutationConfiguration, Level)

				ThingsData[Thing]:Spawn()
			end
		end)
	end
end

function Things.Random(Area)
	local AreaThings = {}

	local TotalChance = 0

	for Thing, ThingConfiguration in pairs(ThingsConfigurations) do
		local ThingArea = ThingConfiguration.Area
		
		if not ThingArea or ThingArea ~= Area then continue end

		TotalChance += ThingConfiguration.Chance or 1

		AreaThings[Thing] = ThingConfiguration
	end

	local RandomThing = nil
	local RandomConfiguration = nil

	local Roll = math.random() * TotalChance
	local Sum = 0

	for Thing, ThingConfiguration in pairs(AreaThings) do
		Sum += ThingConfiguration.Chance or 1

		if Roll > Sum then continue end

		RandomThing = Thing
		RandomConfiguration = ThingConfiguration

		break
	end

	if not RandomThing then return end

	TotalChance = 0

	for Mutation, MutationConfiguration in pairs(MutationsConfigurations) do
		local Chance = MutationConfiguration.Chance or 1

		TotalChance += Chance
	end

	local RandomMutation
	local RandomMutationConfiguration

	Roll = math.random() * TotalChance
	Sum = 0

	for Mutation, MutationConfiguration in pairs(MutationsConfigurations) do
		Sum += MutationConfiguration.Chance or 1

		if Roll > Sum then continue end

		RandomMutation = Mutation
		RandomMutationConfiguration = MutationConfiguration

		break
	end

	if not RandomMutation then
		RandomMutation = "Default"
	end

	local Minimum = RandomConfiguration.Level and RandomConfiguration.Level.Minimum and math.clamp(RandomConfiguration.Level.Minimum, 1, RandomConfiguration.LuckyBlock and math.huge or #RandomConfiguration.Levels) or 1
	local Maximum = RandomConfiguration.Level and RandomConfiguration.Level.Maximum and math.clamp(RandomConfiguration.Level.Maximum, 1, RandomConfiguration.LuckyBlock and math.huge or #RandomConfiguration.Levels) or 1
	
	local RandomLevel =  math.random(Minimum, Maximum) or 1
	
	return RandomThing, RandomConfiguration, RandomMutation, RandomMutationConfiguration, RandomLevel
end

function Things.Animate(Thing, AnimationId, Bool)
	if not AnimationId or AnimationId == "" then return end
	
	local Data = ThingsData[Thing]

	if not Data then return end

	local AnimatorOwner = Thing:FindFirstChildOfClass("Humanoid")

	if not AnimatorOwner then
		AnimatorOwner = Thing:FindFirstChildOfClass("AnimationController")

		if not AnimatorOwner then
			AnimatorOwner = Instance.new("AnimationController")
			AnimatorOwner.Parent = Thing
		end
	end

	local Animator = AnimatorOwner:FindFirstChildOfClass("Animator")
	if not Animator then
		Animator = Instance.new("Animator")
		Animator.Parent = AnimatorOwner
	end

	Data.AnimationTracks = Data.AnimationTracks or {}

	Data.AnimationTracks[Animator] = Data.AnimationTracks[Animator] or {}

	local Tracks = Data.AnimationTracks[Animator]

	local AnimationTrack = Tracks[AnimationId]

	if not AnimationTrack then
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

function Things.Drop(Player)
	local Carrying = PlayersModule.Retrieve(Player, "Carrying")
	local Carried = PlayersModule.Retrieve(Player, "Carried")

	if not Carrying or not Carried then return end

	DropEvent:FireClient(Player, false)
	
	for _, Thing in ipairs(Carrying) do
		local ThingConfiguration = ThingsConfigurations[Thing.Name]
		if not ThingConfiguration then return end

		local ThingAttachment = Thing.PrimaryPart:WaitForChild("ThingAttachment")
		local ThingGui = ThingAttachment:WaitForChild("ThingGui")

		ThingGui.Carried.Visible = false

		for _, Descendant in ipairs(Thing:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end

			local Transparency = Descendant:GetAttribute("Transparency")
			if not Transparency then continue end

			Descendant.Transparency = Transparency

			Descendant:SetAttribute("Transparency", nil)
		end

		local ProximityPrompt = Thing.PrimaryPart:FindFirstChild("ProximityPrompt")
		if ProximityPrompt then
			SetProperties.AllClients(ProximityPrompt, {Enabled = true, ActionText = "Carry"})
		end

		ThingsData[Thing].Carried = nil
	end

	for _, Thing in ipairs(Carried) do
		local Data = ThingsData[Thing]
		if not Data then continue end

		local Character = Player.Character or Player.CharacterAdded:Wait()

		local WeldConstraint = Character.PrimaryPart:FindFirstChild("WeldConstraint")
		if WeldConstraint then
			WeldConstraint:Destroy()
		end

		Data:Destroy()
	end

	for _, Thing in ipairs(workspace.Things:GetChildren()) do
		task.spawn(function()
			local OtherProximityPrompt = Thing.PrimaryPart:FindFirstChild("ProximityPrompt")
			if not OtherProximityPrompt then return end

			SetProperties.Client(Player, OtherProximityPrompt, {Enabled = true, ActionText = "Carry"})

			for _, OtherPlayer in ipairs(Players:GetPlayers()) do
				local Carrying = PlayersModule.Retrieve(OtherPlayer, "Carrying")
				if not Carrying then continue end

				if table.find(Carrying, Thing) then return end
			end
		end)
	end

	PlayersModule.Animate(Player, "rbxassetid://71720976335931", false)

	PlayersModule.Replace(Player, "Carrying", nil)
	PlayersModule.Replace(Player, "Carried", nil)
end

function Things.Zone(Player)
	local Carrying = PlayersModule.Retrieve(Player, "Carrying")
	if not Carrying then return end

	Things.Drop(Player)

	for _, Thing in ipairs(Carrying) do
		task.spawn(function()
			local Name = Thing.Name
			local ThingConfiguration = ThingsConfigurations[Name]

			local Data = ThingsData[Thing]
			if not Data then return end

			local Mutation = Data.Mutation
			local Level = Data.Level or 1
			
			Data:Destroy()

			PlayersModule.Tool(Player, Name, ThingConfiguration, Mutation, Level)
		end)
	end
end

function Things.Create(Area, AreaConfiguration, Thing, ThingConfiguration, Mutation, MutationConfiguration, Level)
	Level = Level or 1

	local Data = setmetatable({}, {__index = Things})

	local Thing = ServerStorage.Things:FindFirstChild(Mutation):FindFirstChild(Area):FindFirstChild(Thing)

	if not Thing.PrimaryPart then
		warn(string.format("%s thing has no primary part.", Thing.Name))
	end

	Thing = Thing:Clone()

	Data.Thing = Thing
	Data.Mutation = Mutation
	Data.Level = Level
	Data.AnimationTracks = {}

	for _, Descendant in ipairs(Thing:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end

		Descendant.CollisionGroup = "Things"

		if Descendant == Thing.PrimaryPart then
			Descendant.Anchored = true
		else
			Descendant.Anchored = false
		end
	end

	local ThingAttachment = Instance.new("Attachment")
	ThingAttachment.Name = "ThingAttachment"
	ThingAttachment.Parent = Thing.PrimaryPart

	local ThingGui = script.Resources:WaitForChild("ThingGui")

	ThingGui = ThingGui:Clone()

	ThingGui.Thing.Text = string.format("%s (Lvl %s)", Thing.Name, Level)
	ThingGui.Area.Text = Area

	local Multiplier = MutationConfiguration.Multiplier or 1
	
	if not ThingConfiguration.LuckyBlock then
		ThingGui.Money.Text = string.format("$%s/s", Format.Number((ThingConfiguration.Levels[Level].Money or 0) * Multiplier))
		
		ThingGui.Money.Visible = true
	end
	
	ThingGui.Area.TextColor3 = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

	if Mutation and Mutation ~= "Default" then
		ThingGui.Mutation.Text = Mutation

		ThingGui.Mutation.TextColor3 = MutationConfiguration.Colour or Color3.fromRGB(255, 255, 255)

		ThingGui.Mutation.Visible = true
	end

	ThingGui.Parent = ThingAttachment
	ThingGui.Enabled = true

	ThingAttachment.CFrame = CFrame.new(Vector3.new(0, ThingConfiguration.YOffset + ThingGui.Size.Y.Scale / 2 + 1, 0))

	ThingsData[Thing] = Data

	return Thing
end

function Things.LuckyBlock(Player, Area, AreaConfiguration, Name, ThingConfiguration, Mutation, MutationConfiguration, Level)
	if not PlayersModule.Retrieve(Player, "LuckyBlockZone") then return end
	
	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	local AreaMutationThings = {}

	local Indexs = 0

	local TotalChance = 0

	local MaximumDistance = ThingConfiguration.Distance

	for Thing, ThingConfiguration in pairs(ThingsConfigurations) do
		if ThingConfiguration.Area ~= Area then continue end
		if ThingConfiguration.LuckyBlock then continue end

		TotalChance += ThingConfiguration.Chance or 1

		local Distance = ThingConfiguration.Distance or 0
		if Distance > MaximumDistance then
			MaximumDistance = Distance
		end

		AreaMutationThings[Thing] = ThingConfiguration

		Indexs += 1
	end

	local Roll = math.random() * TotalChance
	local Sum = 0

	local AreaMutationThing
	local AreaMutationThingConfiguration

	for Thing, ThingConfiguration in pairs(AreaMutationThings) do
		Sum += ThingConfiguration.Chance or 1

		if Roll > Sum then continue end

		AreaMutationThing = Thing
		AreaMutationThingConfiguration = ThingConfiguration

		break
	end

	local IndexsToRemove = Indexs - math.clamp(GameConfigurations.LuckyBlockRoll, 1, Indexs)
	if IndexsToRemove > 0 then
		for Index = 1, IndexsToRemove, 1 do
			local Keys = {}

			for Thing in pairs(AreaMutationThings) do
				table.insert(Keys, Thing)
			end

			if #Keys == 0 then break end

			local RandomIndex

			repeat
				RandomIndex = math.random(1, #Keys)
			until Keys[RandomIndex] ~= AreaMutationThing

			local RandomThing = Keys[RandomIndex]

			AreaMutationThings[RandomThing] = nil
		end
	end

	AreaMutationThings[AreaMutationThing] = nil
	
	local Size = workspace.Zones.LuckyBlocks.Size

	local Position

	local NearestDistance = math.huge

	for Attempt = 1, 100 do
		local HalfX = (Size.X / 2) - MaximumDistance
		local HalfZ = (Size.Z / 2) - MaximumDistance

		local X = (math.random() - 0.5) * 2 * HalfX
		local Z = (math.random() - 0.5) * 2 * HalfZ

		local Candidate = workspace.Zones.LuckyBlocks.CFrame.Position + Vector3.new(X, Size.Y / 2, Z)

		local Valid = true

		for _, OtherThing in ipairs(workspace.LuckyBlocks:GetChildren()) do
			local OtherConfiguration = ThingsConfigurations[OtherThing.Name]
			if not OtherConfiguration then continue end

			local RequiredDistance = MaximumDistance + (OtherConfiguration.Distance or 0)

			local Delta = OtherThing.PrimaryPart.Position - Candidate
			local Distance = Vector2.new(Delta.X, Delta.Z).Magnitude

			if Distance < RequiredDistance then
				Valid = false
				break
			end
		end

		if Valid then
			local DeltaToPlayer = Character.PrimaryPart.Position - Candidate
			local DistanceToPlayer = Vector2.new(DeltaToPlayer.X, DeltaToPlayer.Z).Magnitude

			if DistanceToPlayer >= (MaximumDistance + 2) and DistanceToPlayer < NearestDistance then
				NearestDistance = DistanceToPlayer
				Position = Candidate
			end
		end
	end

	if not Position then return end

	local Tool = Character:FindFirstChildOfClass("Tool")
	if not Tool then return end

	local MaximumLevel = 1

	for Level, _ in pairs(AreaMutationThingConfiguration.Levels) do
		if Level <= MaximumLevel then continue end

		MaximumLevel = Level
	end

	local ToolData = {}

	ToolData.Name = AreaMutationThing
	ToolData.Mutation = Mutation
	ToolData.Level = math.clamp(Level, 1, MaximumLevel)

	local Tools = PlayersModule.Retrieve(Player, "Tools")
	if not Tools then Tools = {} end

	table.insert(Tools, ToolData)

	local Index = #Tools

	PlayersModule.Replace(Player, "Tools", Tools)
	
	for Index, ToolData in pairs(Tools) do
		if ToolData.Tool ~= Tool then continue end

		local Name = ToolData.Name
		local Mutation = ToolData.Mutation
		local Level = ToolData.Level

		local ThingConfiguration = ThingsConfigurations[Name]
		if not ThingConfiguration then return end

		table.remove(Tools, Index)

		PlayersModule.Replace(Player, "Tools", Tools)

		Tool:Destroy()

		break
	end
	
	local Thing = Things.Create(Area, AreaConfiguration, Name, ThingConfiguration, Mutation, MutationConfiguration, Level)

	Thing.Parent = workspace:WaitForChild("LuckyBlocks")

	local TargetCFrame = CFrame.new(Position) + Vector3.new(0, ThingConfiguration.YOffset - Size.Y / 2, 0)

	Thing:PivotTo(TargetCFrame)

	local Length = 0
	
	local RollTrack = Things.Animate(Thing, ThingConfiguration.AnimationsIds.Roll)
	if RollTrack then
		RollTrack:Play()

		Length = RollTrack.Length

		if Length == 0 then
			RollTrack:GetPropertyChangedSignal("Length"):Wait()
			Length = RollTrack.Length
		end

		task.wait(Length)

		RollTrack:Stop()
	end
	
	if Length < GameConfigurations.LuckyBlockRollDelay then
		task.wait(GameConfigurations.LuckyBlockRollDelay - Length)
	end
	
	ThingsData[Thing]:Destroy()
	
	for Name, ThingConfiguration in pairs(AreaMutationThings) do
		local MaximumLevel = 1
		
		for Level, _ in pairs(ThingConfiguration.Levels) do
			if Level <= MaximumLevel then continue end
			
			MaximumLevel = Level
		end
		
		local Thing = Things.Create(Area, AreaConfiguration, Name, ThingConfiguration, Mutation, MutationConfiguration, math.clamp(Level, 1, MaximumLevel))
		
		Thing.Parent = workspace:WaitForChild("LuckyBlocks")
		
		Thing:PivotTo(TargetCFrame)
		
		task.wait(GameConfigurations.LuckyBlockRollDelay)
		
		ThingsData[Thing]:Destroy()
	end
	
	
	local Thing = Things.Create(Area, AreaConfiguration, AreaMutationThing, AreaMutationThingConfiguration, Mutation, MutationConfiguration, math.clamp(Level, 1, MaximumLevel))
	
	Thing.Parent = workspace:WaitForChild("LuckyBlocks")

	Thing:PivotTo(TargetCFrame)
	
	task.wait(GameConfigurations.LuckyBlockRollDelay)

	ThingsData[Thing]:Destroy()
	
	PlayersModule.Tool(Player, AreaMutationThing, AreaMutationThingConfiguration, Mutation, math.clamp(Level, 1, MaximumLevel), Index, ToolData)
end

function Things:Spawn()
	local Thing = self.Thing
	
	local ThingConfiguration = ThingsConfigurations[Thing.Name]

	local Area = workspace.Areas:WaitForChild(ThingConfiguration.Area)
	if not Area.PrimaryPart then
		warn("Area has no PrimaryPart:", Area.Name)

		return
	end

	local AreaConfiguration = AreasConfigurations[Area.Name]

	local AreaCFrame = Area.PrimaryPart.CFrame
	local AreaSize = Area.PrimaryPart.Size

	local Position

	for Attempt = 1, 100 do
		local HalfX = (AreaSize.X / 2) - (ThingConfiguration.Distance or 0)
		local HalfZ = (AreaSize.Z / 2) - (ThingConfiguration.Distance or 0)

		local X = (math.random() - 0.5) * 2 * HalfX
		local Z = (math.random() - 0.5) * 2 * HalfZ

		local Candidate = AreaCFrame.Position + Vector3.new(X, AreaSize.Y / 2, Z)

		local Valid = true

		for _, OtherThing in ipairs(workspace.Things:GetChildren()) do
			if OtherThing == Thing then continue end

			local OtherConfiguration = ThingsConfigurations[OtherThing.Name]
			if not OtherConfiguration then continue end

			local RequiredDistance = (ThingConfiguration.Distance or 0) + (OtherConfiguration.Distance or 0)

			local Delta = OtherThing.PrimaryPart.Position - Candidate
			
			local Distance = Vector2.new(Delta.X, Delta.Z).Magnitude

			if Distance < RequiredDistance then
				Valid = false

				break
			end
		end

		if Valid then
			Position = Candidate

			break
		end
	end

	if not Position then
		self:Destroy()

		return
	end

	Thing.Parent = workspace:WaitForChild("Things")

	local TargetCFrame = CFrame.new(Position) + Vector3.new(0, ThingConfiguration.YOffset - Area.PrimaryPart.Size.Y / 2, 0)

	Thing:PivotTo(TargetCFrame)

	local IdleTrack = Things.Animate(Thing, ThingConfiguration.AnimationsIds.Idle, true)

	local ProximityPrompt = Instance.new("ProximityPrompt")
	ProximityPrompt.Enabled = false
	ProximityPrompt.HoldDuration = 1
	ProximityPrompt.ObjectText = Thing.Name
	ProximityPrompt.RequiresLineOfSight = false
	ProximityPrompt.Parent = Thing.PrimaryPart

	SetProperties.AllClients(ProximityPrompt, {Enabled = true, ActionText = "Carry"})

	for _, Player in ipairs(Players:GetPlayers()) do
		local Carrying = PlayersModule.Retrieve(Player, "Carrying")
		if not Carrying then continue end

		local Carried = PlayersModule.Retrieve(Player, "Carried")
		if not Carried then continue end

		if #Carrying < PlayersModule.Retrieve(Player, "Carry") then continue end

		SetProperties.Client(Player, ProximityPrompt, {ActionText = "Drop"})
	end

	ProximityPrompt.Triggered:Connect(function(Player)
		if (self.Time or 0) < 1 then return end
		
		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			if OtherPlayer == Player then continue end

			local Carrying = PlayersModule.Retrieve(OtherPlayer, "Carrying")
			if not Carrying then continue end

			if table.find(Carrying, Thing) then return end
		end

		local Carrying = PlayersModule.Retrieve(Player, "Carrying")
		local Carried = PlayersModule.Retrieve(Player, "Carried")

		if Carrying and #Carrying >= PlayersModule.Retrieve(Player, "Carry") and Carried and #Carried >= PlayersModule.Retrieve(Player, "Carry") then
			Things.Drop(Player)

			return
		elseif Carrying and table.find(Carrying, Thing) and #Carrying < PlayersModule.Retrieve(Player, "Carry") then
			Things.Drop(Player)

			return
		elseif not Carrying and not Carried then
			Carrying = {}
			Carried = {}
		end

		table.insert(Carrying, Thing)

		PlayersModule.Replace(Player, "Carrying", Carrying)

		self.Carried = Player

		ThingsData[Thing] = self

		PlayersModule.Animate(Player, GameConfigurations.AnimationsIds.Carry, true)

		local ThingAttachment = Thing.PrimaryPart:WaitForChild("ThingAttachment")
		local ThingGui = ThingAttachment:WaitForChild("ThingGui")

		ThingGui.Carried.Visible = true

		for _, OtherThing in ipairs(workspace.Things:GetChildren()) do
			task.spawn(function()
				local OtherProximityPrompt = OtherThing.PrimaryPart:FindFirstChild("ProximityPrompt")
				if not OtherProximityPrompt then return end

				if OtherProximityPrompt == ProximityPrompt then
					SetProperties.AllClients(OtherProximityPrompt, {Enabled = false})

					SetProperties.Client(Player, OtherProximityPrompt, {ActionText = "Drop"})

					SetProperties.Client(Player, OtherProximityPrompt, {Enabled = true})

					return
				end

				if #Carrying < PlayersModule.Retrieve(Player, "Carry") then return end

				SetProperties.Client(Player, OtherProximityPrompt, {Enabled = false, ActionText = "Drop"})

				task.wait()

				SetProperties.Client(Player, OtherProximityPrompt, {Enabled = true})
			end)
		end

		for _, Descendant in ipairs(Thing:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end

			if Descendant.Transparency >= 0.5 then continue end

			Descendant:SetAttribute("Transparency", Descendant.Transparency)

			Descendant.Transparency = 0.5
		end

		local Mutation = self.Mutation
		local MutationConfiguration = MutationsConfigurations[Mutation]
		
		local Level = self.Level or 1
		
		local Character = Player.Character or Player.CharacterAdded:Wait()

		local Humanoid = Character:WaitForChild("Humanoid")

		local CarriedThing = Things.Create(Area.Name, AreaConfiguration, Thing.Name, ThingConfiguration, Mutation, MutationConfiguration, Level)

		CarriedThing.Parent = Character.PrimaryPart

		local YOffset = 0

		if Carried and #Carried > 0 then
			for _, OtherThing in ipairs(Carried) do
				local ThingConfiguration = ThingsConfigurations[OtherThing.Name]

				local ThingAttachment = OtherThing.PrimaryPart:WaitForChild("ThingAttachment")
				local ThingGui = ThingAttachment:WaitForChild("ThingGui")

				ThingGui.Enabled = false

				YOffset += ThingConfiguration.YOffset * 2 + 1
			end
		end

		local TargetCFrame = Character.PrimaryPart.CFrame + Vector3.new(0, Humanoid.HipHeight + Character.PrimaryPart.Size.Y / 2 + ThingConfiguration.YOffset + YOffset + 1, 0)

		CarriedThing:PivotTo(TargetCFrame)

		local IdleTrack = Things.Animate(CarriedThing, ThingConfiguration.AnimationsIds.Idle, true)

		local WeldConstraint = Instance.new("WeldConstraint")
		WeldConstraint.Part0 = CarriedThing.PrimaryPart
		WeldConstraint.Part1 = Character.PrimaryPart
		WeldConstraint.Parent = Character.PrimaryPart

		for _, Descendant in ipairs(CarriedThing:GetDescendants()) do
			if Descendant:IsA("BasePart") then
				if not IdleTrack and Descendant ~= CarriedThing.PrimaryPart then
					local WeldConstraint = Instance.new("WeldConstraint")
					WeldConstraint.Part0 = Descendant
					WeldConstraint.Part1 = CarriedThing.PrimaryPart
					WeldConstraint.Parent = Descendant
				end

				Descendant.Massless = true
				Descendant.Anchored = false
				Descendant.CanCollide = false

				if Descendant.Transparency >= 0.5 then continue end

				Descendant.Transparency = 0.5
			elseif Descendant:IsA("Motor6D") then
				if not IdleTrack then
					Descendant.Enabled = false
				end
			end
		end

		local ThingAttachment = CarriedThing.PrimaryPart:WaitForChild("ThingAttachment")
		local ThingGui = ThingAttachment:WaitForChild("ThingGui")

		ThingGui.Carried.Visible = true

		table.insert(Carried, CarriedThing)

		PlayersModule.Replace(Player, "Carried", Carried)
		
		DropEvent:FireClient(Player, true)
	end)

	local ThingAttachment = Thing.PrimaryPart:WaitForChild("ThingAttachment")
	local ThingGui = ThingAttachment:WaitForChild("ThingGui")

	local Time = ThingConfiguration.Time or 10

	ThingGui.Time.Text = Format.Time(Time)

	self.Time = Time

	task.spawn(function()
		while Thing and Thing.Parent do
			while self.Carried do
				task.wait(0.01)

				if not Thing or not Thing.Parent then return end
			end

			task.wait(1)

			if not Thing or not Thing.Parent then break end

			Time -= 1

			if Time <= 0 then
				self:Destroy()

				break
			end

			ThingGui.Time.Text = Format.Time(Time)
		end
	end)

	ThingGui.Time.Visible = true
end

function Things:Destroy()
	local Thing = self.Thing

	Thing:Destroy()
	Thing = nil

	if not ThingsData[Thing] then return end

	ThingsData[Thing] = nil
end

return Things

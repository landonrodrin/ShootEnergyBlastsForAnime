local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local PlayersModule = require(ServerStorage.Modules:WaitForChild("Players"))
local Anime = require(ServerStorage.Modules:WaitForChild("Anime"))
local ToolsConfigurations = require(ServerStorage.Configurations.Modules:WaitForChild("ToolsConfigurations"))

local Tools = {}
local SetupTrove = Trove.new()
local PlayerTroves = {}
local ToolTroves = {}

local function cleanupPlayer(Player)
	local PlayerTrove = PlayerTroves[Player]
	if PlayerTrove then
		PlayerTrove:Destroy()
		PlayerTroves[Player] = nil
	end
end

local function setupPlayer(Player)
	cleanupPlayer(Player)

	local PlayerTrove = SetupTrove:Extend()
	PlayerTroves[Player] = PlayerTrove

	PlayerTrove:Add(function()
		if PlayerTroves[Player] == PlayerTrove then
			PlayerTroves[Player] = nil
		end
	end)

	PlayerTrove:Connect(Player.CharacterAdded, function()
		Tools.Load(Player)
	end)

	if Player.Character then
		Tools.Load(Player)
	end
end

function Tools.Setup()
	SetupTrove:Clean()
	table.clear(PlayerTroves)
	table.clear(ToolTroves)

	SetupTrove:Connect(Players.PlayerAdded, setupPlayer)
	SetupTrove:Connect(Players.PlayerRemoving, cleanupPlayer)

	for _, Player in ipairs(Players:GetPlayers()) do
		setupPlayer(Player)
	end
end

function Tools.Fling(TargetPlayer, Player, Power)
	local TargetCharacter = TargetPlayer.Character
	local Character = Player.Character
	
	if not TargetCharacter or not Character then return end

	local TargetHumanoidRootPart = TargetCharacter:FindFirstChild("HumanoidRootPart")
	local TargetHumanoid = TargetCharacter:FindFirstChild("Humanoid")
	
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	
	if not TargetHumanoidRootPart or not TargetHumanoid or not HumanoidRootPart then return end

	TargetHumanoid.Sit = true

	local Direction = (TargetHumanoidRootPart.Position - HumanoidRootPart.Position).Unit
	
	local BodyVelocity = Instance.new("BodyVelocity")

	BodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	BodyVelocity.Velocity = (Direction + Vector3.new(0, 1, 0)).Unit * Power
	BodyVelocity.P = 1e4
	BodyVelocity.Parent = TargetHumanoidRootPart
	
	Debris:AddItem(BodyVelocity, 0.35)

	local BodyAngularVelocity = Instance.new("BodyAngularVelocity")

	BodyAngularVelocity.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	BodyAngularVelocity.AngularVelocity = Vector3.new(1, 1, 1) * math.pi * math.random(1, 4)
	BodyAngularVelocity.P = 5000
	BodyAngularVelocity.Parent = TargetHumanoidRootPart
	
	Debris:AddItem(BodyAngularVelocity, 0.35)

	local HumanoidTrove = Trove.new()
	HumanoidTrove:Connect(TargetHumanoid.Destroying, function()
		HumanoidTrove:Destroy()
	end)

	HumanoidTrove:Add(task.delay(0.5, function()
		if TargetHumanoid then
			TargetHumanoid.Sit = false
		end

		HumanoidTrove:Destroy()
	end))
end

function Tools.Create(Player, Name, ToolConfiguration)
	local Backpack = Player:WaitForChild("Backpack")

	local Character = Player.Character
	if not Character or not Character:IsDescendantOf(workspace) then return end
	
	if Backpack:FindFirstChild(Name) or Character:FindFirstChild(Name) then return end
	
	local Tool = ServerStorage.Tools:FindFirstChild(Name)

	local Tool = Tool:Clone()
	local ToolTrove = Trove.new()
	local ToolAlive = true
	ToolTroves[Tool] = ToolTrove

	local PlayerTrove = PlayerTroves[Player]
	if PlayerTrove then
		PlayerTrove:Add(ToolTrove)
	end

	ToolTrove:Add(function()
		ToolAlive = false

		if ToolTroves[Tool] == ToolTrove then
			ToolTroves[Tool] = nil
		end
	end)
	
	Tool.ToolTip = ToolConfiguration.Description or ""
	Tool.TextureId = ToolConfiguration.Icon or ""
	Tool.CanBeDropped = false
	
	Tool.Name = Name
	Tool.Parent = Backpack
	
	local Equipped = false
	local Activated = false
	local Animating = false
	local Cooldown = false

	ToolTrove:Connect(Tool.Destroying, function()
		ToolTrove:Destroy()
	end)

	ToolTrove:Connect(Tool.Equipped, function()
		Equipped = true
		Activated = false
	end)

	ToolTrove:Connect(Tool.Unequipped, function()
		Equipped = false
		Activated = false
	end)

	ToolTrove:Connect(Tool.Activated, function()
		if not Equipped or Activated or Animating or Cooldown then return end

		Activated = true
		Cooldown = true
		
		local AnimationId = ToolConfiguration.AnimationId
		
		local ActivationTrack = AnimationId and PlayersModule.Animate(Player, AnimationId, true)
		if ActivationTrack then Animating = true end

		local Length = tonumber(ActivationTrack and ActivationTrack.Length) or 0

		local ActivationThread = task.delay(Length, function()
			if not ToolAlive then return end

			Activated = false
			Animating = false

			local CooldownThread = task.delay(tonumber(ToolConfiguration.Cooldown) or 0, function()
				if not ToolAlive then return end

				Cooldown = false
			end)

			if ToolAlive then
				ToolTrove:Add(CooldownThread)
			end
		end)

		ToolTrove:Add(ActivationThread)
	end)

	for _, Descendant in ipairs(Tool:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			Descendant.Massless = true

			ToolTrove:Connect(Descendant.Touched, function(Hit)
				if not Activated then return end

				local TouchingPlayer = Players:GetPlayerFromCharacter(Hit.Parent)
				if not TouchingPlayer or TouchingPlayer == Player then return end

				Activated = false

				local Power = tonumber(ToolConfiguration.Power)
				if Power and Power > 0 then
					Tools.Fling(TouchingPlayer, Player, Power)
				end

				if ToolConfiguration.ReturnCarriedAnime then
					Anime.Drop(TouchingPlayer)
				end
			end)
		end
	end
end

function Tools.Load(Player)
	local PlayerTrove = PlayerTroves[Player]

	for Name, ToolConfiguration in pairs(ToolsConfigurations) do
		local Thread = task.spawn(Tools.Create, Player, Name, ToolConfiguration)
		if PlayerTrove then
			PlayerTrove:Add(Thread)
		end
	end
end

return Tools

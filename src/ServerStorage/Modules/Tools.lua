local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local PlayersModule = require(ServerStorage.Modules:WaitForChild("Players"))
local Things = require(ServerStorage.Modules:WaitForChild("Things"))
local ToolsConfigurations = require(ServerStorage.Configurations.Modules:WaitForChild("ToolsConfigurations"))

local Tools = {}

function Tools.Setup()
	Players.PlayerAdded:Connect(function(Player)
		Player.CharacterAdded:Connect(function()
			Tools.Load(Player)
		end)
		
		if not Player.Character then return end
		
		Tools.Load(Player)
	end)
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

	task.delay(0.5, function()
		if TargetHumanoid then
			TargetHumanoid.Sit = false
		end
	end)
end

function Tools.Create(Player, Name, ToolConfiguration)
	local Backpack = Player:WaitForChild("Backpack")

	local Character = Player.Character
	if not Character or not Character:IsDescendantOf(workspace) then return end
	
	if Backpack:FindFirstChild(Name) or Character:FindFirstChild(Name) then return end
	
	local Tool = ServerStorage.Tools:FindFirstChild(Name)

	local Tool = Tool:Clone()
	
	Tool.ToolTip = ToolConfiguration.Description or ""
	Tool.TextureId = ToolConfiguration.Icon or ""
	Tool.CanBeDropped = false
	
	Tool.Name = Name
	Tool.Parent = Backpack
	
	local Equipped = false
	local Activated = false
	local Animating = false
	local Cooldown = false

	Tool.Equipped:Connect(function()
		Equipped = true
		Activated = false
	end)

	Tool.Unequipped:Connect(function()
		Equipped = false
		Activated = false
	end)

	Tool.Activated:Connect(function()
		if not Equipped or Activated or Animating or Cooldown then return end

		Activated = true
		Cooldown = true
		
		local AnimationId = ToolConfiguration.AnimationId
		
		local ActivationTrack = AnimationId and PlayersModule.Animate(Player, AnimationId, true)
		if ActivationTrack then Animating = true end

		local Length = tonumber(ActivationTrack and ActivationTrack.Length) or 0

		task.delay(Length, function()
			Activated = false
			Animating = false

			task.delay(tonumber(ToolConfiguration.Cooldown) or 0, function()
				Cooldown = false
			end)
		end)
	end)

	for _, Descendant in ipairs(Tool:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			Descendant.Massless = true

			Descendant.Touched:Connect(function(Hit)
				if not Activated then return end

				local TouchingPlayer = Players:GetPlayerFromCharacter(Hit.Parent)
				if not TouchingPlayer or TouchingPlayer == Player then return end

				Activated = false

				local Power = tonumber(ToolConfiguration.Power)
				if Power and Power > 0 then
					Tools.Fling(TouchingPlayer, Player, Power)
				end

				if ToolConfiguration.ReturnCarriedThings then
					Things.Drop(TouchingPlayer)
				end
			end)
		end
	end
end

function Tools.Load(Player)
	for Name, ToolConfiguration in pairs(ToolsConfigurations) do
		task.spawn(Tools.Create, Player, Name, ToolConfiguration)
	end
end

return Tools

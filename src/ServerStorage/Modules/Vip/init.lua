local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))

local GameConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("GameConfigurations"))

local Vip = {}
local SetupTrove = Trove.new()

local function setupPlayerPasses(Player)
	local Success, Result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, GameConfigurations.PassesIds.Vip)
	end)

	if Success and Result then
		Vip.Player(Player, "Vip")
	end

	local Success, Result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, GameConfigurations.PassesIds.VipPlus)
	end)

	if Success and Result then
		Vip.Player(Player, "VipPlus")
	end
end

function Vip.Setup()
	SetupTrove:Clean()

	for _, Descendant in pairs(workspace.Zones.Vip:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end
		
		if Descendant.Name == "Vip" then
			local VipGui = script.Resources:WaitForChild("VipGui")

			VipGui = VipGui:Clone()

			VipGui.Parent = Descendant
			VipGui.Enabled = true
			SetupTrove:Add(VipGui)
		elseif Descendant.Name == "Zone" then
			SetupTrove:Connect(Descendant.Touched, function(Hit)
				local Player = Players:GetPlayerFromCharacter(Hit.Parent)
				if not Player then return end
				
				Vip.Purchase(Player, "Vip")
			end)
		end
	end
	
	for _, Descendant in pairs(workspace.Zones.VipPlus:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end
		
		if Descendant.Name == "VipPlus" then
			local VipPlusGui = script.Resources:WaitForChild("VipPlusGui")

			VipPlusGui = VipPlusGui:Clone()

			VipPlusGui.Parent = Descendant
			VipPlusGui.Enabled = true
			SetupTrove:Add(VipPlusGui)
		elseif Descendant.Name == "Zone" then
			SetupTrove:Connect(Descendant.Touched, function(Hit)
				local Player = Players:GetPlayerFromCharacter(Hit.Parent)
				if not Player then return end

				Vip.Purchase(Player, "VipPlus")
			end)
		end
	end

	SetupTrove:Connect(Players.PlayerAdded, setupPlayerPasses)

	for _, Player in ipairs(Players:GetPlayers()) do
		setupPlayerPasses(Player)
	end
	
	SetupTrove:Connect(MarketplaceService.PromptGamePassPurchaseFinished, function(Player, GamepassId, WasPurchased)
		if not WasPurchased then return end

		if GamepassId == GameConfigurations.PassesIds.Vip then
			Vip.Player(Player, "Vip")
		elseif GameConfigurations.PassesIds.VipPlus then
			Vip.Player(Player, "VipPlus")
		end
	end)
end

function Vip.Purchase(Player, Type)
	local GamepassId = GameConfigurations.PassesIds[Type]
	if not GamepassId then return end

	local Success, Result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, GamepassId)
	end)

	if Success and Result then
		Vip.Player(Player, Type)
		
		return
	end

	MarketplaceService:PromptGamePassPurchase(Player, GamepassId)
end

function Vip.Player(Player, Type)
	for _, Descendant in pairs(workspace.Zones[Type]:GetDescendants()) do
		if not Descendant:IsA("BasePart") then continue end
		if Descendant.Name ~= "Zone" then continue end
		
		SetProperties.Client(Player, Descendant, {CanCollide = false})
	end
end

return Vip

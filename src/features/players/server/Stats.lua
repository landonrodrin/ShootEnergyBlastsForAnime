return function(ctx)
	local Bases = ctx.Bases
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local Packets = ctx.Packets
	local PlayersData = ctx.PlayersData
	local PlayersModule = ctx.PlayersModule
	local MoneyPerSecondLeaderstatUpdates = ctx.MoneyPerSecondLeaderstatUpdates
	local normalizeHotbarOrder = ctx.normalizeHotbarOrder
	local syncInventory = ctx.syncInventory
local MONEY_PER_SECOND_LEADERSTAT_INTERVAL = 60

local function isHoldAnimation(AnimationId)
	return AnimationId == GameConfigurations.AnimationsIds.Carry
		or AnimationId == GameConfigurations.AnimationsIds.OwnedHold
end

local function updateMoneyPerSecondLeaderstat(Player, PlayerData)
	local Now = os.clock()
	local LastUpdate = MoneyPerSecondLeaderstatUpdates[Player]

	if LastUpdate and Now - LastUpdate < MONEY_PER_SECOND_LEADERSTAT_INTERVAL then
		return
	end

	MoneyPerSecondLeaderstatUpdates[Player] = Now

	local Leaderstats = Player:WaitForChild("leaderstats")
	local MoneyPerSecond = Leaderstats:WaitForChild("$/s")

	MoneyPerSecond.Value = string.format("%s/s", Format.Number(PlayerData.MoneyPerSecond))
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

		Packets.money.sendTo(Value, Player)
	elseif Name == "MoneyPerSecond" then
		updateMoneyPerSecondLeaderstat(Player, PlayerData)

		if PlayerData.Base then
			Bases.UpdateIncomeDisplay(PlayerData.Base, PlayerData.MoneyPerSecond)
		end
	elseif Name == "Speed" then
		Packets.speed.sendTo(Value, Player)
		Packets.rebirth.sendTo({
			Rebirths = PlayerData.Rebirths,
			Speed = Value,
		}, Player)

		if ctx.applyPlayerMovementSpeed then
			ctx.applyPlayerMovementSpeed(Player)
		end
	elseif Name == "Carry" then
		Packets.carry.sendTo(Value, Player)
	elseif Name == "Rebirths" then
		Packets.rebirth.sendTo({
			Rebirths = Value,
			Speed = PlayerData.Speed,
		}, Player)

		if Bases.RefreshPlayerEconomy then
			Bases.RefreshPlayerEconomy(Player)
		else
			Bases.RefreshPlayerEconomyDisplays(Player)
		end

		syncInventory(Player)
	elseif Name == "Level" then
		local Base = PlayerData.Base

		if Base then
			Bases.Level(PlayerData, Base)
		end
	elseif Name == "Index" then
		Packets.indexSync.sendTo({
			Index = Value,
		}, Player)
	elseif Name == "Tools" then
		if ctx.clearEquippedInventoryTool then
			ctx.clearEquippedInventoryTool(Player)
		end
		normalizeHotbarOrder(PlayerData)
		task.defer(syncInventory, Player)
	end

	PlayersData[Player] = PlayerData
end

function PlayersModule.Animate(Player, AnimationId, Bool)
	local PlayerData = PlayersData[Player]

	if not PlayerData then return end
	if not AnimationId or AnimationId == "" then return end

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

		local Success, Result = pcall(function()
			return Animator:LoadAnimation(Animation)
		end)

		Animation:Destroy()

		if not Success then
			warn(string.format("Failed to load animation %s for %s: %s", tostring(AnimationId), Player.Name, tostring(Result)))
			return
		end

		AnimationTrack = Result

		if isHoldAnimation(AnimationId) then
			AnimationTrack.Looped = true
			AnimationTrack.Priority = Enum.AnimationPriority.Action4
		end

		Tracks[AnimationId] = AnimationTrack
	end

	if Bool then
		if isHoldAnimation(AnimationId) then
			AnimationTrack.Looped = true
			AnimationTrack.Priority = Enum.AnimationPriority.Action4
			AnimationTrack:Play(0.1, 1, 1)
		else
			AnimationTrack:Play()
		end
	else
		AnimationTrack:Stop(0.1)
	end

	return AnimationTrack
end
end

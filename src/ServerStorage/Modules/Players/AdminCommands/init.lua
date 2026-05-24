return function(ctx)
	local ReplicatedStorage = ctx.ReplicatedStorage
	local ServerStorage = ctx.ServerStorage
	local Bases = ctx.Bases
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local CommandsConfigurations = require(ServerStorage.Configurations.Modules:WaitForChild("CommandsConfigurations"))
	local Packets = ctx.Packets
	local PlayersData = ctx.PlayersData
	local PlayersModule = ctx.PlayersModule
	local AdminCommandDebounces = ctx.AdminCommandDebounces
	local ADMIN_RICH_MONEY = ctx.ADMIN_RICH_MONEY
	local ADMIN_FAST_SPEED = ctx.ADMIN_FAST_SPEED
	local BASE_PROGRESSION_VERSION = ctx.BASE_PROGRESSION_VERSION
	local removeHeldModel = ctx.removeHeldModel
	local reconcileIndex = ctx.reconcileIndex
	local cleanupToolData = ctx.cleanupToolData

	local Actions = require(script:WaitForChild("Actions"))

	local function findCmdrPackage()
		local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
		if not Packages then
			error("Missing ReplicatedStorage.Packages; run wally install and restart the Rojo sync.", 0)
		end

		local Direct = Packages:FindFirstChild("cmdr")
		if Direct then
			return Direct
		end

		local PackageIndex = Packages:FindFirstChild("_Index")
		if PackageIndex then
			for _, Child in ipairs(PackageIndex:GetChildren()) do
				if Child.Name:sub(1, #"evaera_cmdr@") == "evaera_cmdr@" then
					local Cmdr = Child:FindFirstChild("cmdr")
					if Cmdr then
						return Cmdr
					end
				end
			end
		end

		error("Missing ReplicatedStorage.Packages.cmdr or ReplicatedStorage.Packages._Index.evaera_cmdr@*.cmdr; run wally install and restart the Rojo sync.", 0)
	end

	local function isWhitelistedCommandPlayer(Player)
		for _, UserId in ipairs(CommandsConfigurations.Whitelist or {}) do
			if Player.UserId == UserId then
				return true
			end
		end

		return false
	end

	local function isAdminCommandDebounced(Player, Command)
		local Now = os.clock()

		AdminCommandDebounces[Player] = AdminCommandDebounces[Player] or {}

		if AdminCommandDebounces[Player][Command] and Now - AdminCommandDebounces[Player][Command] < 1 then
			return true
		end

		AdminCommandDebounces[Player][Command] = Now

		return false
	end

	local function destroyPlayerTools(Player, PlayerData)
		for _, ToolData in ipairs(PlayerData.Tools or {}) do
			cleanupToolData(ToolData)
		end

		local Backpack = Player:FindFirstChildOfClass("Backpack")
		if Backpack then
			for _, Child in ipairs(Backpack:GetChildren()) do
				if Child:IsA("Tool") then
					Child:Destroy()
				end
			end
		end

		local Character = Player.Character
		if Character then
			for _, Child in ipairs(Character:GetChildren()) do
				if Child:IsA("Tool") then
					Child:Destroy()
				end
			end
		end
	end

	local function clearBaseProgress(PlayerData)
		local Base = PlayerData.Base
		if not Base then return end

		for _, Slot in ipairs(Bases.GetSlots(Base)) do
			Bases.Remove(Base, Slot, true)
		end

		local Level = Bases.GetBaseLevelPart(Base)
		if Level then
			for _, GuiName in ipairs({"BaseLevelGui", "BaseLevelGuiFront", "BaseLevelGuiBack"}) do
				local BaseLevelGui = Level:FindFirstChild(GuiName)
				if BaseLevelGui then
					BaseLevelGui:Destroy()
				end
			end

			local LevelGui = Level:FindFirstChild("LevelGui")
			if LevelGui then
				LevelGui:Destroy()
			end
		end
	end

	local function resetPlayerProgress(Player)
		local PlayerData = PlayersData[Player]
		if not PlayerData then
			return "Player data is still loading."
		end

		if isAdminCommandDebounced(Player, "reset") then
			return "Reset is on cooldown."
		end

		removeHeldModel(Player)
		destroyPlayerTools(Player, PlayerData)
		clearBaseProgress(PlayerData)

		PlayersModule.Replace(Player, "Anime", {})
		PlayersModule.Replace(Player, "Tools", {})
		PlayersModule.Replace(Player, "HotbarOrder", {})
		PlayersModule.Replace(Player, "Index", reconcileIndex(nil))
		PlayersModule.Replace(Player, "Steals", 0)
		PlayersModule.Replace(Player, "Money", GameConfigurations.Defaults.Money)
		PlayersModule.Replace(Player, "Speed", GameConfigurations.Defaults.Speed)
		PlayersModule.Replace(Player, "Carry", GameConfigurations.Defaults.Carry)
		PlayersModule.Replace(Player, "Rebirths", 0)
		PlayersModule.Replace(Player, "Level", 1)
		PlayersModule.Replace(Player, "MoneyPerSecond", 0)
		PlayerData.BaseProgressionVersion = BASE_PROGRESSION_VERSION

		local Character = Player.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid.WalkSpeed = GameConfigurations.Defaults.Speed
		end

		print(string.format("Owner reset executed for %s (%d)", Player.Name, Player.UserId))
		Packets.announcement.sendTo({
			Text = "Testing progress reset.",
			Colour = Packets.EncodeColour(Color3.fromRGB(0, 255, 0)),
		}, Player)

		return "Testing progress reset."
	end

	local function grantRichMoney(Player)
		local PlayerData = PlayersData[Player]
		if not PlayerData then
			return "Player data is still loading."
		end

		if isAdminCommandDebounced(Player, "rich") then
			return "Rich is on cooldown."
		end

		PlayersModule.Replace(Player, "Money", ADMIN_RICH_MONEY)

		print(string.format("Owner rich command executed for %s (%d)", Player.Name, Player.UserId))
		Packets.announcement.sendTo({
			Text = string.format("Money set to $%s.", Format.Number(ADMIN_RICH_MONEY)),
			Colour = Packets.EncodeColour(Color3.fromRGB(0, 255, 0)),
		}, Player)

		return string.format("Money set to $%s.", Format.Number(ADMIN_RICH_MONEY))
	end

	local function grantFastSpeed(Player)
		local PlayerData = PlayersData[Player]
		if not PlayerData then
			return "Player data is still loading."
		end

		if isAdminCommandDebounced(Player, "fast") then
			return "Fast is on cooldown."
		end

		PlayersModule.Replace(Player, "Speed", ADMIN_FAST_SPEED)

		local Character = Player.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid.WalkSpeed = ADMIN_FAST_SPEED
		end

		print(string.format("Owner fast command executed for %s (%d)", Player.Name, Player.UserId))
		Packets.announcement.sendTo({
			Text = string.format("Speed set to %s.", ADMIN_FAST_SPEED),
			Colour = Packets.EncodeColour(Color3.fromRGB(0, 255, 0)),
		}, Player)

		return string.format("Speed set to %s.", ADMIN_FAST_SPEED)
	end

	local function setupCmdr()
		local Cmdr = require(findCmdrPackage())

		Cmdr:RegisterCommandsIn(script:WaitForChild("Commands"))
		Cmdr.Registry:RegisterHook("BeforeRun", function(CommandContext)
			if CommandContext.Group ~= "Owner" then
				return nil
			end

			if not CommandContext.Executor or not isWhitelistedCommandPlayer(CommandContext.Executor) then
				return "You do not have permission to run this command."
			end

			return nil
		end)

		print("Owner Cmdr commands registered: reset, rich, fast")
	end

	Actions.Reset = resetPlayerProgress
	Actions.Rich = grantRichMoney
	Actions.Fast = grantFastSpeed

	setupCmdr()

	ctx.destroyPlayerTools = destroyPlayerTools
	ctx.clearBaseProgress = clearBaseProgress
	ctx.isWhitelistedCommandPlayer = isWhitelistedCommandPlayer
end

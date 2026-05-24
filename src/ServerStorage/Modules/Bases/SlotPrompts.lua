return function(ctx)
	local MarketplaceService = ctx.MarketplaceService
	local Players = ctx.Players
	local HttpService = ctx.HttpService
	local SetProperties = ctx.SetProperties
	local Grounding = ctx.Grounding
	local Trove = ctx.Trove
	local Format = ctx.Format
	local GameConfigurations = ctx.GameConfigurations
	local BaseConfigurations = ctx.BaseConfigurations
	local AreasConfigurations = ctx.AreasConfigurations
	local AnimeConfigurations = ctx.AnimeConfigurations
	local MutationsConfigurations = ctx.MutationsConfigurations
	local RebirthsConfigurations = ctx.RebirthsConfigurations
	local RetrieveAnimeDataFunction = ctx.RetrieveAnimeDataFunction
	local CreateAnimeFunction = ctx.CreateAnimeFunction
	local RetrievePlayerDataFunction = ctx.RetrievePlayerDataFunction
	local AnimateAnimeEvent = ctx.AnimateAnimeEvent
	local ReplacePlayerDataEvent = ctx.ReplacePlayerDataEvent
	local CreateToolEvent = ctx.CreateToolEvent
	local LevelEvent = ctx.LevelEvent
	local AnnouncementEvent = ctx.AnnouncementEvent
	local Packets = ctx.Packets
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
	local updateBaseAnimeMoneyText = ctx.updateBaseAnimeMoneyText
	local updateBaseSlotSellPrompt = ctx.updateBaseSlotSellPrompt
	local updateBaseInfoMoneyPerSecond = ctx.updateBaseInfoMoneyPerSecond
	local createBaseInfoGui = ctx.createBaseInfoGui
	local removeLegacyBaseInfoGuis = ctx.removeLegacyBaseInfoGuis
	local removeBaseLevelGuis = ctx.removeBaseLevelGuis
	local BASE_SELL_SUCCESS_COLOUR = Color3.fromRGB(95, 255, 140)
	local PromptTroves = {}

local function applyOccupiedSlotPromptState(Player, Slot, AnimeConfiguration, Level, Mutation, RebirthMultiplier)
	local SlotSpawn = getSlotSpawn(Slot)
	local SlotAttachment = getSlotAttachment(Slot)
	if not (SlotSpawn and SlotAttachment) then return false end

	local GrabProximityPrompt = SlotAttachment:FindFirstChild("GrabProximityPrompt")
	local PlaceProximityPrompt = SlotAttachment:FindFirstChild("PlaceProximityPrompt")
	local SwapProximityPrompt = SlotAttachment:FindFirstChild("SwapProximityPrompt")
	local StealProximityPrompt = SlotAttachment:FindFirstChild("StealProximityPrompt")
	local SellProximityPrompt = SlotAttachment:FindFirstChild("SellProximityPrompt")

	if not (GrabProximityPrompt and PlaceProximityPrompt and SwapProximityPrompt and StealProximityPrompt and SellProximityPrompt) then
		return false
	end

	SlotAttachment.Position = Vector3.new(0, (AnimeConfiguration.YOffset or 3) - SlotSpawn.Size.Y / 2, 0)

	GrabProximityPrompt.ActionText = PICK_UP_PROMPT_TEXT
	updateBaseSlotSellPrompt(Slot, AnimeConfiguration, Level, Mutation, RebirthMultiplier)

	local SetNonOwnerProperties = SetProperties.AllClientsExcept or function(_, Object, Properties)
		SetProperties.AllClients(Object, Properties)
	end

	SetNonOwnerProperties(Player, GrabProximityPrompt, {Enabled = false})
	SetNonOwnerProperties(Player, PlaceProximityPrompt, {Enabled = false})
	SetNonOwnerProperties(Player, SwapProximityPrompt, {Enabled = false})
	SetNonOwnerProperties(Player, StealProximityPrompt, {Enabled = true})
	SetNonOwnerProperties(Player, SellProximityPrompt, {Enabled = false})

	SetProperties.Client(Player, StealProximityPrompt, {Enabled = false})
	SetProperties.Client(Player, PlaceProximityPrompt, {Enabled = false})
	SetProperties.Client(Player, SwapProximityPrompt, {Enabled = false})
	SetProperties.Client(Player, GrabProximityPrompt, {Enabled = true})
	SetProperties.Client(Player, SellProximityPrompt, {Enabled = true})

	return true
end

function Bases.Setup()
	for _, Base in ipairs(workspace.Bases:GetChildren()) do
		for _, Slot in ipairs(getOrderedSlots(Base)) do
			do
				local SlotSpawn = getSlotSpawn(Slot)
				if not (SlotSpawn and SlotSpawn:IsA("BasePart")) then continue end

				if PromptTroves[Slot] then
					PromptTroves[Slot]:Destroy()
					PromptTroves[Slot] = nil
				end

				local PromptTrove = Trove.new()
				PromptTroves[Slot] = PromptTrove

				PromptTrove:Add(function()
					if PromptTroves[Slot] == PromptTrove then
						PromptTroves[Slot] = nil
					end
				end)

				local Attachment = PromptTrove:Add(Instance.new("Attachment"))
				Attachment.Position = Vector3.new(0, 3 - SlotSpawn.Size.Y / 2, 0)
				Attachment.Parent = SlotSpawn

				PromptTrove:Connect(SlotSpawn.Destroying, function()
					PromptTrove:Destroy()
				end)

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
				PlaceProximityPrompt.MaxActivationDistance = BASE_SLOT_PLACE_PROMPT_MAX_ACTIVATION_DISTANCE
				PlaceProximityPrompt.Name = "PlaceProximityPrompt"
				PlaceProximityPrompt.Parent = Attachment

				local SwapProximityPrompt = Instance.new("ProximityPrompt")
				SwapProximityPrompt.Enabled = false
				SwapProximityPrompt.ActionText = "Swap"
				SwapProximityPrompt.HoldDuration = BASE_SLOT_PROMPT_HOLD_DURATION
				SwapProximityPrompt.ObjectText = ""
				SwapProximityPrompt.RequiresLineOfSight = false
				SwapProximityPrompt.MaxActivationDistance = BASE_SLOT_PLACE_PROMPT_MAX_ACTIVATION_DISTANCE
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

				PromptTrove:Connect(GrabProximityPrompt.Triggered, function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player ~= TriggeringPlayer then return end

					local Anime = BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Anime
					if not Anime then return end

					local Name = Anime.Name

					local AnimeConfiguration = AnimeConfigurations[Name]
					if not AnimeConfiguration then return end

					local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")
					if not Mutation then return end

					local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level")
					if not Level then Level = 1 end

					CreateToolEvent:Fire(Player, Name, AnimeConfiguration, Mutation, Level, true)

					Bases.Remove(Base, Slot)
				end)

				PromptTrove:Connect(PlaceProximityPrompt.Triggered, function(TriggeringPlayer)
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

						local Anime = Bases.Add(Player, Base, Slot, Name, Mutation, Level)

						table.remove(ToolsData, Index)

						ReplacePlayerDataEvent:Fire(Player, "Tools", ToolsData)

						Tool:Destroy()

						break
					end
				end)

				PromptTrove:Connect(SwapProximityPrompt.Triggered, function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player ~= TriggeringPlayer then return end

					local Character = Player.Character or Player.CharacterAdded:Wait()

					local Tool = Character:FindFirstChildOfClass("Tool")
					if not Tool then return end

					local Anime = BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Anime
					if not Anime then return end

					local Name = Anime.Name

					local AnimeConfiguration = AnimeConfigurations[Name]
					if not AnimeConfiguration then return end

					local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")
					if not Mutation then return end

					local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level")
					if not Level then Level = 1 end

					local ToolsData = RetrievePlayerDataFunction:Invoke(Player, "Tools")

					for Index, ToolData in pairs(ToolsData) do
						if ToolData.Tool ~= Tool then continue end

						Bases.Remove(Base, Slot)

						Tool:Destroy()

						table.remove(ToolsData, Index)

						ReplacePlayerDataEvent:Fire(Player, "Tools", ToolsData)

						CreateToolEvent:Fire(Player, Name, AnimeConfiguration, Mutation, Level, true)

						local Name = ToolData.Name
						local Mutation = ToolData.Mutation
						local Level = ToolData.Level

						local Anime = Bases.Add(Player, Base, Slot, Name, Mutation, Level)

						break
					end
				end)

				PromptTrove:Connect(StealProximityPrompt.Triggered, function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player == TriggeringPlayer then return end

					local Anime = BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Anime
					if not Anime then return end

					local Name = Anime.Name

					local AnimeConfiguration = AnimeConfigurations[Name]
					if not AnimeConfiguration then return end

					local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")
					if not Mutation then return end

					local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level")
					if not Level then Level = 1 end

					local StealingData = {
						Player = Player,
						Base = Base,
						Slot = Slot
					}

					if (RetrievePlayerDataFunction:Invoke(Player, "Steals") or 0) >= 1 then
						ReplacePlayerDataEvent:Fire(Player, "Steals", RetrievePlayerDataFunction:Invoke(Player, "Steals") - 1)

						CreateToolEvent:Fire(TriggeringPlayer, Name, AnimeConfiguration, Mutation, Level)

						Bases.Remove(Base, Slot)
					else
						ReplacePlayerDataEvent:Fire(TriggeringPlayer, "Stealing", StealingData)

						MarketplaceService:PromptProductPurchase(TriggeringPlayer, GameConfigurations.ProductsIds.Steal)
					end
				end)

				PromptTrove:Connect(SellProximityPrompt.Triggered, function(TriggeringPlayer)
					if not BasesData[Base] then return end

					local Player = BasesData[Base].Player
					if not Player then return end

					if Player ~= TriggeringPlayer then return end

					local Anime = BasesData[Base].SlotsData[Slot.Name] and BasesData[Base].SlotsData[Slot.Name].Anime
					if not Anime then return end

					local Name = Anime.Name

					local AnimeConfiguration = AnimeConfigurations[Name]
					if not AnimeConfiguration then return end

					local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level")
					if not Level then Level = 1 end

					local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")

					local Sell = getBaseSellValue(AnimeConfiguration, Level, Mutation, getPlayerRebirthMultiplier(Player))

					Bases.Remove(Base, Slot)

					ReplacePlayerDataEvent:Fire(Player, "Money", RetrievePlayerDataFunction:Invoke(Player, "Money") + Sell)
					Packets.announcement.sendTo({
						Text = string.format("Sold anime for $%s.", Format.Number(Sell)),
						Colour = Packets.EncodeColour(BASE_SELL_SUCCESS_COLOUR),
					}, Player)
				end)
			end
		end
	end
end
	ctx.applyOccupiedSlotPromptState = applyOccupiedSlotPromptState
end

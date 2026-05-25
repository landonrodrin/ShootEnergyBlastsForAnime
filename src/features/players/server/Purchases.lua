return function(ctx)
	local MarketplaceService = ctx.MarketplaceService
	local Players = ctx.Players
	local Bases = ctx.Bases
	local GameConfigurations = ctx.GameConfigurations
	local AnimeConfigurations = ctx.AnimeConfigurations
	local UpgradesConfigurations = ctx.UpgradesConfigurations
	local AreasConfigurations = ctx.AreasConfigurations
	local RebirthsConfigurations = ctx.RebirthsConfigurations
	local RetrieveAnimeDataFunction = ctx.RetrieveAnimeDataFunction
	local RetrievePlayerDataFunction = ctx.RetrievePlayerDataFunction
	local ReplacePlayerDataEvent = ctx.ReplacePlayerDataEvent
	local CreateToolEvent = ctx.CreateToolEvent
	local Packets = ctx.Packets
	local PlayersData = ctx.PlayersData
	local PlayersModule = ctx.PlayersModule

	local function setupPurchaseProcessing()
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
					local Anime = Bases.Retrieve(Base, "SlotsData")[Slot.Name] and Bases.Retrieve(Base, "SlotsData")[Slot.Name].Anime
					if not Anime then return end

					local Name = Anime.Name

					local AnimeConfiguration = AnimeConfigurations[Name]
					if not AnimeConfiguration then return end

					local Mutation = RetrieveAnimeDataFunction:Invoke(Anime, "Mutation")
					if not Mutation then return end

					local Level = RetrieveAnimeDataFunction:Invoke(Anime, "Level")
					if not Level then Level = 1 end

					CreateToolEvent:Fire(Player, Name, AnimeConfiguration, Mutation, Level)

					Bases.Remove(Base, Slot)

					local AreaConfiguration = AreasConfigurations[AnimeConfiguration.Area]
					if not AreaConfiguration then return end

					local Colour = AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255)

					Colour = string.format("rgb(%d, %d, %d)", Colour.R * 255, Colour.G * 255, Colour.B * 255)

					local Text = string.format("%s stole your <font color=\"%s\">%s</font> Anime!", Player.Name, Colour, Name)

					Packets.announcement.sendTo({
						Text = Text,
					}, StolenPlayer)

					local Text = string.format("You stole %s's <font color=\"%s\">%s</font> Anime!", StolenPlayer.Name, Colour, Name)

					Packets.announcement.sendTo({
						Text = Text,
					}, Player)
				else
					ReplacePlayerDataEvent:Fire(Player, "Steals", RetrievePlayerDataFunction:Invoke(Player, "Steals") + 1)
				end
			elseif ProductId == GameConfigurations.ProductsIds.SkipRebirth then
				local Rebirths = PlayersModule.Retrieve(Player, "Rebirths")
				local Speed = PlayersModule.Retrieve(Player, "Speed")

				if not RebirthsConfigurations[Rebirths + 1] then return end

				ReplacePlayerDataEvent:Fire(Player, "Rebirths", Rebirths + 1)

				Packets.rebirth.sendTo({
					Rebirths = Rebirths + 1,
					Speed = Speed,
				}, Player)
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
	end

	ctx.setupPurchaseProcessing = setupPurchaseProcessing
end

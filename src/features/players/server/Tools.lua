return function(ctx)
	local Packets = ctx.Packets
	local PlayersData = ctx.PlayersData
	local PlayersModule = ctx.PlayersModule
	local makeInventoryId = ctx.makeInventoryId
	local normalizeHotbarOrder = ctx.normalizeHotbarOrder
	local equipInventoryTool = ctx.equipInventoryTool
	local queueInventorySync = ctx.queueInventorySync
	local cleanupToolData = ctx.cleanupToolData
function PlayersModule.Tool(Player, Name, AnimeConfiguration, Mutation, Level, ToolIndex, ToolData, AutoEquip, SuppressSync)
	if typeof(ToolIndex) == "boolean" and ToolData == nil and AutoEquip == nil then
		AutoEquip = ToolIndex
		ToolIndex = nil
	end

	if not AnimeConfiguration then return end

	if ToolData and ToolData.Trove then
		cleanupToolData(ToolData)
	end

	local Data = ToolData or {}
	Mutation = Mutation or "Default"

	local Tool = ctx.Resources:WaitForChild("Tool")

	Tool = Tool:Clone()

	local Id = ToolData and ToolData.Id or makeInventoryId()

	Data.Tool = Tool
	Data.Id = Id
	Data.Name = Name
	Data.Mutation = Mutation
	Data.Level = Level or 1
	local ToolTrove = ctx.Trove.new()
	Data.Trove = ToolTrove

	local IndexData = PlayersData[Player] and PlayersData[Player].Index
	if IndexData then
		IndexData[Mutation] = IndexData[Mutation] or {}
	end

	if IndexData and not IndexData[Mutation][Name] then
		IndexData[Mutation][Name] = true

		Packets.indexSync.sendTo({
			Index = IndexData,
		}, Player)
		if not ToolData then
			task.defer(function()
				if not Player.Parent then return end

				Packets.animeUnlocked.sendTo({
					Name = Name,
					Mutation = Mutation,
				}, Player)
			end)
		end
	end

	ToolTrove:Connect(Tool.Equipped, function()
		if Player:GetAttribute("HoldState") ~= "Carry" then
			Player:SetAttribute("HoldState", "Inventory")
		end
		queueInventorySync(Player)
	end)

	ToolTrove:Connect(Tool.Unequipped, function()
		if Player:GetAttribute("HoldState") == "Inventory" then
			Player:SetAttribute("HoldState", nil)
		end
		queueInventorySync(Player)
	end)

	Tool.Name = Name
	Tool.ToolTip = Name
	Tool.TextureId = AnimeConfiguration.Icons[Mutation]
	Tool.RequiresHandle = false
	Tool:SetAttribute("InventoryId", Id)
	Tool:SetAttribute("Mutation", Mutation)
	Tool:SetAttribute("Level", Data.Level)
	Tool:SetAttribute("Rebirths", PlayersData[Player] and PlayersData[Player].Rebirths or 0)

	ToolTrove:Connect(Tool.Destroying, function()
		Data.Tool = nil
		if Data.Trove == ToolTrove then
			Data.Trove = nil
		end

		task.defer(function()
			ToolTrove:Destroy()
		end)
	end)

	if ToolIndex and ToolData then
		ToolData.Id = Id
		ToolData.Tool = Tool
		ToolData.Trove = ToolTrove

		PlayersData[Player].Tools[ToolIndex] = ToolData
	else
		local Tools = PlayersData[Player].Tools
		if not Tools then Tools = {} end

		table.insert(Tools, Data)

		PlayersData[Player].Tools = Tools
	end

	Tool.Parent = Player.Backpack
	normalizeHotbarOrder(PlayersData[Player])
	if AutoEquip and not ToolData then
		task.defer(function()
			if not Player.Parent then return end
			if not Tool.Parent then return end

			equipInventoryTool(Player, Data)
			queueInventorySync(Player)
		end)
	elseif not SuppressSync then
		queueInventorySync(Player)
	end

	return Data
end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ZonePlus = require(ReplicatedStorage.Shared.Packages:WaitForChild("ZonePlus"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))
local SellPanelView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("SellPanelView"))

local InventoryController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("InventoryController"))
local Player = Players.LocalPlayer
local GAMEPLAY_PANELS = UiTuning.GameplayPanels

local function mutationColour(Mutation)
	local Configuration = MutationsConfigurations[Mutation]
	return Configuration and Configuration.Colour or Color3.fromRGB(255, 255, 255)
end

local function inventoryTotal(Inventory)
	local Total = 0
	for _, Item in ipairs(Inventory.Items or {}) do
		Total += Item.Sell or 0
	end
	return Total
end

local function SellController(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local ConfirmOpen, SetConfirmOpen = React.useState(false)
	local Inventory, SetInventory = React.useState(InventoryController.GetSnapshot())
	local ActivePanelRef = React.useRef(Props.ActivePanel)
	local Open = if Props.SetActivePanel then Props.ActivePanel == "Sell" else LocalOpen

	React.useEffect(function()
		ActivePanelRef.current = Props.ActivePanel

		return nil
	end, { Props.ActivePanel })

	local function setOpen(NextOpen)
		if Props.SetActivePanel then
			Props.SetActivePanel(if NextOpen then "Sell" else nil)
		else
			SetLocalOpen(NextOpen)
		end
	end

	local function closeIfActive()
		if Props.SetActivePanel then
			if ActivePanelRef.current == "Sell" then
				Props.SetActivePanel(nil)
			end
		else
			SetLocalOpen(false)
		end
	end

	React.useEffect(function()
		local ChangedConnection = InventoryController.Changed:Connect(function(Name)
			if Name ~= "Inventory" then return end
			SetInventory(InventoryController.GetSnapshot())
		end)

		local CharacterConnection = Player.CharacterRemoving:Connect(function()
			closeIfActive()
			SetConfirmOpen(false)
		end)

		local SellStation = workspace:WaitForChild("Sell", 10)
		local Toggle = SellStation and SellStation:WaitForChild("Toggle", 10)
		local SellZone = nil
		local EnteredConnection = nil
		local ExitedConnection = nil

		if Toggle then
			SellZone = ZonePlus.CreatePresenceZone(Toggle)
			EnteredConnection = SellZone.localPlayerEntered:Connect(function()
				setOpen(true)
			end)
			ExitedConnection = SellZone.localPlayerExited:Connect(function()
				closeIfActive()
				SetConfirmOpen(false)
			end)

			if SellZone:findLocalPlayer() then
				setOpen(true)
			end
		else
			warn("Missing sell station zone: Workspace.Sell.Toggle")
		end

		return function()
			ChangedConnection:Disconnect()
			CharacterConnection:Disconnect()
			if EnteredConnection then
				EnteredConnection:Disconnect()
			end
			if ExitedConnection then
				ExitedConnection:Disconnect()
			end
			if SellZone then
				SellZone:destroy()
			end
		end
	end, { Props.SetActivePanel })

	local Total = inventoryTotal(Inventory)
	local Items = {}
	for _, Item in ipairs(Inventory.Items or {}) do
		local Mutation = Item.Mutation or "Default"
		table.insert(Items, {
			Accent = mutationColour(Mutation),
			Id = Item.Id,
			Mutation = Mutation,
			MutationText = string.format("%s Lvl %s", Mutation, Item.Level or 1),
			Name = tostring(Item.Name or "Anime"),
			SellText = string.format("$%s", Format.Number(Item.Sell or 0)),
		})
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Panel = React.createElement(SellPanelView, {
			CanSellAll = Total > 0,
			ConfirmText = string.format("Sell all %s inventory anime for $%s?", #(Inventory.Items or {}), Format.Number(Total)),
			ConfirmVisible = ConfirmOpen,
			Items = Items,
			OnCancelConfirm = function()
				SetConfirmOpen(false)
			end,
			OnClose = function()
				closeIfActive()
				SetConfirmOpen(false)
			end,
			OnConfirmSellAll = function()
				SetConfirmOpen(false)
				InventoryController.SellAll()
			end,
			OnSellAll = function()
				SetConfirmOpen(true)
			end,
			OnSellSingle = function(ItemId)
				InventoryController.SellSingle(ItemId)
			end,
			SellAllText = string.format("Sell All ($%s)", Format.Number(Total)),
			SharedTuning = GAMEPLAY_PANELS,
			Tuning = GAMEPLAY_PANELS.Sell,
			Visible = Open,
		}),
	})
end

return SellController

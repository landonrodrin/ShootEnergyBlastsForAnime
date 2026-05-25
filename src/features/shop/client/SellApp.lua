local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ZonePlus = require(ReplicatedStorage.Shared.Packages:WaitForChild("ZonePlus"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ReactUi"))
local ViewportPreview = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ViewportPreview"))

local InventoryController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("InventoryController"))
local Player = Players.LocalPlayer

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

local function SellApp()
	local Open, SetOpen = React.useState(false)
	local ConfirmOpen, SetConfirmOpen = React.useState(false)
	local Inventory, SetInventory = React.useState(InventoryController.GetSnapshot())

	React.useEffect(function()
		local ChangedConnection = InventoryController.Changed:Connect(function(Name)
			if Name ~= "Inventory" then return end
			SetInventory(InventoryController.GetSnapshot())
		end)

		local CharacterConnection = Player.CharacterRemoving:Connect(function()
			SetOpen(false)
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
				SetOpen(true)
			end)
			ExitedConnection = SellZone.localPlayerExited:Connect(function()
				SetOpen(false)
				SetConfirmOpen(false)
			end)

			if SellZone:findLocalPlayer() then
				SetOpen(true)
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
	end, {})

	local Total = inventoryTotal(Inventory)
	local ListChildren = {
		Layout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for Index, Item in ipairs(Inventory.Items or {}) do
		local Accent = mutationColour(Item.Mutation)
		ListChildren[string.format("Item%d", Index)] = React.createElement(ReactUi.Panel, {
			BackgroundColor3 = Color3.fromRGB(26, 29, 38),
			LayoutOrder = Index,
			Size = UDim2.new(1, -8, 0, 96),
			StrokeColor = Accent,
		}, {
			Preview = React.createElement(ViewportPreview, {
				AnimeName = Item.Name,
				BackgroundColor3 = Accent,
				BackgroundTransparency = 0.72,
				Mutation = Item.Mutation,
				Position = UDim2.fromOffset(12, 12),
				Scale = 1.25,
				Size = UDim2.fromOffset(72, 72),
				StrokeColor = Accent,
			}),
			Name = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromOffset(98, 34),
				Size = UDim2.new(0.44, 0, 0, 34),
				Text = tostring(Item.Name or "Anime"),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Mutation = React.createElement(ReactUi.Text, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromOffset(98, 64),
				Size = UDim2.new(0.44, 0, 0, 26),
				Text = string.format("%s Lvl %s", Item.Mutation or "Default", Item.Level or 1),
				TextColor3 = Accent,
				TextScaled = true,
				TextStrokeTransparency = 0.75,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Sell = React.createElement(ReactUi.Button, {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = ReactUi.Colours.Green,
				MaxTextSize = 24,
				OnActivated = function()
					InventoryController.SellSingle(Item.Id)
				end,
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(150, 44),
				Text = string.format("$%s", Format.Number(Item.Sell or 0)),
			}),
		})
	end

	if #(Inventory.Items or {}) == 0 then
		ListChildren.Empty = React.createElement(ReactUi.EmptyState, {
			Text = "No anime to sell.",
		})
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Panel = React.createElement(ReactUi.Panel, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.fromScale(0.52, 0.62),
			StrokeColor = ReactUi.Colours.Green,
			StrokeThickness = 3,
			Visible = Open,
		}, {
			Header = React.createElement(ReactUi.Header, {
				OnClose = function()
					SetOpen(false)
					SetConfirmOpen(false)
				end,
				Title = "Sell Anime",
			}),
			List = React.createElement("ScrollingFrame", {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, 0),
				Position = UDim2.fromOffset(18, 76),
				ScrollBarThickness = 8,
				Size = UDim2.new(1, -36, 1, -148),
			}, ListChildren),
			SellAll = React.createElement(ReactUi.Button, {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = ReactUi.Colours.Green,
				Disabled = Total <= 0,
				OnActivated = function()
					SetConfirmOpen(true)
				end,
				Position = UDim2.new(0.5, 0, 1, -18),
				Size = UDim2.fromOffset(260, 48),
				Text = string.format("Sell All ($%s)", Format.Number(Total)),
			}),
		}),
		Confirm = React.createElement(ReactUi.Panel, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(18, 20, 28),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(420, 180),
			StrokeColor = ReactUi.Colours.Green,
			StrokeThickness = 3,
			Visible = ConfirmOpen,
			ZIndex = 20,
		}, {
			Message = React.createElement(ReactUi.Text, {
				Position = UDim2.fromOffset(24, 20),
				Size = UDim2.new(1, -48, 0, 72),
				Text = string.format("Sell all %s inventory anime for $%s?", #(Inventory.Items or {}), Format.Number(Total)),
				ZIndex = 21,
			}),
			Cancel = React.createElement(ReactUi.Button, {
				BackgroundColor3 = ReactUi.Colours.PanelLight,
				OnActivated = function()
					SetConfirmOpen(false)
				end,
				Position = UDim2.fromOffset(44, 112),
				Size = UDim2.fromOffset(150, 44),
				Text = "Cancel",
				ZIndex = 21,
			}),
			Confirm = React.createElement(ReactUi.Button, {
				BackgroundColor3 = ReactUi.Colours.Green,
				OnActivated = function()
					SetConfirmOpen(false)
					InventoryController.SellAll()
				end,
				Position = UDim2.fromOffset(226, 112),
				Size = UDim2.fromOffset(150, 44),
				Text = "Sell",
				ZIndex = 21,
			}),
		}),
	})
end

return SellApp

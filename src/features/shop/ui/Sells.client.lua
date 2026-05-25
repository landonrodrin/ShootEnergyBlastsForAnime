local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local ZonePlus = require(ReplicatedStorage.Shared:WaitForChild("ZonePlus"))
local AnimeViewports = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AnimeViewports"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local Animations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("Animations"))
local MutationsConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("MutationsConfigurations"))

local InventoryController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("InventoryController"))
InventoryController.Start()

local Player = Players.LocalPlayer
local SellsGui = script.Parent
local SellsFrame = SellsGui:WaitForChild("SellsFrame")
local SellStation = workspace:WaitForChild("Sell")
local Toggle = SellStation:WaitForChild("Toggle")

local Inventory = {
	Items = {},
	EquippedId = nil
}

local ScriptTrove = Trove.new()
local RowsTrove = Trove.new()
ScriptTrove:Add(RowsTrove)
ScriptTrove:Connect(script.Destroying, function()
	ScriptTrove:Destroy()
end)

local Header = SellsFrame:FindFirstChild("Header")
local CloseButton = Header and Header:FindFirstChild("Close")
local HeaderText = Header and Header:FindFirstChild("Upgrades")
if HeaderText and HeaderText:IsA("TextLabel") then
	HeaderText.Text = "Sells"
end

local List = SellsFrame:WaitForChild("SellList")
local RowTemplate = SellsFrame:WaitForChild("SellRowTemplate")
local Layout = List:WaitForChild("UIListLayout")
local SellAllButton = SellsFrame:WaitForChild("SellAll")
local SellAllBackground = SellsFrame:FindFirstChild("SellAllBackground")
local ConfirmFrame = SellsGui:WaitForChild("SellConfirm")
local ConfirmButton = ConfirmFrame:WaitForChild("Confirm")
local CancelButton = ConfirmFrame:WaitForChild("Cancel")

RowTemplate.Visible = false

local function clearRows()
	RowsTrove:Clean()
end

local function getMutationColour(Mutation)
	local Configuration = MutationsConfigurations[Mutation]
	return Configuration and Configuration.Colour or Color3.fromRGB(255, 255, 255)
end

local function totalSell()
	local Total = 0
	for _, Item in ipairs(Inventory.Items or {}) do
		Total += Item.Sell or 0
	end
	return Total
end

local function setFrameOpen(Open)
	if SellsFrame.Visible ~= Open then
		Animations.ToggleFrame(SellsFrame)
	end

	if Open then
		List.CanvasPosition = Vector2.zero
	else
		ConfirmFrame.Visible = false
	end
end

local function createRow(Item, LayoutOrder)
	local RowTrove = RowsTrove:Extend()
	local Accent = getMutationColour(Item.Mutation)
	local Row = RowTemplate:Clone()
	Row.Name = string.format("Sell_%s", tostring(Item.Id))
	Row.LayoutOrder = LayoutOrder
	Row.Visible = true
	Row.Parent = List
	RowTrove:Add(Row)

	local Stroke = Row:FindFirstChildOfClass("UIStroke")
	if Stroke then
		Stroke.Color = Accent
		Stroke.Transparency = Item.Mutation == "Default" and 0.45 or 0
	end

	local Icon = Row:FindFirstChild("Icon")
	if Icon and Icon:IsA("GuiObject") then
		Icon.BackgroundColor3 = Accent
		Icon.BackgroundTransparency = Item.Mutation == "Default" and 0.35 or 0.08
		local Viewport = AnimeViewports.Mount(Icon, Item.Name, Item.Mutation, {
			Scale = 1.4,
		})
		if Viewport then
			RowTrove:Add(Viewport)
		end
	end

	local NameLabel = Row:FindFirstChild("Name")
	if NameLabel and NameLabel:IsA("TextLabel") then
		NameLabel.Text = Item.Name
	end

	local MutationLabel = Row:FindFirstChild("Mutation")
	if MutationLabel and MutationLabel:IsA("TextLabel") then
		MutationLabel.Text = string.format("%s Lvl %s", Item.Mutation or "Default", Item.Level or 1)
		MutationLabel.Visible = true
		MutationLabel.TextColor3 = Accent
	end

	local Description = Row:FindFirstChild("Description")
	if Description and Description:IsA("TextLabel") then
		Description.Text = "Sell"
	end

	local MoneyButton = Row:FindFirstChild("Money")
	if MoneyButton and MoneyButton:IsA("GuiButton") then
		MoneyButton.Text = string.format("$%s", Format.Number(Item.Sell or 0))
		RowTrove:Connect(MoneyButton.Activated, function()
			InventoryController.SellSingle(Item.Id)
		end)
	end

	return Row
end

local function redraw()
	clearRows()

	for Index, Item in ipairs(Inventory.Items or {}) do
		createRow(Item, Index)
	end

	task.defer(function()
		List.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 8)
	end)

	local Total = totalSell()
	SellAllButton.Text = string.format("Sell All ($%s)", Format.Number(Total))
	SellAllButton.AutoButtonColor = Total > 0
	SellAllButton.Active = Total > 0
	SellAllButton.BackgroundColor3 = Total > 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(65, 68, 78)
	SellAllButton.BackgroundTransparency = Total > 0 and 1 or 0
	if SellAllBackground then
		SellAllBackground.Visible = Total > 0
	end
end

ScriptTrove:Connect(InventoryController.Changed, function(Name)
	if Name ~= "Inventory" then return end

	Inventory = InventoryController.GetSnapshot()
	redraw()
end)

if CloseButton then
	ScriptTrove:Connect(CloseButton.Activated, function()
		setFrameOpen(false)
	end)
end

ScriptTrove:Connect(SellAllButton.Activated, function()
	local Total = totalSell()
	if Total <= 0 then return end

	local Message = ConfirmFrame:FindFirstChild("Message")
	if Message and Message:IsA("TextLabel") then
		Message.Text = string.format("Sell all %s inventory animes for $%s?", #(Inventory.Items or {}), Format.Number(Total))
	end

	ConfirmFrame.Visible = true
end)

ScriptTrove:Connect(ConfirmButton.Activated, function()
	ConfirmFrame.Visible = false
	InventoryController.SellAll()
end)

ScriptTrove:Connect(CancelButton.Activated, function()
	ConfirmFrame.Visible = false
end)

local SellZone = ZonePlus.CreatePresenceZone(Toggle)
ScriptTrove:Add(SellZone, "destroy")
ZonePlus.ConnectSignal(ScriptTrove, SellZone.localPlayerEntered, function()
	setFrameOpen(true)
end)

ZonePlus.ConnectSignal(ScriptTrove, SellZone.localPlayerExited, function()
	setFrameOpen(false)
end)

if SellZone:findLocalPlayer() then
	setFrameOpen(true)
end

ScriptTrove:Connect(Player.CharacterRemoving, function()
	setFrameOpen(false)
end)

Animations.Frame(SellsFrame)
Inventory = InventoryController.GetSnapshot()
redraw()

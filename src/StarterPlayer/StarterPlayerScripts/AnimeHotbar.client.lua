local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))

local RemoteEvents = ReplicatedStorage.Network:WaitForChild("RemoteEvents")
local InventorySyncEvent = RemoteEvents:WaitForChild("InventorySync")
local EquipInventoryEvent = RemoteEvents:WaitForChild("EquipInventory")
local UpdateHotbarSlotEvent = RemoteEvents:WaitForChild("UpdateHotbarSlot")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local HOTBAR_SLOTS = 10
local SLOT_WIDTH = 54
local SLOT_HEIGHT = 60
local SLOT_PADDING = 4
local BACKPACK_WIDTH = 62
local SLOT_LABELS = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}
local SLOT_KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero
}

local Gui = Instance.new("ScreenGui")
Gui.Name = "AnimeHotbarGui"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

local Inventory = {
	Items = {},
	EquippedId = nil,
	HotbarOrder = {},
	MaxHotbarSlots = HOTBAR_SLOTS
}

local SlotButtons = {}
local VisibleHotbarItems = {}
local DragState = nil

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local Bar = Instance.new("Frame")
Bar.Name = "Bar"
Bar.AnchorPoint = Vector2.new(0.5, 1)
Bar.BackgroundTransparency = 1
Bar.Position = UDim2.new(0.5, 0, 1, -14)
Bar.Size = UDim2.new(0, 680, 0, SLOT_HEIGHT + 8)
Bar.Parent = Gui

local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Horizontal
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.Padding = UDim.new(0, SLOT_PADDING)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Bar

local BackpackButton = Instance.new("TextButton")
BackpackButton.Name = "BackpackButton"
BackpackButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BackpackButton.BackgroundTransparency = 0.78
BackpackButton.BorderSizePixel = 0
BackpackButton.Font = Enum.Font.GothamBlack
BackpackButton.LayoutOrder = HOTBAR_SLOTS + 1
BackpackButton.Size = UDim2.new(0, BACKPACK_WIDTH, 0, SLOT_HEIGHT)
BackpackButton.Text = "BAG"
BackpackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BackpackButton.TextScaled = true
BackpackButton.Parent = Bar

local BackpackButtonCorner = Instance.new("UICorner")
BackpackButtonCorner.CornerRadius = UDim.new(0, 8)
BackpackButtonCorner.Parent = BackpackButton

local BackpackButtonStroke = Instance.new("UIStroke")
BackpackButtonStroke.Color = Color3.fromRGB(120, 180, 255)
BackpackButtonStroke.Thickness = 2
BackpackButtonStroke.Transparency = 0.18
BackpackButtonStroke.Parent = BackpackButton

local BackpackFrame = Instance.new("Frame")
BackpackFrame.Name = "BackpackFrame"
BackpackFrame.AnchorPoint = Vector2.new(0.5, 1)
BackpackFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
BackpackFrame.BorderSizePixel = 0
BackpackFrame.Position = UDim2.new(0.5, 0, 1, -116)
BackpackFrame.Size = UDim2.new(0, 520, 0, 300)
BackpackFrame.Visible = false
BackpackFrame.Parent = Gui

local BackpackCorner = Instance.new("UICorner")
BackpackCorner.CornerRadius = UDim.new(0, 8)
BackpackCorner.Parent = BackpackFrame

local BackpackStroke = Instance.new("UIStroke")
BackpackStroke.Color = Color3.fromRGB(70, 76, 92)
BackpackStroke.Thickness = 2
BackpackStroke.Parent = BackpackFrame

local BackpackTitle = Instance.new("TextLabel")
BackpackTitle.BackgroundTransparency = 1
BackpackTitle.Font = Enum.Font.GothamBlack
BackpackTitle.Position = UDim2.new(0, 16, 0, 10)
BackpackTitle.Size = UDim2.new(1, -56, 0, 28)
BackpackTitle.Text = "Anime Backpack"
BackpackTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
BackpackTitle.TextScaled = true
BackpackTitle.TextXAlignment = Enum.TextXAlignment.Left
BackpackTitle.Parent = BackpackFrame

local BackpackClose = Instance.new("TextButton")
BackpackClose.BackgroundColor3 = Color3.fromRGB(42, 45, 54)
BackpackClose.BorderSizePixel = 0
BackpackClose.Font = Enum.Font.GothamBlack
BackpackClose.Position = UDim2.new(1, -42, 0, 10)
BackpackClose.Size = UDim2.new(0, 28, 0, 28)
BackpackClose.Text = "X"
BackpackClose.TextColor3 = Color3.fromRGB(255, 255, 255)
BackpackClose.TextScaled = true
BackpackClose.Parent = BackpackFrame

local BackpackCloseCorner = Instance.new("UICorner")
BackpackCloseCorner.CornerRadius = UDim.new(0, 6)
BackpackCloseCorner.Parent = BackpackClose

local BackpackList = Instance.new("ScrollingFrame")
BackpackList.BackgroundTransparency = 1
BackpackList.BorderSizePixel = 0
BackpackList.CanvasSize = UDim2.new()
BackpackList.Position = UDim2.new(0, 14, 0, 50)
BackpackList.ScrollBarThickness = 6
BackpackList.Size = UDim2.new(1, -28, 1, -64)
BackpackList.Parent = BackpackFrame

local BackpackGrid = Instance.new("UIGridLayout")
BackpackGrid.CellPadding = UDim2.new(0, 8, 0, 8)
BackpackGrid.CellSize = UDim2.new(0, 88, 0, 92)
BackpackGrid.SortOrder = Enum.SortOrder.LayoutOrder
BackpackGrid.Parent = BackpackList

local function clear(Container)
	for _, Child in ipairs(Container:GetChildren()) do
		if Child:IsA("GuiObject") then
			Child:Destroy()
		end
	end
end

local function getMutationColour(Mutation)
	local Configuration = MutationsConfigurations[Mutation]
	return Configuration and Configuration.Colour or Color3.fromRGB(255, 255, 255)
end

local function getItemById(Id)
	if not Id then return nil end

	for _, Item in ipairs(Inventory.Items or {}) do
		if Item.Id == Id then
			return Item
		end
	end
end

local function getHotbarIdSet()
	local Set = {}
	for _, Item in ipairs(VisibleHotbarItems) do
		Set[Item.Id] = true
	end
	return Set
end

local function getVisibleHotbarItems()
	local Items = {}
	local UsedIds = {}
	local Limit = math.min(#(Inventory.Items or {}), HOTBAR_SLOTS)

	for Slot = 1, HOTBAR_SLOTS do
		if #Items >= Limit then break end

		local Id = Inventory.HotbarOrder and Inventory.HotbarOrder[Slot]
		local Item = getItemById(Id)
		if Item and not UsedIds[Item.Id] then
			table.insert(Items, Item)
			UsedIds[Item.Id] = true
		end
	end

	for _, Item in ipairs(Inventory.Items or {}) do
		if #Items >= Limit then break end
		if UsedIds[Item.Id] then continue end

		table.insert(Items, Item)
		UsedIds[Item.Id] = true
	end

	return Items
end

local function renderPreview(Viewport, Name, Mutation)
	local Previews = ReplicatedStorage:FindFirstChild("AnimePreviews")
	local Template = Previews and Previews:FindFirstChild(Name)
	if not Template then return end

	local World = Instance.new("WorldModel")
	World.Parent = Viewport

	local Model = Template:Clone()
	Model.Parent = World

	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = getMutationColour(Mutation)
	Highlight.FillTransparency = Mutation == "Default" and 1 or 0.75
	Highlight.OutlineColor = getMutationColour(Mutation)
	Highlight.OutlineTransparency = Mutation == "Default" and 1 or 0.15
	Highlight.Parent = Model

	local Camera = Instance.new("Camera")
	Camera.Parent = Viewport
	Viewport.CurrentCamera = Camera

	local CFrameValue, Size = Model:GetBoundingBox()
	local MaxSize = math.max(Size.X, Size.Y, Size.Z, 1)
	local Center = CFrameValue.Position

	Camera.CFrame = CFrame.new(Center + Vector3.new(0, Size.Y * 0.15, MaxSize * 2.2), Center)
end

local function pointInside(Frame, Position)
	local AbsolutePosition = Frame.AbsolutePosition
	local AbsoluteSize = Frame.AbsoluteSize

	return Position.X >= AbsolutePosition.X
		and Position.X <= AbsolutePosition.X + AbsoluteSize.X
		and Position.Y >= AbsolutePosition.Y
		and Position.Y <= AbsolutePosition.Y + AbsoluteSize.Y
end

local function slotAtPosition(Position)
	for Slot, Button in pairs(SlotButtons) do
		if pointInside(Button, Position) then
			return Slot
		end
	end
end

local function stopDrag(Position)
	if not DragState then return end

	local TargetSlot = Position and slotAtPosition(Position)
	if TargetSlot then
		UpdateHotbarSlotEvent:FireServer(TargetSlot, DragState.Id)
	end

	if DragState.Ghost then
		DragState.Ghost:Destroy()
	end

	DragState = nil
end

local function updateDrag(Position)
	if not DragState or not DragState.Ghost then return end

	DragState.Ghost.Position = UDim2.fromOffset(Position.X - (SLOT_WIDTH / 2), Position.Y - (SLOT_HEIGHT / 2))
end

local function beginDrag(Item, Position)
	if not Item then return end

	if DragState and DragState.Ghost then
		DragState.Ghost:Destroy()
	end

	local Ghost = Instance.new("Frame")
	Ghost.Name = "DragGhost"
	Ghost.BackgroundColor3 = getMutationColour(Item.Mutation)
	Ghost.BackgroundTransparency = 0.62
	Ghost.BorderSizePixel = 0
	Ghost.Position = UDim2.fromOffset(Position.X - (SLOT_WIDTH / 2), Position.Y - (SLOT_HEIGHT / 2))
	Ghost.Size = UDim2.new(0, SLOT_WIDTH, 0, SLOT_HEIGHT)
	Ghost.ZIndex = 100
	Ghost.Parent = Gui

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Ghost

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = getMutationColour(Item.Mutation)
	Stroke.Thickness = 3
	Stroke.Parent = Ghost

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.GothamBlack
	Label.Position = UDim2.new(0, 4, 0, 20)
	Label.Size = UDim2.new(1, -8, 0, 30)
	Label.Text = Item.Name
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.TextScaled = true
	Label.TextStrokeTransparency = 0.35
	Label.ZIndex = 101
	Label.Parent = Ghost

	DragState = {
		Id = Item.Id,
		Ghost = Ghost
	}
end

local function attachDrag(Button, Item)
	Button.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		beginDrag(Item, Input.Position)
	end)
end

local function createItemButton(Item, Slot, Parent)
	local Selected = Inventory.EquippedId == Item.Id
	local Accent = getMutationColour(Item.Mutation)

	local Button = Instance.new("TextButton")
	Button.Name = Item.Id
	Button.AutoButtonColor = true
	Button.BackgroundColor3 = Accent
	Button.BackgroundTransparency = Selected and 0.68 or 0.84
	Button.BorderSizePixel = 0
	Button.Text = ""
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Button

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Accent
	Stroke.Thickness = Selected and 3 or 1.5
	Stroke.Transparency = Selected and 0.05 or 0.35
	Stroke.Parent = Button

	if Slot then
		local Number = Instance.new("TextLabel")
		Number.BackgroundTransparency = 1
		Number.Font = Enum.Font.GothamBold
		Number.Text = SLOT_LABELS[Slot]
		Number.TextColor3 = Color3.fromRGB(230, 235, 245)
		Number.TextScaled = true
		Number.Position = UDim2.new(0, 5, 0, 3)
		Number.Size = UDim2.new(0, 14, 0, 14)
		Number.Parent = Button
	end

	local Viewport = Instance.new("ViewportFrame")
	Viewport.BackgroundTransparency = 1
	Viewport.Position = UDim2.new(0, 5, 0, 4)
	Viewport.Size = UDim2.new(1, -10, 1, -20)
	Viewport.Parent = Button
	renderPreview(Viewport, Item.Name, Item.Mutation)

	local NameLabel = Instance.new("TextLabel")
	NameLabel.BackgroundTransparency = 1
	NameLabel.Font = Enum.Font.GothamBold
	NameLabel.Text = Item.Name
	NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	NameLabel.TextScaled = true
	NameLabel.TextStrokeTransparency = 0.35
	NameLabel.Position = UDim2.new(0, 3, 1, -17)
	NameLabel.Size = UDim2.new(1, -6, 0, 13)
	NameLabel.Parent = Button

	Button.Activated:Connect(function()
		EquipInventoryEvent:FireServer(Item.Id)
	end)

	attachDrag(Button, Item)

	return Button
end

local function redrawHotbar()
	SlotButtons = {}
	VisibleHotbarItems = getVisibleHotbarItems()

	for _, Child in ipairs(Bar:GetChildren()) do
		if Child:IsA("GuiObject") and Child ~= BackpackButton then
			Child:Destroy()
		end
	end

	Bar.Visible = #VisibleHotbarItems > 0

	for Slot, Item in ipairs(VisibleHotbarItems) do
		local Button = createItemButton(Item, Slot, Bar)
		Button.Size = UDim2.new(0, SLOT_WIDTH, 0, SLOT_HEIGHT)
		Button.LayoutOrder = Slot
		SlotButtons[Slot] = Button
	end

	BackpackButton.LayoutOrder = #VisibleHotbarItems + 1
end

local function redrawBackpack()
	clear(BackpackList)

	local HotbarIds = getHotbarIdSet()
	local OverflowCount = 0

	for _, Item in ipairs(Inventory.Items or {}) do
		if HotbarIds[Item.Id] then continue end

		OverflowCount += 1

		local Button = createItemButton(Item, nil, BackpackList)
		Button.LayoutOrder = OverflowCount
		Button.Size = UDim2.new(0, 88, 0, 92)
	end

	task.defer(function()
		BackpackList.CanvasSize = UDim2.new(0, 0, 0, BackpackGrid.AbsoluteContentSize.Y + 8)
	end)

	BackpackButton.Text = OverflowCount > 0 and string.format("BAG\n%s", OverflowCount) or "BAG"

	if OverflowCount > 0 then
		BackpackButton.Visible = true
		BackpackButton.Size = UDim2.new(0, BACKPACK_WIDTH, 0, SLOT_HEIGHT)
	else
		BackpackButton.Visible = false
		BackpackButton.Size = UDim2.new(0, 0, 0, SLOT_HEIGHT)
		BackpackFrame.Visible = false
	end
end

local function redraw()
	redrawHotbar()
	redrawBackpack()
end

local function equipSlot(Slot)
	local Item = VisibleHotbarItems[Slot]
	if not Item then return end

	EquipInventoryEvent:FireServer(Item.Id)
end

BackpackButton.Activated:Connect(function()
	BackpackFrame.Visible = not BackpackFrame.Visible
end)

BackpackClose.Activated:Connect(function()
	BackpackFrame.Visible = false
end)

UserInputService.InputChanged:Connect(function(Input)
	if not DragState then return end
	if Input.UserInputType ~= Enum.UserInputType.MouseMovement
		and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	updateDrag(Input.Position)
end)

UserInputService.InputEnded:Connect(function(Input)
	if not DragState then return end
	if Input.UserInputType ~= Enum.UserInputType.MouseButton1
		and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	stopDrag(Input.Position)
end)

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	if GameProcessed then return end

	for Slot, KeyCode in ipairs(SLOT_KEYS) do
		if Input.KeyCode == KeyCode then
			equipSlot(Slot)
			return
		end
	end
end)

InventorySyncEvent.OnClientEvent:Connect(function(Snapshot)
	Inventory = Snapshot or Inventory
	Inventory.HotbarOrder = Inventory.HotbarOrder or {}
	Inventory.MaxHotbarSlots = Inventory.MaxHotbarSlots or HOTBAR_SLOTS
	redraw()
end)

Player.CharacterAdded:Connect(function()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
end)

redraw()

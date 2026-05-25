return function(ctx)
	local SetProperties = ctx.SetProperties
	local Format = ctx.Format
	local BASE_GUI_MAX_DISTANCE = ctx.BASE_GUI_MAX_DISTANCE
	local BASE_INFO_GUI_NAME = ctx.BASE_INFO_GUI_NAME
	local BASE_INFO_ANCHOR_NAME = ctx.BASE_INFO_ANCHOR_NAME
local function getPlayerDisplayName(Player)
	return (Player.DisplayName and Player.DisplayName ~= "" and Player.DisplayName) or Player.Name
end

local function getBaseInfoAnchor(Base)
	if not Base then return end

	local Anchor = Base:FindFirstChild(BASE_INFO_ANCHOR_NAME)
	if Anchor and Anchor:IsA("BasePart") then
		return Anchor
	end

	warn(string.format("%s is missing a %s BasePart for BaseInfoGui.", Base:GetFullName(), BASE_INFO_ANCHOR_NAME))
end

local function getBaseInfoGui(Base)
	local Anchor = Base and Base:FindFirstChild(BASE_INFO_ANCHOR_NAME)
	local BaseInfoGui = Anchor and Anchor:FindFirstChild(BASE_INFO_GUI_NAME)

	if BaseInfoGui then return BaseInfoGui end

	return Base and Base:FindFirstChild(BASE_INFO_GUI_NAME, true)
end

local function updateBaseInfoMoneyPerSecond(Base, MoneyPerSecond)
	local BaseInfoGui = getBaseInfoGui(Base)
	local MoneyPerSecondLabel = BaseInfoGui and BaseInfoGui:FindFirstChild("MoneyPerSecond", true)
	if not (MoneyPerSecondLabel and MoneyPerSecondLabel:IsA("TextLabel")) then return end

	MoneyPerSecondLabel.Text = string.format("%s/s", Format.Number(MoneyPerSecond or 0))
end

local function removeLegacyBaseInfoGuis(Base)
	local PlayerPart = Base and Base:FindFirstChild("Player")
	local PlayerGui = PlayerPart and PlayerPart:FindFirstChild("PlayerGui")
	if PlayerGui then
		PlayerGui:Destroy()
	end

	local DataPart = Base and Base:FindFirstChild("Data")
	local DataGui = DataPart and DataPart:FindFirstChild("DataGui")
	if DataGui then
		DataGui:Destroy()
	end
end

local function createBaseInfoGui(Player, Base)
	removeLegacyBaseInfoGuis(Base)

	local Anchor = getBaseInfoAnchor(Base)
	if not Anchor then return end

	local ExistingBaseInfoGui = Anchor:FindFirstChild(BASE_INFO_GUI_NAME)
	if ExistingBaseInfoGui then
		ExistingBaseInfoGui:Destroy()
	end

	local Resources = ctx.Resources
	local BaseInfoGui = Resources:WaitForChild(BASE_INFO_GUI_NAME):Clone()
	BaseInfoGui.Name = BASE_INFO_GUI_NAME
	BaseInfoGui.AlwaysOnTop = false
	BaseInfoGui.MaxDistance = BASE_GUI_MAX_DISTANCE
	BaseInfoGui.Enabled = true

	local Icon = BaseInfoGui:FindFirstChild("Icon", true)
	if Icon and Icon:IsA("ImageLabel") then
		Icon.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=512&height=512&format=png", Player.UserId)
	end

	local PlayerLabel = BaseInfoGui:FindFirstChild("Player", true)
	if PlayerLabel and PlayerLabel:IsA("TextLabel") then
		PlayerLabel.Text = getPlayerDisplayName(Player)
	end

	local RebirthsLabel = BaseInfoGui:FindFirstChild("Rebirths", true)
	if RebirthsLabel and RebirthsLabel:IsA("GuiObject") then
		RebirthsLabel.Visible = false
	end

	BaseInfoGui.Parent = Anchor
	updateBaseInfoMoneyPerSecond(Base, 0)

	SetProperties.AllClients(BaseInfoGui, {
		AlwaysOnTop = false,
		MaxDistance = BASE_GUI_MAX_DISTANCE
	})

	return BaseInfoGui
end
	ctx.getPlayerDisplayName = getPlayerDisplayName
	ctx.getBaseInfoAnchor = getBaseInfoAnchor
	ctx.getBaseInfoGui = getBaseInfoGui
	ctx.updateBaseInfoMoneyPerSecond = updateBaseInfoMoneyPerSecond
	ctx.removeLegacyBaseInfoGuis = removeLegacyBaseInfoGuis
	ctx.createBaseInfoGui = createBaseInfoGui
end

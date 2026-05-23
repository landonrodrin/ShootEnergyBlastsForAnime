local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))

local AnnouncementEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("Announcement")

local MESSAGE_LIFETIME = 2.25
local MAX_MESSAGES = 4
local ENTRY_OFFSET = UDim2.new(0, 0, 0, -16)
local ENTRY_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EXIT_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local ActiveMessages = {}
local MessageTroves = {}
local ScriptTrove = Trove.new()
local createMessageTrove

local Gui = script:FindFirstAncestor("AnnouncementGui")
if not Gui then
	warn("Announcement script must be parented under StarterGui.AnnouncementGui")
	return
end

Gui.ResetOnSpawn = false

local Container = Gui:WaitForChild("Container", 10)
if not Container then
	warn("AnnouncementGui is missing Container")
	return
end

local Template = Container:WaitForChild("MessageTemplate", 10)
if not Template then
	warn("AnnouncementGui.Container is missing MessageTemplate")
	return
end

Template.Visible = false

local function applyColour(MessageFrame, Colour)
	Colour = typeof(Colour) == "Color3" and Colour or Color3.fromRGB(255, 255, 255)

	local Stroke = MessageFrame:FindFirstChildOfClass("UIStroke")
	if Stroke then
		Stroke.Color = Colour
	end

	local Label = MessageFrame:FindFirstChild("Message")
	if Label and Label:IsA("TextLabel") then
		Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function removeMessage(MessageFrame)
	if not MessageFrame or not MessageFrame.Parent then return end
	if MessageFrame:GetAttribute("Removing") then return end
	MessageFrame:SetAttribute("Removing", true)

	for Index, ActiveMessage in ipairs(ActiveMessages) do
		if ActiveMessage ~= MessageFrame then continue end

		table.remove(ActiveMessages, Index)
		break
	end

	local Label = MessageFrame:FindFirstChild("Message")
	local Stroke = MessageFrame:FindFirstChildOfClass("UIStroke")

	if Label and Label:IsA("TextLabel") then
		TweenService:Create(Label, EXIT_TWEEN, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end

	if Stroke then
		TweenService:Create(Stroke, EXIT_TWEEN, {Transparency = 1}):Play()
	end

	local ExitTween = TweenService:Create(MessageFrame, EXIT_TWEEN, {
		BackgroundTransparency = 1,
		Position = MessageFrame.Position + UDim2.new(0, 0, 0, -12)
	})

	ExitTween:Play()
	local MessageTrove = MessageTroves[MessageFrame]
	if not MessageTrove then
		MessageTrove = createMessageTrove(MessageFrame)
	end

	MessageTrove:Add(ExitTween)
	MessageTrove:Connect(ExitTween.Completed, function()
		MessageTrove:Destroy()
	end)
end

createMessageTrove = function(MessageFrame)
	local MessageTrove = Trove.new()
	local Active = true
	MessageTroves[MessageFrame] = MessageTrove

	MessageTrove:Add(MessageFrame)
	MessageTrove:Add(function()
		Active = false
		MessageTroves[MessageFrame] = nil
	end)

	return MessageTrove, function()
		return Active
	end
end

local function trimActiveMessages()
	while #ActiveMessages > MAX_MESSAGES do
		removeMessage(ActiveMessages[1])
	end
end

local function showAnnouncement(Text, Colour)
	local MessageTrove
	local IsMessageActive
	local MessageFrame = Template:Clone()
	MessageTrove, IsMessageActive = createMessageTrove(MessageFrame)
	MessageFrame.Name = "Message"
	MessageFrame.LayoutOrder = os.clock() * 1000
	MessageFrame.Visible = true
	MessageFrame.Parent = Container

	local Label = MessageFrame:FindFirstChild("Message")
	if Label and Label:IsA("TextLabel") then
		Label.Text = tostring(Text or "")
		Label.TextTransparency = 1
		Label.TextStrokeTransparency = 1
	end

	applyColour(MessageFrame, Colour)

	local FinalPosition = MessageFrame.Position
	MessageFrame.Position = FinalPosition + ENTRY_OFFSET
	MessageFrame.BackgroundTransparency = 1

	local Stroke = MessageFrame:FindFirstChildOfClass("UIStroke")
	if Stroke then
		Stroke.Transparency = 1
	end

	table.insert(ActiveMessages, MessageFrame)
	trimActiveMessages()

	MessageTrove:Add(TweenService:Create(MessageFrame, ENTRY_TWEEN, {
		BackgroundTransparency = Template.BackgroundTransparency,
		Position = FinalPosition
	})):Play()

	if Label and Label:IsA("TextLabel") then
		MessageTrove:Add(TweenService:Create(Label, ENTRY_TWEEN, {TextTransparency = 0, TextStrokeTransparency = 0.35})):Play()
	end

	if Stroke then
		MessageTrove:Add(TweenService:Create(Stroke, ENTRY_TWEEN, {Transparency = 0.08})):Play()
	end

	MessageTrove:Add(task.delay(MESSAGE_LIFETIME, function()
		if not IsMessageActive() then return end

		removeMessage(MessageFrame)
	end))
end

ScriptTrove:Connect(AnnouncementEvent.OnClientEvent, showAnnouncement)

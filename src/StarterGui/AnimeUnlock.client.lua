local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MutationsConfigurations = require(ReplicatedStorage.Configurations.Modules:WaitForChild("MutationsConfigurations"))
local AnimeViewports = require(ReplicatedStorage.Modules:WaitForChild("AnimeViewports"))

local AnimeUnlockedEvent = ReplicatedStorage.Network.RemoteEvents:WaitForChild("AnimeUnlocked")

local DISPLAY_TIME = 2.7
local ENTRY_OFFSET = UDim2.new(0, 0, 0, -130)
local ENTRY_TWEEN = TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EXIT_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local Queue = {}
local Showing = false

local function getMutationColour(Mutation)
	local Configuration = MutationsConfigurations[Mutation]
	return Configuration and Configuration.Colour or Color3.fromRGB(120, 180, 255)
end

local Gui = script:FindFirstAncestor("AnimeUnlockGui")
if not Gui then
	warn("AnimeUnlock script must be parented under StarterGui.AnimeUnlockGui")
	return
end

Gui.ResetOnSpawn = false

local Container = Gui:WaitForChild("Container", 10)
if not Container then
	warn("AnimeUnlockGui is missing Container")
	return
end

local Template = Container:WaitForChild("BannerTemplate", 10)
if not Template then
	warn("AnimeUnlockGui.Container is missing BannerTemplate")
	return
end

Template.Visible = false

local function showNext()
	if Showing then return end

	local Data = table.remove(Queue, 1)
	if not Data then return end

	Showing = true

	local Banner = Template:Clone()
	Banner.Name = "UnlockBanner"
	Banner.Visible = true
	Banner.Parent = Container

	local Title = Banner:FindFirstChild("Title")
	if Title and Title:IsA("TextLabel") then
		Title.Text = string.format("You just unlocked \"%s\"", tostring(Data.Name or "Anime"))
		Title.TextTransparency = 1
		Title.TextStrokeTransparency = 1
	end

	local Accent = getMutationColour(Data.Mutation)
	local Stroke = Banner:FindFirstChildOfClass("UIStroke")
	if Stroke then
		Stroke.Color = Accent
		Stroke.Transparency = 1
	end

	local Preview = Banner:FindFirstChild("Preview")
	AnimeViewports.ReplacePlaceholder(Preview, Data.Name, Data.Mutation)

	local FinalPosition = Banner.Position
	Banner.Position = FinalPosition + ENTRY_OFFSET
	Banner.BackgroundTransparency = 1

	TweenService:Create(Banner, ENTRY_TWEEN, {
		BackgroundTransparency = Template.BackgroundTransparency,
		Position = FinalPosition
	}):Play()

	if Title and Title:IsA("TextLabel") then
		TweenService:Create(Title, ENTRY_TWEEN, {TextTransparency = 0, TextStrokeTransparency = 0.35}):Play()
	end

	if Stroke then
		TweenService:Create(Stroke, ENTRY_TWEEN, {Transparency = 0.08}):Play()
	end

	task.delay(DISPLAY_TIME, function()
		local ExitTween = TweenService:Create(Banner, EXIT_TWEEN, {
			BackgroundTransparency = 1,
			Position = Banner.Position + UDim2.new(0, 0, 0, -24)
		})

		ExitTween:Play()

		if Title and Title:IsA("TextLabel") then
			TweenService:Create(Title, EXIT_TWEEN, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end

		if Stroke then
			TweenService:Create(Stroke, EXIT_TWEEN, {Transparency = 1}):Play()
		end

		local CompletedConnection
		CompletedConnection = ExitTween.Completed:Connect(function()
			if CompletedConnection then
				CompletedConnection:Disconnect()
				CompletedConnection = nil
			end

			Banner:Destroy()
			Showing = false
			showNext()
		end)
	end)
end

local function showUnlock(Name, Mutation)
	table.insert(Queue, {
		Name = Name,
		Mutation = Mutation or "Default"
	})

	showNext()
end

AnimeUnlockedEvent.OnClientEvent:Connect(showUnlock)

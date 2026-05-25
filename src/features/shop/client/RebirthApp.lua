local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local RebirthsConfigurations = require(ReplicatedStorage.Features.Shop.Shared:WaitForChild("RebirthsConfigurations"))
local ReactUi = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("ReactUi"))
local UiAssets = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiAssets"))
local RightRailButton = require(ReplicatedStorage.Features.Ui.Client:WaitForChild("RightRailButton"))

local RequestController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("RequestController"))
local StatsController = require(ReplicatedStorage.Features.Players.Client:WaitForChild("StatsController"))
local Player = Players.LocalPlayer

local function useStat(Name, Default)
	local Value, SetValue = React.useState(StatsController.Get(Name) or Default)

	React.useEffect(function()
		local Connection = StatsController.Changed:Connect(function(ChangedName, NextValue)
			if ChangedName ~= Name then return end
			SetValue(NextValue)
		end)

		return function()
			Connection:Disconnect()
		end
	end, { Name })

	return Value
end

local function RebirthApp(Props)
	Props = Props or {}

	local LocalOpen, SetLocalOpen = React.useState(false)
	local Rebirths = useStat("Rebirths", 0)
	local Speed = useStat("Speed", GameConfigurations.Defaults.Speed)
	local CurrentConfiguration = RebirthsConfigurations[Rebirths]
	local NextConfiguration = RebirthsConfigurations[Rebirths + 1]
	local CurrentMultiplier = CurrentConfiguration and CurrentConfiguration.Multiplier or 1
	local Progress = NextConfiguration and math.clamp(Speed / NextConfiguration.Speed, 0, 1) or 1
	local Open = if Props.SetActivePanel then Props.ActivePanel == "Rebirth" else LocalOpen

	local function setOpen(NextOpen)
		if Props.SetActivePanel then
			Props.SetActivePanel(if NextOpen then "Rebirth" else nil)
		else
			SetLocalOpen(NextOpen)
		end
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Button = React.createElement(RightRailButton, {
			BackgroundColor3 = Color3.fromRGB(235, 77, 112),
			Icon = UiAssets.Icons.Rebirth,
			OnActivated = function()
				setOpen(not Open)
			end,
			Row = 3,
			Text = "Rebirth",
		}),
		Panel = React.createElement(ReactUi.Panel, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromOffset(520, 420),
			StrokeColor = Color3.fromRGB(235, 77, 112),
			StrokeThickness = 3,
			Visible = Open,
		}, {
			Header = React.createElement(ReactUi.Header, {
				OnClose = function()
					setOpen(false)
				end,
				Title = "Rebirth",
			}),
			Current = React.createElement(ReactUi.Text, {
				Position = UDim2.fromOffset(30, 88),
				Size = UDim2.new(1, -60, 0, 52),
				Text = string.format("Current: Rebirth %s | %sx Money", Rebirths, CurrentMultiplier),
			}),
			Next = React.createElement(ReactUi.Text, {
				Position = UDim2.fromOffset(30, 146),
				Size = UDim2.new(1, -60, 0, 52),
				Text = NextConfiguration and string.format("Next: Rebirth %s | %sx Money", Rebirths + 1, NextConfiguration.Multiplier) or "Max rebirth reached",
			}),
			ProgressBackground = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(42, 46, 60),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(40, 220),
				Size = UDim2.new(1, -80, 0, 42),
			}, {
				UICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
				Fill = React.createElement("Frame", {
					BackgroundColor3 = ReactUi.Colours.Green,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(Progress, 1),
				}, {
					UICorner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
				}),
				Label = React.createElement(ReactUi.Text, {
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.95, 0.75),
					Text = NextConfiguration and string.format("Speed %s / %s", Format.Number(Speed), Format.Number(NextConfiguration.Speed)) or "MAX",
				}),
			}),
			Rebirth = React.createElement(ReactUi.Button, {
				BackgroundColor3 = ReactUi.Colours.Green,
				Disabled = NextConfiguration == nil,
				OnActivated = function()
					RequestController.Rebirth()
				end,
				Position = UDim2.fromOffset(72, 314),
				Size = UDim2.fromOffset(170, 54),
				Text = "Rebirth",
			}),
			Skip = React.createElement(ReactUi.Button, {
				BackgroundColor3 = ReactUi.Colours.Accent,
				Disabled = NextConfiguration == nil,
				OnActivated = function()
					MarketplaceService:PromptProductPurchase(Player, GameConfigurations.ProductsIds.SkipRebirth)
				end,
				Position = UDim2.fromOffset(278, 314),
				Size = UDim2.fromOffset(170, 54),
				Text = "Skip",
			}),
		}),
	})
end

return RebirthApp

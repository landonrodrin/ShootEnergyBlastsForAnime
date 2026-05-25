local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))

local Player = Players.LocalPlayer

local function InviteApp()
	local Scale, SetScale = React.useState(1)

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.141146, 0.518072),
		Size = UDim2.fromScale(0.080208, 0.096386),
	}, {
		UIScale = React.createElement("UIScale", {
			Scale = Scale,
		}),
		UIStroke = React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter,
			Thickness = 3,
		}),
		Background = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.974, 0.962),
		}),
		Icon = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = "rbxassetid://78970344244825",
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.519481, 0.769944),
		}),
		Label = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromScale(0.467532, 0.288462),
			Text = "Invite",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextWrapped = true,
		}, {
			UIStroke = React.createElement("UIStroke", {
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = 3,
			}),
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = 30,
			}),
		}),
		Button = React.createElement("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Text = "",

			[React.Event.Activated] = function()
				SocialService:PromptGameInvite(Player)
			end,
			[React.Event.MouseEnter] = function()
				SetScale(1.1)
			end,
			[React.Event.MouseLeave] = function()
				SetScale(1)
			end,
			[React.Event.MouseButton1Down] = function()
				SetScale(0.9)
			end,
			[React.Event.MouseButton1Up] = function()
				SetScale(1)
			end,
		}),
	})
end

return InviteApp

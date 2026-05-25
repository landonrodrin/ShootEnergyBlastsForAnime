local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))
local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))

local Player = Players.LocalPlayer

local function productPriceText(PassId)
	local Success, ProductInfo = pcall(function()
		return MarketplaceService:GetProductInfoAsync(PassId, Enum.InfoType.GamePass)
	end)

	if not Success or typeof(ProductInfo) ~= "table" then
		return "\u{E002} --"
	end

	return string.format("\u{E002} %s", Format.Number(ProductInfo.PriceInRobux or 0))
end

local function cardGradient(VipPlus)
	if VipPlus then
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 105, 180)),
			ColorSequenceKeypoint.new(0.16, Color3.fromRGB(128, 0, 128)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		})
	end

	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 218, 48)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 0)),
	})
end

local function PassCard(Props)
	local OwnedText = if Props.Owned then "Owned" else Props.PriceText

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		LayoutOrder = Props.LayoutOrder,
		Size = UDim2.new(1, 0, 0, 180),
	}, {
		UIGradient = React.createElement("UIGradient", {
			Color = cardGradient(Props.VipPlus),
			Rotation = if Props.VipPlus then 11.25 else 90,
		}),
		UIStroke = React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter,
			Thickness = 3,
		}),
		Icon = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = Props.Icon,
			Position = UDim2.fromScale(0.12, 0.5),
			Size = UDim2.fromScale(0.12, 0.62),
		}),
		Title = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Position = UDim2.fromScale(0.5, 0.22),
			Size = UDim2.fromScale(0.25, 0.22),
			Text = Props.Title,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextWrapped = true,
		}, {
			UIStroke = React.createElement("UIStroke", {
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = 3,
			}),
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = 50,
			}),
		}),
		Description = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Position = UDim2.fromScale(0.5, 0.62),
			Size = UDim2.fromScale(0.36, 0.32),
			Text = "Boost your chances of getting rare things!",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextWrapped = true,
		}, {
			UIStroke = React.createElement("UIStroke", {
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = 3,
			}),
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = 40,
			}),
		}),
		PurchaseButton = React.createElement("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			AutoButtonColor = not Props.Owned,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Position = UDim2.fromScale(0.82, 0.64),
			Size = UDim2.fromOffset(240, 60),
			Text = OwnedText,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextWrapped = true,

			[React.Event.Activated] = function()
				if Props.Owned then
					return
				end

				MarketplaceService:PromptGamePassPurchase(Player, Props.PassId)
			end,
		}, {
			UIGradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 218, 48)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 0)),
				}),
				Rotation = 90,
			}),
			UIStroke = React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = 3,
			}),
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
				MaxTextSize = 50,
			}),
		}),
	})
end

local function ShopButton(Props)
	local Scale, SetScale = React.useState(1)

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.050521, 0.403151),
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
			Image = "rbxassetid://73314638149402",
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.519481, 0.769944),
		}),
		Label = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromScale(0.402597, 0.288462),
			Text = "Shop",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextWrapped = true,
		}, {
			UIGradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 191, 31)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 245, 110)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 191, 31)),
				}),
				Rotation = 45,
			}),
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
			ZIndex = 2,

			[React.Event.Activated] = Props.OnActivated,
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

local function ShopApp()
	local Open, SetOpen = React.useState(false)
	local OwnsVip, SetOwnsVip = React.useState(false)
	local OwnsVipPlus, SetOwnsVipPlus = React.useState(false)
	local VipPriceText, SetVipPriceText = React.useState("\u{E002} --")
	local VipPlusPriceText, SetVipPlusPriceText = React.useState("\u{E002} --")

	local VipId = GameConfigurations.PassesIds.Vip
	local VipPlusId = GameConfigurations.PassesIds.VipPlus

	React.useEffect(function()
		local Alive = true

		task.spawn(function()
			local OwnsVipSuccess, VipOwned = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, VipId)
			end)
			local OwnsVipPlusSuccess, VipPlusOwned = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, VipPlusId)
			end)

			local NextVipPriceText = productPriceText(VipId)
			local NextVipPlusPriceText = productPriceText(VipPlusId)

			if not Alive then
				return
			end

			SetOwnsVip(OwnsVipSuccess and VipOwned == true)
			SetOwnsVipPlus(OwnsVipPlusSuccess and VipPlusOwned == true)
			SetVipPriceText(NextVipPriceText)
			SetVipPlusPriceText(NextVipPlusPriceText)
		end)

		local PurchaseConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, GamepassId, WasPurchased)
			if not WasPurchased then
				return
			end

			if GamepassId == VipId then
				SetOwnsVip(true)
			elseif GamepassId == VipPlusId then
				SetOwnsVipPlus(true)
			end
		end)

		return function()
			Alive = false
			PurchaseConnection:Disconnect()
		end
	end, {})

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Button = React.createElement(ShopButton, {
			OnActivated = function()
				SetOpen(function(WasOpen)
					return not WasOpen
				end)
			end,
		}),
		Frame = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.614583, 0.686456),
			Visible = Open,
		}, {
			UIStroke = React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = 5,
			}),
			Header = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.067568),
				Size = UDim2.fromScale(1, 0.135135),
			}, {
				UIGradient = React.createElement("UIGradient", {
					Color = ColorSequence.new(Color3.fromRGB(247, 247, 99), Color3.fromRGB(255, 128, 0)),
					Rotation = 90,
				}),
				UIStroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Miter,
					Thickness = 5,
				}),
				Title = React.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					Position = UDim2.fromScale(0.12, 0.5),
					Size = UDim2.fromScale(0.2, 0.6),
					Text = "Shop",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextWrapped = true,
				}, {
					UIStroke = React.createElement("UIStroke", {
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = 5,
					}),
					UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
						MaxTextSize = 60,
					}),
				}),
				Close = React.createElement("TextButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(235, 55, 50),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					Position = UDim2.fromScale(0.958, 0.5),
					Size = UDim2.fromScale(0.085, 1),
					Text = "X",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,

					[React.Event.Activated] = function()
						SetOpen(false)
					end,
				}, {
					UIStroke = React.createElement("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = 5,
					}),
				}),
			}),
			List = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.57),
				Size = UDim2.fromScale(0.96, 0.78),
			}, {
				UIListLayout = React.createElement("UIListLayout", {
					Padding = UDim.new(0.04, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Vip = React.createElement(PassCard, {
					Icon = "rbxassetid://137815151495402",
					LayoutOrder = 1,
					Owned = OwnsVip,
					PassId = VipId,
					PriceText = VipPriceText,
					Title = "Vip",
					VipPlus = false,
				}),
				VipPlus = React.createElement(PassCard, {
					Icon = "rbxassetid://88847702235235",
					LayoutOrder = 2,
					Owned = OwnsVipPlus,
					PassId = VipPlusId,
					PriceText = VipPlusPriceText,
					Title = "Vip+",
					VipPlus = true,
				}),
			}),
		}),
	})
end

return ShopApp

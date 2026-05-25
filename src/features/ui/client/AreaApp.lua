local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))

local Player = Players.LocalPlayer

local function AreaApp()
	local AreaName, SetAreaName = React.useState(nil)
	local AreaColour, SetAreaColour = React.useState(Color3.fromRGB(255, 255, 255))
	local ActiveArea = React.useRef(nil)

	React.useEffect(function()
		local CharacterConnections = {}
		local CharacterAddedConnection = nil
		local ActiveTouches = {}

		local function disconnectCharacter()
			for _, Connection in ipairs(CharacterConnections) do
				Connection:Disconnect()
			end

			table.clear(CharacterConnections)
		end

		local function setArea(PossibleArea, AreaConfiguration)
			ActiveArea.current = PossibleArea

			if not PossibleArea or not AreaConfiguration then
				SetAreaName(nil)
				return
			end

			SetAreaName(PossibleArea.Name)
			SetAreaColour(AreaConfiguration.Colour or Color3.fromRGB(255, 255, 255))
		end

		local function connectCharacter(Character)
			disconnectCharacter()
			ActiveTouches = {}
			setArea(nil)

			for _, Descendant in ipairs(Character:GetDescendants()) do
				if not Descendant:IsA("BasePart") then
					continue
				end

				table.insert(CharacterConnections, Descendant.Touched:Connect(function(Hit)
					if Character:IsAncestorOf(Hit) then
						return
					end

					local PossibleArea = Hit.Parent
					if not PossibleArea then
						return
					end

					local AreaConfiguration = AreasConfigurations[PossibleArea.Name]
					if not AreaConfiguration then
						return
					end

					ActiveTouches[PossibleArea] = (ActiveTouches[PossibleArea] or 0) + 1

					if ActiveArea.current ~= PossibleArea then
						setArea(PossibleArea, AreaConfiguration)
					end
				end))

				table.insert(CharacterConnections, Descendant.TouchEnded:Connect(function(Hit)
					local PossibleArea = Hit.Parent
					if not PossibleArea then
						return
					end

					local Count = ActiveTouches[PossibleArea]
					if not Count then
						return
					end

					Count -= 1
					if Count <= 0 then
						ActiveTouches[PossibleArea] = nil

						if ActiveArea.current == PossibleArea then
							setArea(nil)
						end
					else
						ActiveTouches[PossibleArea] = Count
					end
				end))
			end
		end

		if Player.Character then
			connectCharacter(Player.Character)
		end

		CharacterAddedConnection = Player.CharacterAdded:Connect(connectCharacter)

		return function()
			disconnectCharacter()

			if CharacterAddedConnection then
				CharacterAddedConnection:Disconnect()
			end
		end
	end, {})

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.065),
		Size = UDim2.fromScale(0.979, 0.093),
		Visible = AreaName ~= nil,
	}, {
		Area = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Text = if AreaName then string.format("%s Area", AreaName) else "",
			TextColor3 = AreaColour,
			TextScaled = true,
			TextStrokeTransparency = 0,
			TextWrapped = true,
		}, {
			UIStroke = React.createElement("UIStroke", {
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = 10,
			}),
		}),
	})
end

return AreaApp

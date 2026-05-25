local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AreasConfigurations = require(ReplicatedStorage.Features.Anime.Shared:WaitForChild("AreasConfigurations"))

local Player = Players.LocalPlayer
local AreaGui = script.Parent
local AreaFrame = AreaGui:WaitForChild("AreaFrame")
local Area = nil
local ActiveTouches = {}

local function setArea(possibleArea, areaConfiguration)
	if not possibleArea or not areaConfiguration then
		Area = nil
		AreaFrame.Visible = false

		return
	end

	Area = possibleArea

	local colour = areaConfiguration.Colour or Color3.fromRGB(255, 255, 255)
	local colourText = string.format("rgb(%d, %d, %d)", colour.R * 255, colour.G * 255, colour.B * 255)

	AreaFrame.Area.Text = string.format("<font color=\"%s\">%s</font> Area", colourText, Area.Name)
	AreaFrame.Visible = true
end

local function connectCharacter(character)
	setArea()
	ActiveTouches = {}

	for _, descendant in ipairs(character:GetDescendants()) do
		if not descendant:IsA("BasePart") then continue end

		descendant.Touched:Connect(function(hit)
			if character:IsAncestorOf(hit) then return end

			local possibleArea = hit.Parent
			if not possibleArea then return end

			local areaConfiguration = AreasConfigurations[possibleArea.Name]
			if not areaConfiguration then return end

			ActiveTouches[possibleArea] = (ActiveTouches[possibleArea] or 0) + 1

			if Area ~= possibleArea then
				setArea(possibleArea, areaConfiguration)
			end
		end)

		descendant.TouchEnded:Connect(function(hit)
			local possibleArea = hit.Parent
			if not possibleArea then return end

			local count = ActiveTouches[possibleArea]
			if not count then return end

			count -= 1

			if count <= 0 then
				ActiveTouches[possibleArea] = nil

				if Area == possibleArea then
					setArea(nil)
				end
			else
				ActiveTouches[possibleArea] = count
			end
		end)
	end
end

local Character = Player.Character or Player.CharacterAdded:Wait()

connectCharacter(Character)
Player.CharacterAdded:Connect(connectCharacter)

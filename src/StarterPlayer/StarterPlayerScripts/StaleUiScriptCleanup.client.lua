local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local TARGETS = {
	DataGui = "Data",
	DropGui = "Drop",
	RebirthGui = "Rebirth",
	SpeedGui = "Speed",
	UpgradesGui = "Upgrades",
}

local function purgeDuplicates(GuiName, ScriptName)
	local Gui = PlayerGui:FindFirstChild(GuiName)
	if not Gui then return end

	for _, Child in ipairs(Gui:GetChildren()) do
		if Child:IsA("ScreenGui") and Child.Name == GuiName then
			Child:Destroy()
		end
	end

	local MatchingScripts = {}
	for _, Child in ipairs(Gui:GetChildren()) do
		if Child:IsA("LocalScript") and Child.Name == ScriptName then
			table.insert(MatchingScripts, Child)
		end
	end

	if #MatchingScripts <= 1 then return end

	table.sort(MatchingScripts, function(Left, Right)
		local LeftIsByteNet = Left:GetAttribute("ByteNetUiScript") == true
		local RightIsByteNet = Right:GetAttribute("ByteNetUiScript") == true

		if LeftIsByteNet ~= RightIsByteNet then
			return LeftIsByteNet
		end

		return Left:GetDebugId() > Right:GetDebugId()
	end)

	for Index = 2, #MatchingScripts do
		MatchingScripts[Index].Disabled = true
		MatchingScripts[Index]:Destroy()
	end
end

local function purgeAll()
	for GuiName, ScriptName in pairs(TARGETS) do
		purgeDuplicates(GuiName, ScriptName)
	end
end

task.defer(purgeAll)
task.delay(1, purgeAll)

PlayerGui.ChildAdded:Connect(function(Child)
	local ScriptName = TARGETS[Child.Name]
	if not ScriptName then return end

	task.defer(purgeDuplicates, Child.Name, ScriptName)
	task.delay(1, purgeDuplicates, Child.Name, ScriptName)
end)

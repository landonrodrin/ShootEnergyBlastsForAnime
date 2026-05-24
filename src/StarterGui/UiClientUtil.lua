local UiClientUtil = {}

local MAX_DUMP_ITEMS = 40

function UiClientUtil.Normalize(Text)
	return tostring(Text or ""):lower():gsub("[%s%p_]+", "")
end

function UiClientUtil.NameOrTextMatches(Object, Candidates)
	local Name = UiClientUtil.Normalize(Object.Name)
	local Text = ""

	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		Text = UiClientUtil.Normalize(Object.Text)
	end

	for _, Candidate in ipairs(Candidates) do
		local Normalized = UiClientUtil.Normalize(Candidate)
		if Normalized ~= "" and (Name:find(Normalized, 1, true) or Text:find(Normalized, 1, true)) then
			return true
		end
	end

	return false
end

function UiClientUtil.WaitForDescendants(Gui, Timeout)
	local Deadline = os.clock() + (Timeout or 3)

	repeat
		if #Gui:GetDescendants() > 0 then
			return true
		end

		task.wait(0.1)
	until os.clock() >= Deadline

	return #Gui:GetDescendants() > 0
end

function UiClientUtil.DumpDescendants(Gui)
	local Items = {}

	for _, Descendant in ipairs(Gui:GetDescendants()) do
		if #Items >= MAX_DUMP_ITEMS then
			table.insert(Items, "...")
			break
		end

		local Text = ""
		if Descendant:IsA("TextLabel") or Descendant:IsA("TextButton") or Descendant:IsA("TextBox") then
			Text = string.format(" text=%q", Descendant.Text)
		end

		table.insert(Items, string.format("%s<%s>%s", Descendant:GetFullName():gsub("^.*PlayerGui%.", ""), Descendant.ClassName, Text))
	end

	return table.concat(Items, "; ")
end

function UiClientUtil.WarnMissing(Script, Key, Warned, Message, Gui)
	if Warned[Key] then return end

	Warned[Key] = true
	warn(string.format("%s %s. Descendants: %s", Script:GetFullName(), Message, UiClientUtil.DumpDescendants(Gui)))
end

function UiClientUtil.PurgeDuplicateSiblingScripts(Script)
	local Parent = Script.Parent
	if not Parent then return end

	for _, Child in ipairs(Parent:GetChildren()) do
		if Child ~= Script and Child:IsA("LocalScript") and Child.Name == Script.Name then
			Child.Disabled = true
			Child:Destroy()
		end
	end
end

function UiClientUtil.FindFirstButton(Gui, Candidates)
	for _, Descendant in ipairs(Gui:GetDescendants()) do
		if Descendant:IsA("GuiButton") and UiClientUtil.NameOrTextMatches(Descendant, Candidates) then
			return Descendant
		end
	end

	for _, Descendant in ipairs(Gui:GetDescendants()) do
		if Descendant:IsA("GuiButton") then
			return Descendant
		end
	end

	return nil
end

function UiClientUtil.FindLabels(Gui, Candidates)
	local Labels = {}

	for _, Descendant in ipairs(Gui:GetDescendants()) do
		if Descendant:IsA("TextLabel") and UiClientUtil.NameOrTextMatches(Descendant, Candidates) then
			table.insert(Labels, Descendant)
		end
	end

	return Labels
end

return UiClientUtil

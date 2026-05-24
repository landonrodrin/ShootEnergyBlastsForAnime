local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Trove = require(ReplicatedStorage.Shared:WaitForChild("Trove"))
local Packets = require(ReplicatedStorage.Network:WaitForChild("Packets"))

local ScriptTrove = Trove.new()

local ADMIN_COMMANDS = {
	{
		Name = "OwnerResetCommand",
		PrimaryAlias = "/reset",
		SecondaryAlias = "reset"
	},
	{
		Name = "OwnerRichCommand",
		PrimaryAlias = "/rich",
		SecondaryAlias = "rich"
	},
	{
		Name = "OwnerFastCommand",
		PrimaryAlias = "/fast",
		SecondaryAlias = "fast"
	}
}

local function trim(Value)
	return (Value or ""):match("^%s*(.-)%s*$")
end

local function requestAdminCommand(UnfilteredText)
	local Text = string.lower(trim(UnfilteredText))

	for _, Command in ipairs(ADMIN_COMMANDS) do
		if Text == Command.PrimaryAlias or Text == Command.SecondaryAlias then
			Packets.adminCommand.send({
				Message = Text,
			})
			return
		end
	end
end

local function getCommandsParent()
	return TextChatService:WaitForChild("TextChatCommands", 10) or TextChatService
end

local function getOrCreateAdminCommand(CommandConfiguration)
	local Parent = getCommandsParent()
	local Command = Parent:FindFirstChild(CommandConfiguration.Name) or TextChatService:FindFirstChild(CommandConfiguration.Name)

	if not Command then
		Command = Instance.new("TextChatCommand")
		Command.Name = CommandConfiguration.Name
		Command.Parent = Parent
	end

	Command.PrimaryAlias = CommandConfiguration.PrimaryAlias
	Command.SecondaryAlias = CommandConfiguration.SecondaryAlias
	Command.AutocompleteVisible = false
	Command.Enabled = true

	return Command
end

for _, CommandConfiguration in ipairs(ADMIN_COMMANDS) do
	local Command = getOrCreateAdminCommand(CommandConfiguration)

	ScriptTrove:Connect(Command.Triggered, function(_, UnfilteredText)
		requestAdminCommand(UnfilteredText or CommandConfiguration.PrimaryAlias)
	end)
end

ScriptTrove:Connect(TextChatService.SendingMessage, function(TextChatMessage)
	requestAdminCommand(TextChatMessage.Text)
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

local Animations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("Animations"))

local InviteController = {}

local Started = false

function InviteController.Init() end

function InviteController.Start()
	if Started then return end
	Started = true

	local Player = Players.LocalPlayer
	local PlayerGui = Player:WaitForChild("PlayerGui")
	local InviteGui = PlayerGui:WaitForChild("InviteGui")
	local InviteButton = InviteGui:WaitForChild("InviteButton")

	InviteButton.Button.Activated:Connect(function()
		SocialService:PromptGameInvite(Player)
	end)

	Animations.Button(InviteButton, InviteButton.Button)
end

return InviteController

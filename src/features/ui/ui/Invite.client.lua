local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

local Animations = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("Animations"))

local Player = Players.LocalPlayer
local InviteGui = script.Parent
local InviteButton = InviteGui:WaitForChild("InviteButton")

InviteButton.Button.Activated:Connect(function()
	SocialService:PromptGameInvite(Player)
end)

Animations.Button(InviteButton, InviteButton.Button)

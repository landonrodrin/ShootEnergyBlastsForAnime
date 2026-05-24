local Players = game:GetService("Players")

local RequestGuard = {}

local LastAcceptedAt = {}

function RequestGuard.Allow(Player, Action, Cooldown)
	if typeof(Player) ~= "Instance" or not Player:IsA("Player") or not Player.Parent then
		return false
	end

	if type(Action) ~= "string" or Action == "" then
		return false
	end

	Cooldown = tonumber(Cooldown)
	if not Cooldown or Cooldown < 0 then
		return false
	end

	local PlayerRequests = LastAcceptedAt[Player]
	if not PlayerRequests then
		PlayerRequests = {}
		LastAcceptedAt[Player] = PlayerRequests
	end

	local Now = os.clock()
	local LastAccepted = PlayerRequests[Action]
	if LastAccepted and Now - LastAccepted < Cooldown then
		return false
	end

	PlayerRequests[Action] = Now
	return true
end

function RequestGuard.Clear(Player)
	LastAcceptedAt[Player] = nil
end

Players.PlayerRemoving:Connect(RequestGuard.Clear)

return RequestGuard

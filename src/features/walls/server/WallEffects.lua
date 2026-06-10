local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WallConfig = require(ReplicatedStorage.Features.Walls.Shared:WaitForChild("WallConfig"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))

local WallEffects = {}

local function getDebrisCount(state)
	local debrisConfig = WallConfig.ClientDebris or {}
	if state.maxHP <= 1 then
		return debrisConfig.VipCount or 4
	end

	return debrisConfig.NormalCount or 8
end

function WallEffects.PlayDebris(state, hitPosition)
	Packets.wallDebris.sendToAll({
		Id = state.id,
		DisplayName = state.displayName,
		WallCFrame = state.originalCFrame,
		WallSize = state.originalSize,
		Wall = state.wall,
		HitPosition = hitPosition,
		Color = Packets.EncodeColour(state.originalColor),
		Material = Packets.EncodeMaterial(state.originalMaterial),
		Count = getDebrisCount(state),
	})
end

return WallEffects

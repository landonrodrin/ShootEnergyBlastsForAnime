local StationZones = {}

local SELL_ZONE_PATH = "Workspace.Sell.Interaction Circle.Hitbox"
local UPGRADE_ZONE_PATH = "Workspace.Upgrade.Interaction Circle.Hitbox"

local function getChild(parent, name)
	if not parent then
		return nil
	end

	return parent:FindFirstChild(name)
end

local function configureHitbox(hitbox)
	if not (hitbox and hitbox:IsA("BasePart")) then
		return hitbox
	end

	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = true
	hitbox.CanQuery = true
	hitbox.Transparency = 1
	hitbox.CastShadow = false

	return hitbox
end

local function getInteractionHitbox(station)
	local interactionCircle = getChild(station, "Interaction Circle")
	return configureHitbox(getChild(interactionCircle, "Hitbox"))
end

function StationZones.GetSellZoneContainer()
	local sell = workspace:FindFirstChild("Sell") or workspace:WaitForChild("Sell", 10)
	return getInteractionHitbox(sell)
end

function StationZones.GetUpgradeZoneContainer()
	local upgrade = workspace:FindFirstChild("Upgrade") or workspace:WaitForChild("Upgrade", 10)
	return getInteractionHitbox(upgrade)
end

function StationZones.GetZonePosition(container)
	if not container then
		return nil
	end

	if container:IsA("BasePart") then
		return container.Position
	end

	if container:IsA("Model") then
		return container:GetPivot().Position
	end

	return nil
end

function StationZones.WarnMissingSellZone()
	warn(string.format("Missing sell station zone: %s", SELL_ZONE_PATH))
end

function StationZones.WarnMissingUpgradeZone()
	warn(string.format("Missing upgrades zone: %s", UPGRADE_ZONE_PATH))
end

return StationZones

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WallConfig = require(ReplicatedStorage.Features.Walls.Shared:WaitForChild("WallConfig"))
local WallUi = require(script.Parent:WaitForChild("WallUi"))

local WallRegistry = {}

local wallStates = {}
local wallsByPart = {}

local function getNumberAttribute(instance, attributeName)
	local value = instance:GetAttribute(attributeName)
	if typeof(value) == "number" and value > 0 then
		return value
	end

	return nil
end

local function getStringAttribute(instance, attributeName)
	local value = instance:GetAttribute(attributeName)
	if typeof(value) == "string" and value ~= "" then
		return value
	end

	return nil
end

local function getStripOrder(strip)
	return tonumber(strip.Name:match("(%d+)$")) or math.huge
end

local function getOrderedStrips(strips)
	local orderedStrips = {}

	for _, strip in ipairs(strips:GetChildren()) do
		table.insert(orderedStrips, strip)
	end

	table.sort(orderedStrips, function(left, right)
		local leftOrder = getStripOrder(left)
		local rightOrder = getStripOrder(right)
		if leftOrder == rightOrder then
			return left.Name < right.Name
		end

		return leftOrder < rightOrder
	end)

	return orderedStrips
end

function WallRegistry.SetWallActive(state, active)
	local wall = state.wall
	wall.Transparency = active and state.originalTransparency or 1
	wall.CanCollide = active and state.originalCanCollide or false
	wall.CanQuery = active and state.originalCanQuery or false
	wall.CanTouch = active and state.originalCanTouch or false
	wall.Anchored = true
	wall:SetAttribute("Destroyed", not active)
	WallUi.SetEnabled(state, active)
end

function WallRegistry.SetHp(state, hp)
	state.hp = math.clamp(hp, 0, state.maxHP)
	state.wall:SetAttribute("HP", state.hp)
	WallUi.UpdateHpLabel(state)
end

local function buildWallState(wall, defaults)
	if wallsByPart[wall] then
		return wallsByPart[wall]
	end

	if not wall:IsA("BasePart") then
		warn("Damageable wall must be a BasePart:", wall:GetFullName())
		return nil
	end

	local maxHP = getNumberAttribute(wall, "MaxHP") or defaults and defaults.MaxHP
	if not maxHP then
		warn("Damageable wall is missing a positive MaxHP attribute:", wall:GetFullName())
		return nil
	end

	local displayName = getStringAttribute(wall, "DisplayName") or defaults and defaults.DisplayName or wall.Name
	local id = getStringAttribute(wall, "WallId") or defaults and defaults.Id or wall:GetFullName()

	local state = {
		id = id,
		displayName = displayName,
		wall = wall,
		maxHP = maxHP,
		hp = maxHP,
		originalTransparency = wall.Transparency,
		originalCanCollide = wall.CanCollide,
		originalCanQuery = wall.CanQuery,
		originalCanTouch = wall.CanTouch,
		originalColor = wall.Color,
		originalMaterial = wall.Material,
		originalSize = wall.Size,
		originalCFrame = wall.CFrame,
	}

	table.insert(wallStates, state)
	wallsByPart[wall] = state

	wall:SetAttribute("DamageableWall", true)
	wall:SetAttribute("MaxHP", state.maxHP)
	WallRegistry.SetHp(state, state.hp)
	WallRegistry.SetWallActive(state, true)

	return state
end

local function seedConfiguredWallAttributes(wall, config, strip)
	if not wall:IsA("BasePart") then
		warn("Configured damageable wall must be a BasePart:", wall:GetFullName())
		return nil
	end

	if wall:GetAttribute("DamageableWall") ~= true then
		wall:SetAttribute("DamageableWall", true)
	end

	if not getNumberAttribute(wall, "MaxHP") then
		wall:SetAttribute("MaxHP", config.MaxHP)
	end

	if not getStringAttribute(wall, "DisplayName") then
		wall:SetAttribute("DisplayName", config.DisplayName or config.Name or wall.Name)
	end

	if strip and not getStringAttribute(wall, "WallId") then
		wall:SetAttribute("WallId", string.format("%s:%s", strip.Name, wall.Name))
	end

	return wall
end

local function seedConfiguredWallsInStrips(strips)
	local foundByName = {}

	for _, strip in ipairs(getOrderedStrips(strips)) do
		for _, wallConfig in ipairs(WallConfig.Walls) do
			local wallName = wallConfig.Name
			local wall = wallName and strip:FindFirstChild(wallName)
			if not wall then continue end

			foundByName[wallName] = true
			seedConfiguredWallAttributes(wall, wallConfig, strip)
		end
	end

	for _, wallConfig in ipairs(WallConfig.Walls) do
		local wallName = wallConfig.Name
		if wallName and not foundByName[wallName] then
			warn("Missing configured damageable wall template in Workspace.Strips:", wallName)
		end
	end
end

function WallRegistry.RegisterDamageableWalls()
	local strips = workspace:FindFirstChild("Strips")
	if strips then
		seedConfiguredWallsInStrips(strips)

		for _, descendant in ipairs(strips:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("DamageableWall") == true then
				buildWallState(descendant)
			end
		end
	else
		warn("Workspace.Strips is missing; unable to discover configured damageable walls.")
	end
end

function WallRegistry.GetWallFromHit(instance)
	local current = instance
	while current and current ~= workspace do
		local state = wallsByPart[current]
		if state then
			return state
		end
		current = current.Parent
	end

	return nil
end

function WallRegistry.ResetWall(state)
	state.destroyed = false
	state.wall.CFrame = state.originalCFrame
	state.wall.Size = state.originalSize
	state.wall.Color = state.originalColor
	state.wall.Material = state.originalMaterial
	state.wall:SetAttribute("MaxHP", state.maxHP)
	WallRegistry.SetHp(state, state.maxHP)
	WallRegistry.SetWallActive(state, true)
end

function WallRegistry.ResetAllWalls()
	for _, state in pairs(wallStates) do
		WallRegistry.ResetWall(state)
	end
end

return WallRegistry

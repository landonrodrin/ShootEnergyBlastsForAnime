local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))

local Player = Players.LocalPlayer
local DEFAULT_EDGE_TOLERANCE = 0.75
local DEFAULT_AXIS_TOLERANCE = 6

local ShopZonePanel = {}

local function getAxisValue(Vector, AxisName)
	if AxisName == "X" then
		return Vector.X
	end
	if AxisName == "Y" then
		return Vector.Y
	end

	return Vector.Z
end

local function getRootPosition()
	local Character = Player.Character
	local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
	if not (RootPart and RootPart:IsA("BasePart")) then
		return nil
	end

	return RootPart.Position
end

local function isInsideBlock(Part, LocalPosition, EdgeTolerance)
	local HalfSize = Part.Size * 0.5
	return math.abs(LocalPosition.X) <= HalfSize.X + EdgeTolerance
		and math.abs(LocalPosition.Y) <= HalfSize.Y + EdgeTolerance
		and math.abs(LocalPosition.Z) <= HalfSize.Z + EdgeTolerance
end

local function isInsideCylinder(Part, LocalPosition, EdgeTolerance)
	local Size = Part.Size
	local AxisName = "X"
	local AxisSize = Size.X
	if Size.Y < AxisSize then
		AxisName = "Y"
		AxisSize = Size.Y
	end
	if Size.Z < AxisSize then
		AxisName = "Z"
		AxisSize = Size.Z
	end

	local AxisDistance = math.abs(getAxisValue(LocalPosition, AxisName))
	local AxisLimit = math.max((AxisSize * 0.5) + EdgeTolerance, DEFAULT_AXIS_TOLERANCE)
	if AxisDistance > AxisLimit then
		return false
	end

	local RadiusAxisA = if AxisName == "X" then "Y" else "X"
	local RadiusAxisB = if AxisName == "Z" then "Y" else "Z"
	local RadiusA = (getAxisValue(Size, RadiusAxisA) * 0.5) + EdgeTolerance
	local RadiusB = (getAxisValue(Size, RadiusAxisB) * 0.5) + EdgeTolerance
	if RadiusA <= 0 or RadiusB <= 0 then
		return false
	end

	local NormalizedA = getAxisValue(LocalPosition, RadiusAxisA) / RadiusA
	local NormalizedB = getAxisValue(LocalPosition, RadiusAxisB) / RadiusB
	return (NormalizedA * NormalizedA) + (NormalizedB * NormalizedB) <= 1
end

local function isRootInsideContainer(Container, EdgeTolerance)
	if not (Container and Container:IsA("BasePart")) then
		return false
	end

	local RootPosition = getRootPosition()
	if not RootPosition then
		return false
	end

	local LocalPosition = Container.CFrame:PointToObjectSpace(RootPosition)
	if Container:IsA("Part") and Container.Shape == Enum.PartType.Cylinder then
		return isInsideCylinder(Container, LocalPosition, EdgeTolerance)
	end

	return isInsideBlock(Container, LocalPosition, EdgeTolerance)
end

function ShopZonePanel.UsePanelZone(Options)
	local PanelName = Options.PanelName
	local ActivePanelRef = React.useRef(Options.ActivePanel)
	local LocalOpenRef = React.useRef(Options.LocalOpen == true)
	local SetActivePanelRef = React.useRef(Options.SetActivePanel)
	local SetLocalOpenRef = React.useRef(Options.SetLocalOpen)
	local OnClosedByExitRef = React.useRef(Options.OnClosedByExit)
	local DebugEnabledRef = React.useRef(Options.DebugEnabled == true)
	local DebugNameRef = React.useRef(Options.DebugName or PanelName)
	local ManualCloseRef = React.useRef(false)
	local ZoneInsideRef = React.useRef(false)

	ActivePanelRef.current = Options.ActivePanel
	LocalOpenRef.current = Options.LocalOpen == true
	SetActivePanelRef.current = Options.SetActivePanel
	SetLocalOpenRef.current = Options.SetLocalOpen
	OnClosedByExitRef.current = Options.OnClosedByExit
	DebugEnabledRef.current = Options.DebugEnabled == true
	DebugNameRef.current = Options.DebugName or PanelName

	local function debugLog(...)
		if not DebugEnabledRef.current then
			return
		end

		print(string.format("[ShopZonePanel:%s]", tostring(DebugNameRef.current)), ...)
	end

	local function setOpen(NextOpen)
		local SetActivePanel = SetActivePanelRef.current
		if SetActivePanel then
			local NextPanel = if NextOpen then PanelName else nil
			if ActivePanelRef.current == NextPanel then
				return
			end

			debugLog("SetActivePanel", ActivePanelRef.current, "->", NextPanel)
			ActivePanelRef.current = NextPanel
			SetActivePanel(NextPanel)
			return
		end

		local SetLocalOpen = SetLocalOpenRef.current
		if SetLocalOpen then
			if LocalOpenRef.current == NextOpen then
				return
			end

			debugLog("SetLocalOpen", LocalOpenRef.current, "->", NextOpen)
			LocalOpenRef.current = NextOpen
			SetLocalOpen(NextOpen)
		end
	end

	local function closeIfActive()
		local SetActivePanel = SetActivePanelRef.current
		if SetActivePanel then
			if ActivePanelRef.current ~= PanelName then
				return
			end

			debugLog("SetActivePanel", ActivePanelRef.current, "->", nil)
			ActivePanelRef.current = nil
			SetActivePanel(nil)
			return
		end

		local SetLocalOpen = SetLocalOpenRef.current
		if SetLocalOpen then
			if not LocalOpenRef.current then
				return
			end

			debugLog("SetLocalOpen", LocalOpenRef.current, "->", false)
			LocalOpenRef.current = false
			SetLocalOpen(false)
		end
	end

	local function closeFromExit()
		closeIfActive()
		if OnClosedByExitRef.current then
			OnClosedByExitRef.current()
		end
	end

	React.useEffect(function()
		local GetZoneContainer = Options.GetZoneContainer
		local WarnMissingZone = Options.WarnMissingZone
		local EdgeTolerance = Options.EdgeTolerance or DEFAULT_EDGE_TOLERANCE
		local ZoneContainer = GetZoneContainer and GetZoneContainer()

		local CharacterConnection = Player.CharacterRemoving:Connect(function()
			debugLog("character removing")
			ZoneInsideRef.current = false
			closeFromExit()
			ManualCloseRef.current = false
		end)

		if ZoneContainer then
			local function updatePresence()
				local IsInside = isRootInsideContainer(ZoneContainer, EdgeTolerance)
				if IsInside == ZoneInsideRef.current then
					return
				end

				ZoneInsideRef.current = IsInside
				if IsInside then
					debugLog("entered")
					if not ManualCloseRef.current then
						setOpen(true)
					else
						debugLog("entered while manually closed")
					end
					return
				end

				debugLog("exited")
				closeFromExit()
				ManualCloseRef.current = false
			end

			if isRootInsideContainer(ZoneContainer, EdgeTolerance) then
				debugLog("initial inside")
				ZoneInsideRef.current = true
				if not ManualCloseRef.current then
					setOpen(true)
				end
			end

			local HeartbeatConnection = RunService.Heartbeat:Connect(updatePresence)

			return function()
				ZoneInsideRef.current = false
				HeartbeatConnection:Disconnect()
				CharacterConnection:Disconnect()
			end
		elseif WarnMissingZone then
			WarnMissingZone()
		end

		return function()
			ZoneInsideRef.current = false
			CharacterConnection:Disconnect()
		end
	end, {})

	return {
		CloseManually = function()
			debugLog("manual close")
			ManualCloseRef.current = true
			closeIfActive()
		end,
		Open = if SetActivePanelRef.current then Options.ActivePanel == PanelName else Options.LocalOpen == true,
	}
end

return ShopZonePanel

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run Wally install and restart the Rojo sync.")

local ZONEPLUS_TIMEOUT = 10

local function findIndexedZonePlus()
	local PackageIndex = Packages:FindFirstChild("_Index")
	if not PackageIndex then return nil end

	local Prefixes = {
		"mattschrubb_zoneplus@",
		"1foreverhd_zoneplus@",
	}

	for _, Child in ipairs(PackageIndex:GetChildren()) do
		for _, Prefix in ipairs(Prefixes) do
			if Child.Name:sub(1, #Prefix) == Prefix then
				local ZonePlusPackage = Child:FindFirstChild("zoneplus")
				if ZonePlusPackage then
					return ZonePlusPackage
				end
			end
		end
	end

	return nil
end

local function findZonePlusShim()
	local ZonePlusModule = Packages:FindFirstChild("zoneplus")
	if ZonePlusModule then
		return ZonePlusModule
	end

	return Packages:FindFirstChild("ZonePlus")
end

local function findZonePlusModule()
	local Deadline = os.clock() + ZONEPLUS_TIMEOUT

	repeat
		local ZonePlusModule = findIndexedZonePlus() or findZonePlusShim()
		if ZonePlusModule then
			return ZonePlusModule
		end

		task.wait()
	until os.clock() >= Deadline

	return nil
end

local ZonePlusModule = findZonePlusModule()
assert(ZonePlusModule, "Missing ReplicatedStorage.Packages.zoneplus or ReplicatedStorage.Packages._Index.*_zoneplus@*.zoneplus; run Wally install and restart the Rojo sync.")

local ZonePlusReference = ReplicatedStorage:FindFirstChild("ZonePlusReference")
local RunContextName = if game:GetService("RunService"):IsClient() then "Client" else "Server"
local ZonePlusShim = findZonePlusShim()
local IsSelfReference = ZonePlusReference
	and ZonePlusReference:IsA("ObjectValue")
	and (ZonePlusReference.Value == ZonePlusModule or ZonePlusReference.Value == ZonePlusShim)
if IsSelfReference then
	local ContextMarker = ZonePlusReference:FindFirstChild(RunContextName)
	if ContextMarker then
		ZonePlusReference:Destroy()
	end
end

local ZonePlus = require(ZonePlusModule)

function ZonePlus.ConnectSignal(OwnerTrove, Signal, Callback)
	assert(OwnerTrove and typeof(OwnerTrove.Add) == "function", "ZonePlus.ConnectSignal requires an owner trove")
	assert(typeof(Signal) == "table" and typeof(Signal.Connect) == "function", "ZonePlus.ConnectSignal requires a ZonePlus signal")
	assert(typeof(Callback) == "function", "ZonePlus.ConnectSignal requires a callback")

	local Connection = Signal:Connect(Callback)
	OwnerTrove:Add(function()
		if Connection and typeof(Connection.Disconnect) == "function" then
			Connection:Disconnect()
		end
	end)

	return Connection
end

function ZonePlus.CreatePresenceZone(Container)
	local Zone = ZonePlus.new(Container)
	Zone:setDetection("WholeBody")
	return Zone
end

return ZonePlus

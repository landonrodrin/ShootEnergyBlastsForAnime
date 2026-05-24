local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run Wally install and restart the Rojo sync.")

local ZONEPLUS_TIMEOUT = 10

local function findIndexedZonePlus()
	local PackageIndex = Packages:FindFirstChild("_Index")
	if not PackageIndex then return nil end

	local Prefixes = {
		"1foreverhd_zoneplus@",
		"mattschrubb_zoneplus@",
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

local function findZonePlusModule()
	local Deadline = os.clock() + ZONEPLUS_TIMEOUT

	repeat
		local ZonePlusModule = Packages:FindFirstChild("zoneplus") or findIndexedZonePlus()
		if ZonePlusModule then
			return ZonePlusModule
		end

		task.wait()
	until os.clock() >= Deadline

	return nil
end

local ZonePlusModule = findZonePlusModule()
assert(ZonePlusModule, "Missing ReplicatedStorage.Packages.zoneplus or ReplicatedStorage.Packages._Index.*_zoneplus@*.zoneplus; run Wally install and restart the Rojo sync.")

return require(ZonePlusModule)

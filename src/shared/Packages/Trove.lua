local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run Wally install and restart the Rojo sync.")

local TROVE_TIMEOUT = 10

local function findIndexedTrove()
	local PackageIndex = Packages:FindFirstChild("_Index")
	if not PackageIndex then return nil end

	for _, Child in ipairs(PackageIndex:GetChildren()) do
		if Child.Name:sub(1, #"sleitnick_trove@") == "sleitnick_trove@" then
			local TrovePackage = Child:FindFirstChild("trove")
			if TrovePackage then
				return TrovePackage
			end
		end
	end

	return nil
end

local function findTroveModule()
	local Deadline = os.clock() + TROVE_TIMEOUT

	repeat
		local TroveModule = Packages:FindFirstChild("trove") or findIndexedTrove()
		if TroveModule then
			return TroveModule
		end

		task.wait()
	until os.clock() >= Deadline

	return nil
end

local TroveModule = findTroveModule()
assert(TroveModule, "Missing ReplicatedStorage.Packages.trove or ReplicatedStorage.Packages._Index.sleitnick_trove@*.trove; run wally install and restart the Rojo sync.")

return require(TroveModule)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run Wally install and restart the Rojo sync.")

local LOADER_TIMEOUT = 10

local function findIndexedLoader()
	local PackageIndex = Packages:FindFirstChild("_Index")
	if not PackageIndex then return nil end

	for _, Child in ipairs(PackageIndex:GetChildren()) do
		if Child.Name:sub(1, #"sleitnick_loader@") == "sleitnick_loader@" then
			local LoaderPackage = Child:FindFirstChild("loader")
			if LoaderPackage then
				return LoaderPackage
			end
		end
	end

	return nil
end

local function findLoaderModule()
	local Deadline = os.clock() + LOADER_TIMEOUT

	repeat
		local LoaderModule = Packages:FindFirstChild("loader") or findIndexedLoader()
		if LoaderModule then
			return LoaderModule
		end

		task.wait()
	until os.clock() >= Deadline

	return nil
end

local LoaderModule = findLoaderModule()
assert(LoaderModule, "Missing ReplicatedStorage.Packages.loader or ReplicatedStorage.Packages._Index.sleitnick_loader@*.loader; run wally install and restart the Rojo sync.")

local Loader = require(LoaderModule)
assert(type(Loader) == "table" and type(Loader.LoadChildren) == "function", "ReplicatedStorage.Packages.loader did not return Sleitnick Loader; run wally install and restart the Rojo sync.")

return Loader

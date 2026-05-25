local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run Wally install and restart the Rojo sync.")

local PROMISE_TIMEOUT = 10

local function findIndexedPromise()
	local PackageIndex = Packages:FindFirstChild("_Index")
	if not PackageIndex then return nil end

	for _, Child in ipairs(PackageIndex:GetChildren()) do
		if Child.Name:sub(1, #"evaera_promise@") == "evaera_promise@" then
			local PromisePackage = Child:FindFirstChild("promise")
			if PromisePackage then
				return PromisePackage
			end
		end
	end

	return nil
end

local function findPromiseModule()
	local Deadline = os.clock() + PROMISE_TIMEOUT

	repeat
		local PromiseModule = Packages:FindFirstChild("promise") or findIndexedPromise()
		if PromiseModule then
			return PromiseModule
		end

		task.wait()
	until os.clock() >= Deadline

	return nil
end

local PromiseModule = findPromiseModule()
assert(PromiseModule, "Missing ReplicatedStorage.Packages.promise or ReplicatedStorage.Packages._Index.evaera_promise@*.promise; run Wally install and restart the Rojo sync.")

return require(PromiseModule)

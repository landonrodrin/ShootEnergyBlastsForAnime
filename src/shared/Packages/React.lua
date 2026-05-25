local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run Wally install and restart the Rojo sync.")

local REACT_TIMEOUT = 10

local function findIndexedReact()
	local PackageIndex = Packages:FindFirstChild("_Index")
	if not PackageIndex then return nil end

	for _, Child in ipairs(PackageIndex:GetChildren()) do
		if Child.Name:sub(1, #"jsdotlua_react@") == "jsdotlua_react@" then
			local ReactPackage = Child:FindFirstChild("react")
			if ReactPackage then
				return ReactPackage
			end
		end
	end

	return nil
end

local function findReactModule()
	local Deadline = os.clock() + REACT_TIMEOUT

	repeat
		local ReactModule = Packages:FindFirstChild("react") or Packages:FindFirstChild("React") or findIndexedReact()
		if ReactModule then
			return ReactModule
		end

		task.wait()
	until os.clock() >= Deadline

	return nil
end

local ReactModule = findReactModule()
assert(ReactModule, "Missing ReplicatedStorage.Packages.react or ReplicatedStorage.Packages._Index.jsdotlua_react@*.react; run Wally install and restart the Rojo sync.")

return require(ReactModule)

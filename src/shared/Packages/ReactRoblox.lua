local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run Wally install and restart the Rojo sync.")

local REACT_ROBLOX_TIMEOUT = 10

local function findIndexedReactRoblox()
	local PackageIndex = Packages:FindFirstChild("_Index")
	if not PackageIndex then return nil end

	for _, Child in ipairs(PackageIndex:GetChildren()) do
		if Child.Name:sub(1, #"jsdotlua_react-roblox@") == "jsdotlua_react-roblox@" then
			local ReactRobloxPackage = Child:FindFirstChild("react-roblox")
			if ReactRobloxPackage then
				return ReactRobloxPackage
			end
		end
	end

	return nil
end

local function findReactRobloxModule()
	local Deadline = os.clock() + REACT_ROBLOX_TIMEOUT

	repeat
		local ReactRobloxModule = Packages:FindFirstChild("react-roblox")
			or Packages:FindFirstChild("ReactRoblox")
			or findIndexedReactRoblox()
		if ReactRobloxModule then
			return ReactRobloxModule
		end

		task.wait()
	until os.clock() >= Deadline

	return nil
end

local ReactRobloxModule = findReactRobloxModule()
assert(ReactRobloxModule, "Missing ReplicatedStorage.Packages.react-roblox or ReplicatedStorage.Packages._Index.jsdotlua_react-roblox@*.react-roblox; run Wally install and restart the Rojo sync.")

return require(ReactRobloxModule)

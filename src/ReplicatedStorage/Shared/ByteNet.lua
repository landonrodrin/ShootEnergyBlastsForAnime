local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local function findIndexedByteNet()
	local Index = Packages:FindFirstChild("_Index")
	if not Index then return nil end

	for _, Child in ipairs(Index:GetChildren()) do
		if Child.Name:match("_bytenet@") then
			local ByteNetPackage = Child:FindFirstChild("bytenet")
			if ByteNetPackage then
				return ByteNetPackage
			end
		end
	end
end

local function findByteNetModule()
	for _ = 1, 50 do
		local ByteNetModule = Packages:FindFirstChild("bytenet") or Packages:FindFirstChild("ByteNet") or findIndexedByteNet()
		if ByteNetModule then
			return ByteNetModule
		end

		task.wait(0.1)
	end
end

local ByteNetModule = findByteNetModule()
assert(ByteNetModule, "Missing ReplicatedStorage.Packages.bytenet or ReplicatedStorage.Packages._Index.*_bytenet@*.bytenet; run wally install and restart the Rojo sync.")

return require(ByteNetModule)

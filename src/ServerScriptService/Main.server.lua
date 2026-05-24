local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PACKAGE_TIMEOUT = 10

local function waitForRequiredChild(Parent, Name, Description)
	local Child = Parent:WaitForChild(Name, PACKAGE_TIMEOUT)
	if Child then
		return Child
	end

	error(string.format("Missing %s; run wally install and restart the Rojo sync.", Description), 0)
end

local function hasIndexedPackage(Packages, Prefix, ChildName)
	local PackageIndex = Packages:FindFirstChild("_Index")
	if not PackageIndex then return false end

	for _, Child in ipairs(PackageIndex:GetChildren()) do
		if Child.Name:sub(1, #Prefix) == Prefix and Child:FindFirstChild(ChildName) then
			return true
		end
	end

	return false
end

local function hasAnyIndexedPackage(Packages, Prefixes, ChildName)
	for _, Prefix in ipairs(Prefixes) do
		if hasIndexedPackage(Packages, Prefix, ChildName) then
			return true
		end
	end

	return false
end

local function waitForPackageShimOrIndex(Packages, ShimName, IndexPrefix, IndexChildName, Description)
	local Deadline = os.clock() + PACKAGE_TIMEOUT

	repeat
		if Packages:FindFirstChild(ShimName) or hasIndexedPackage(Packages, IndexPrefix, IndexChildName) then
			return
		end

		task.wait()
	until os.clock() >= Deadline

	error(string.format("Missing %s; run wally install and restart the Rojo sync.", Description), 0)
end

local function waitForPackageShimOrAnyIndex(Packages, ShimName, IndexPrefixes, IndexChildName, Description)
	local Deadline = os.clock() + PACKAGE_TIMEOUT

	repeat
		if Packages:FindFirstChild(ShimName) or hasAnyIndexedPackage(Packages, IndexPrefixes, IndexChildName) then
			return
		end

		task.wait()
	until os.clock() >= Deadline

	error(string.format("Missing %s; run wally install and restart the Rojo sync.", Description), 0)
end

local function preflightPackages()
	local Packages = waitForRequiredChild(ReplicatedStorage, "Packages", "ReplicatedStorage.Packages")

	waitForPackageShimOrIndex(Packages, "promise", "evaera_promise@", "promise", "ReplicatedStorage.Packages.promise or ReplicatedStorage.Packages._Index.evaera_promise@*.promise")
	waitForPackageShimOrIndex(Packages, "trove", "sleitnick_trove@", "trove", "ReplicatedStorage.Packages.trove or ReplicatedStorage.Packages._Index.sleitnick_trove@*.trove")
	waitForPackageShimOrIndex(Packages, "bytenet", "ffrostflame_bytenet@", "bytenet", "ReplicatedStorage.Packages.bytenet or ReplicatedStorage.Packages._Index.ffrostflame_bytenet@*.bytenet")
	waitForPackageShimOrIndex(Packages, "cmdr", "evaera_cmdr@", "cmdr", "ReplicatedStorage.Packages.cmdr or ReplicatedStorage.Packages._Index.evaera_cmdr@*.cmdr")
	waitForPackageShimOrAnyIndex(Packages, "zoneplus", {"1foreverhd_zoneplus@", "mattschrubb_zoneplus@"}, "zoneplus", "ReplicatedStorage.Packages.zoneplus or ReplicatedStorage.Packages._Index.*_zoneplus@*.zoneplus")
end

preflightPackages()

local WallGameplay = require(script.Parent:WaitForChild("WallGameplay"))
local Bases = require(ServerStorage.Modules:WaitForChild("Bases"))
local PlayersModule = require(ServerStorage.Modules:WaitForChild("Players"))
local Anime = require(ServerStorage.Modules:WaitForChild("Anime"))

WallGameplay.Start()
Bases.Setup()
PlayersModule.Setup()
Anime.Setup()

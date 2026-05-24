local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run wally install and restart the Rojo sync.")

local TOPBARPLUS_TIMEOUT = 10

local function findTopbarPlusPackage()
	local Deadline = os.clock() + TOPBARPLUS_TIMEOUT

	repeat
		local Index = Packages:FindFirstChild("_Index")
		if Index then
			local PinnedPackage = Index:FindFirstChild("1foreverhd_topbarplus@3.4.0")
			if PinnedPackage and PinnedPackage:FindFirstChild("topbarplus") then
				return PinnedPackage.topbarplus
			end

			for _, Child in ipairs(Index:GetChildren()) do
				if Child.Name:sub(1, #"1foreverhd_topbarplus@") == "1foreverhd_topbarplus@" then
					local TopbarPlus = Child:FindFirstChild("topbarplus")
					if TopbarPlus then
						return TopbarPlus
					end
				end
			end
		end

		task.wait()
	until os.clock() >= Deadline

	return nil
end

local TopbarPlus = findTopbarPlusPackage()
assert(TopbarPlus, "Missing ReplicatedStorage.Packages._Index.1foreverhd_topbarplus@*.topbarplus; run wally install and restart the Rojo sync.")

return require(TopbarPlus)

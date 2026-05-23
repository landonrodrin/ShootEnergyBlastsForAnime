local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
assert(Packages, "Missing ReplicatedStorage.Packages; run Wally install and restart the Rojo sync.")

local PromiseModule = Packages:WaitForChild("promise", 10)
assert(PromiseModule, "Missing ReplicatedStorage.Packages.promise; run Wally install and restart the Rojo sync.")

return require(PromiseModule)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrClientModule = ReplicatedStorage:WaitForChild("CmdrClient", 10)
assert(CmdrClientModule, "Missing ReplicatedStorage.CmdrClient; make sure the server started, Cmdr loaded, and Rojo synced ReplicatedStorage.Packages.cmdr.")

local CmdrClient = require(CmdrClientModule)

CmdrClient:SetActivationKeys({Enum.KeyCode.Y})
CmdrClient:SetEnabled(true)

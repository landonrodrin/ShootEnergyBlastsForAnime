local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared:WaitForChild("Loader"))
local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local Shooting = require(script.Parent:WaitForChild("Shooting"))
local WallDebris = require(script.Parent:WaitForChild("WallDebris"))
local LadderNudge = require(script.Parent:WaitForChild("LadderNudge"))

local Controllers = Loader.LoadChildren(script.Parent:WaitForChild("Controllers"))
local ControllerOrder = {
	"RequestController",
	"StatsController",
	"InventoryController",
	"PlayerController",
	"HeldPreviewController",
	"BaseController",
	"UiController",
}

for _, ControllerName in ipairs(ControllerOrder) do
	local Controller = Controllers[ControllerName]
	assert(Controller, string.format("Loader failed to load Controllers.%s; make sure it is a ModuleScript under StarterPlayerScripts.Controllers.", ControllerName))
	assert(type(Controller) == "table", string.format("Controllers.%s must return a controller table.", ControllerName))
	assert(type(Controller.Start) == "function", string.format("Controllers.%s must expose Start().", ControllerName))
end

for _, ControllerName in ipairs(ControllerOrder) do
	local Controller = Controllers[ControllerName]
	if Controller and Controller.Init then
		Controller.Init(Controllers)
	end
end

for _, ControllerName in ipairs(ControllerOrder) do
	local Controller = Controllers[ControllerName]
	if Controller and Controller.Start then
		Controller.Start()
	end
end

Packets.MarkClientReady()

Shooting.Start()
WallDebris.Start()
LadderNudge.Start()

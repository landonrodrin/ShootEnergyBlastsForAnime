local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local Features = ReplicatedStorage:WaitForChild("Features")
local PlayersFeature = Features:WaitForChild("Players")
local BasesFeature = Features:WaitForChild("Bases")
local UiFeature = Features:WaitForChild("Ui")
local WallsFeature = Features:WaitForChild("Walls")

local ControllerOrder = {
	"RequestController",
	"StatsController",
	"InventoryController",
	"PlayerController",
	"HeldPreviewController",
	"BaseController",
	"UiController",
}

local ControllerModules = {
	RequestController = PlayersFeature.Client:WaitForChild("RequestController"),
	StatsController = PlayersFeature.Client:WaitForChild("StatsController"),
	InventoryController = PlayersFeature.Client:WaitForChild("InventoryController"),
	PlayerController = PlayersFeature.Client:WaitForChild("PlayerController"),
	HeldPreviewController = PlayersFeature.Client:WaitForChild("HeldPreviewController"),
	BaseController = BasesFeature.Client:WaitForChild("BaseController"),
	UiController = UiFeature.Client.Controllers:WaitForChild("UiController"),
}

local Controllers = {}

for _, ControllerName in ipairs(ControllerOrder) do
	Controllers[ControllerName] = require(ControllerModules[ControllerName])
end

for _, ControllerName in ipairs(ControllerOrder) do
	local Controller = Controllers[ControllerName]
	assert(Controller, string.format("Failed to load feature controller %s.", ControllerName))
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

local Shooting = require(WallsFeature.Client:WaitForChild("Shooting"))
local WallDebris = require(WallsFeature.Client:WaitForChild("WallDebris"))
local LadderNudge = require(WallsFeature.Client:WaitForChild("LadderNudge"))

Shooting.Start()
WallDebris.Start()
LadderNudge.Start()

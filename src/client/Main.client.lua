local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage.Shared.Network:WaitForChild("Packets"))
local Features = ReplicatedStorage:WaitForChild("Features")
local PlayersFeature = Features:WaitForChild("Players")
local BasesFeature = Features:WaitForChild("Bases")
local ShopFeature = Features:WaitForChild("Shop")
local UiFeature = Features:WaitForChild("Ui")
local WallsFeature = Features:WaitForChild("Walls")

local OPTIONAL_CONTROLLER_WAIT_SECONDS = 3

local RequiredControllerOrder = {
	"RequestController",
	"StatsController",
	"InventoryController",
	"PlayerController",
	"HeldPreviewController",
	"BaseController",
	"UiController",
}

local OptionalControllerOrder = {
	"AreaController",
	"InviteController",
	"ShopController",
}

local RequiredControllerModules = {
	RequestController = PlayersFeature.Client:WaitForChild("RequestController"),
	StatsController = PlayersFeature.Client:WaitForChild("StatsController"),
	InventoryController = PlayersFeature.Client:WaitForChild("InventoryController"),
	PlayerController = PlayersFeature.Client:WaitForChild("PlayerController"),
	HeldPreviewController = PlayersFeature.Client:WaitForChild("HeldPreviewController"),
	BaseController = BasesFeature.Client:WaitForChild("BaseController"),
	UiController = UiFeature.Client:WaitForChild("UiController"),
}

local OptionalControllerModules = {
	AreaController = {
		Feature = UiFeature,
		FolderName = "Client",
		ModuleName = "AreaController",
	},
	InviteController = {
		Feature = UiFeature,
		FolderName = "Client",
		ModuleName = "InviteController",
	},
	ShopController = {
		Feature = ShopFeature,
		FolderName = "Client",
		ModuleName = "ShopController",
	},
}

local Controllers = {}

local function tryLoadOptionalController(ControllerName)
	local ModuleConfig = OptionalControllerModules[ControllerName]
	local Feature = ModuleConfig and ModuleConfig.Feature
	local Folder = Feature and (Feature:FindFirstChild(ModuleConfig.FolderName) or Feature:WaitForChild(ModuleConfig.FolderName, OPTIONAL_CONTROLLER_WAIT_SECONDS))
	if not Folder then
		warn(string.format("Optional controller %s skipped: missing feature client folder.", ControllerName))
		return
	end

	local ModuleScript = Folder:FindFirstChild(ModuleConfig.ModuleName)
		or Folder:WaitForChild(ModuleConfig.ModuleName, OPTIONAL_CONTROLLER_WAIT_SECONDS)
	if not ModuleScript then
		warn(string.format("Optional controller %s skipped: missing module %s.%s.", ControllerName, Folder:GetFullName(), ModuleConfig.ModuleName))
		return
	end

	local Success, Controller = pcall(require, ModuleScript)
	if not Success then
		warn(string.format("Optional controller %s skipped: %s", ControllerName, tostring(Controller)))
		return
	end

	if type(Controller) ~= "table" or type(Controller.Start) ~= "function" then
		warn(string.format("Optional controller %s skipped: controller must return a table with Start().", ControllerName))
		return
	end

	Controllers[ControllerName] = Controller
end

for _, ControllerName in ipairs(RequiredControllerOrder) do
	Controllers[ControllerName] = require(RequiredControllerModules[ControllerName])
end

for _, ControllerName in ipairs(RequiredControllerOrder) do
	local Controller = Controllers[ControllerName]
	assert(Controller, string.format("Failed to load feature controller %s.", ControllerName))
	assert(type(Controller) == "table", string.format("Controllers.%s must return a controller table.", ControllerName))
	assert(type(Controller.Start) == "function", string.format("Controllers.%s must expose Start().", ControllerName))
end

for _, ControllerName in ipairs(RequiredControllerOrder) do
	local Controller = Controllers[ControllerName]
	if Controller and Controller.Init then
		Controller.Init(Controllers)
	end
end

for _, ControllerName in ipairs(RequiredControllerOrder) do
	local Controller = Controllers[ControllerName]
	if Controller and Controller.Start then
		Controller.Start()
	end
end

Packets.MarkClientReady()

for _, ControllerName in ipairs(OptionalControllerOrder) do
	tryLoadOptionalController(ControllerName)

	local Controller = Controllers[ControllerName]
	if Controller and Controller.Init then
		local Success, Message = pcall(Controller.Init, Controllers)
		if not Success then
			warn(string.format("Optional controller %s Init() failed: %s", ControllerName, tostring(Message)))
			Controllers[ControllerName] = nil
			continue
		end
	end

	if Controller and Controller.Start then
		local Success, Message = pcall(Controller.Start)
		if not Success then
			warn(string.format("Optional controller %s Start() failed: %s", ControllerName, tostring(Message)))
			Controllers[ControllerName] = nil
		end
	end
end

local Shooting = require(WallsFeature.Client:WaitForChild("Shooting"))
local WallDebris = require(WallsFeature.Client:WaitForChild("WallDebris"))
local LadderNudge = require(WallsFeature.Client:WaitForChild("LadderNudge"))

Shooting.Start()
WallDebris.Start()
LadderNudge.Start()

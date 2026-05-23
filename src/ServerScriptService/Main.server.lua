local ServerStorage = game:GetService("ServerStorage")

local WallGameplay = require(script.Parent:WaitForChild("WallGameplay"))
local Bases = require(ServerStorage.Modules:WaitForChild("Bases"))
local PlayersModule = require(ServerStorage.Modules:WaitForChild("Players"))
local Anime = require(ServerStorage.Modules:WaitForChild("Anime"))

WallGameplay.Start()
Bases.Setup()
PlayersModule.Setup()
Anime.Setup()

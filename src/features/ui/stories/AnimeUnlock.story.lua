local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Shared.Packages:WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage.Packages:WaitForChild("react-roblox"))
local AnimeUnlockFeedView = require(ReplicatedStorage.Features.Ui.Client.Views:WaitForChild("AnimeUnlockFeedView"))
local UiTuning = require(ReplicatedStorage.Features.Ui.Shared:WaitForChild("UiTuning"))

local ANIME_UNLOCK = UiTuning.AnimeUnlock

local ANIME = {
	Goku = "Goku",
	Luffy = "Luffy",
	Naruto = "Naruto",
}

local MUTATIONS = {
	Default = "Default",
	Diamond = "Diamond",
	Gold = "Gold",
}

local function buildUnlocks(Name, Mutation, Count)
	local Names = { Name, "Naruto", "Goku", "Luffy" }
	local Mutations = { Mutation, "Gold", "Diamond", "Default" }
	local Unlocks = {}

	for Index = 1, math.max(1, Count) do
		table.insert(Unlocks, {
			Id = Index,
			Mutation = Mutations[((Index - 1) % #Mutations) + 1],
			Name = Names[((Index - 1) % #Names) + 1],
		})
	end

	return Unlocks
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Anime = ANIME.Luffy,
		Mutation = MUTATIONS.Default,
		Count = 1,
		CardWidth = ANIME_UNLOCK.CardWidth,
		CardHeight = ANIME_UNLOCK.CardHeight,
		PreviewSize = ANIME_UNLOCK.PreviewSize,
		PreviewScale = ANIME_UNLOCK.PreviewScale,
	},
	story = function(Props)
		local Controls = Props.controls

		return React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 120, 55),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
		}, {
			Unlocks = React.createElement(AnimeUnlockFeedView, {
				CardHeight = Controls.CardHeight,
				CardWidth = Controls.CardWidth,
				PreviewScale = Controls.PreviewScale,
				PreviewSize = Controls.PreviewSize,
				Unlocks = buildUnlocks(Controls.Anime, Controls.Mutation, Controls.Count),
			}),
		})
	end,
}

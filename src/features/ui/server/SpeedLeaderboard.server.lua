local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")

local GameConfigurations = require(ReplicatedStorage.Shared.Constants:WaitForChild("GameConfigurations"))
local Format = require(ReplicatedStorage.Shared.Util:WaitForChild("Format"))

local SpeedDataStore = DataStoreService:GetOrderedDataStore("Speed")
local LeaderboardGui = script.Parent
local LeaderboardFrame = LeaderboardGui:WaitForChild("LeaderboardFrame")
local Updating = false

local IndexColours = {
	[1] = Color3.fromRGB(255, 210, 74),
	[2] = Color3.fromRGB(200, 201, 204),
	[3] = Color3.fromRGB(242, 125, 0),
}

local function update()
	if Updating then return end

	Updating = true

	for _, entryFrame in ipairs(LeaderboardFrame.Leaderboard:GetChildren()) do
		if entryFrame:IsA("Frame") then
			entryFrame:Destroy()
		end
	end

	local pageSuccess, page = pcall(function()
		return SpeedDataStore:GetSortedAsync(false, 100, 1)
	end)

	if not pageSuccess or not page then
		Updating = false

		return
	end

	for index, entry in ipairs(page:GetCurrentPage()) do
		task.spawn(function()
			local userId = tonumber(entry.key)
			if not userId or userId <= 0 then return end

			local playerFrame = script.Resources:WaitForChild("Player"):Clone()

			playerFrame.Index.Text = string.format("#%s", index)
			playerFrame.Speed.Text = Format.Number(entry.value or 0)

			local userInfoSuccess, result = pcall(function()
				return UserService:GetUserInfosByUserIdsAsync({ userId })
			end)

			if userInfoSuccess and result and #result > 0 then
				local userInfo = result[1]

				playerFrame.Name = userInfo.Username
				playerFrame.Username.Text = userInfo.Username
			end

			playerFrame.BackgroundColor3 = IndexColours[index] or Color3.fromRGB(255, 255, 255)
			playerFrame.LayoutOrder = index
			playerFrame.Parent = LeaderboardFrame:WaitForChild("Leaderboard")
			playerFrame.Visible = true
		end)

		task.wait(0.1)
	end

	Updating = false
end

while true do
	pcall(update)

	task.wait(GameConfigurations.LeaderboardsUpdateDelay)
end

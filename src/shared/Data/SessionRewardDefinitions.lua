local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sift = require(ReplicatedStorage.Packages.Sift)
type Seconds = number
type Reward = { [string]: any }

export type SessionReward = {
	time: Seconds,
	rewards: { Reward },
}

local rewardLists: { { Reward } } = {
	{
		{ type = "power", amount = 250 },
	},
	{
		{ type = "power", amount = 75 },
	},
	{
		{ type = "premium", amount = 5 },
	},
	{
		{ type = "power", amount = 500 },
	},
	{
		{ type = "booster", minutes = 5 },
	},
	{
		{ type = "power", amount = 1000 },
	},
	{
		{ type = "premium", amount = 10 },
	},
	{
		{ type = "power", amount = 2500 },
	},
	{
		{ type = "booster", minutes = 10 },
	},
	{
		{ type = "power", amount = 5000 },
	},
	{
		{ type = "premium", amount = 25 },
	},
	{
		{ type = "booster", minutes = 15 },
	},
}

local listCount = #rewardLists
local sessionDuration = RunService:IsStudio() and 2.5 or 25

return Sift.Array.map(rewardLists, function(rewardList, index)
	local minutes = math.round(index / listCount * sessionDuration * 10) / 10

	return {
		time = minutes * 60,
		rewards = Sift.Dictionary.copyDeep(rewardList),
	}
end) :: { SessionReward }

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)

type Seconds = number

type PlaytimeReward = {
	RoundCountRequired: number,
	Currency: CurrencyDefinitions.CurrencyType,
	Amount: number,
}

type Config = {
	GameVersion: string,
	DataStoreKey: string,

	PlaytimeRewards: {
		RefreshTime: Seconds,
		Rewards: { PlaytimeReward },
	},

	DailyChallenges: {
		Count: number,
		Reward: { Currency: string, Amount: number },
	},
}

local Config: Config = {
	GameVersion = `{game.PlaceId}.{game.PlaceVersion}`,
	DataStoreKey = "DATA_VERSION_3",

	PlaytimeRewards = {
		RefreshTime = 24 * 60 * 60,
		Rewards = {
			{ RoundCountRequired = 1, Currency = "power", Amount = 250 },
			{ RoundCountRequired = 3, Currency = "power", Amount = 500 },
			{ RoundCountRequired = 6, Currency = "premium", Amount = 10 },
			{ RoundCountRequired = 8, Currency = "power", Amount = 750 },
			{ RoundCountRequired = 10, Currency = "premium", Amount = 15 },
		},
	},

	DailyChallenges = {
		Count = 2,
		Reward = { Currency = "premium", Amount = 15 },
	},
}

return Config

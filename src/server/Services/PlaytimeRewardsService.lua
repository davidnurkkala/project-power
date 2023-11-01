local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Sift = require(ReplicatedStorage.Packages.Sift)

type UnixTimestamp = number
type Data = {
	timestamp: UnixTimestamp,
	count: number,
}

local DATA_KEY = "PlaytimeRewards"
local DEFAULT_DATA: Data = {
	timestamp = 0,
	count = 0,
}

DataStore2.Combine(Configuration.DataStoreKey, DATA_KEY)

local PlaytimeRewardsService = {}
PlaytimeRewardsService.className = "PlaytimeRewardsService"
PlaytimeRewardsService.priority = 0

function PlaytimeRewardsService:init()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "PlaytimeRewardsService")
	self._notified = self._comm:CreateSignal("Notified")
end

function PlaytimeRewardsService:start() end

function PlaytimeRewardsService:resetPlayer(player: Player)
	local store = DataStore2(DATA_KEY, player)
	return store:GetAsync(DEFAULT_DATA):andThen(function(data: Data)
		data.timestamp = 0
		data.count = 0
		store:Set(data)
	end)
end

function PlaytimeRewardsService:rewardPlayer(player: Player)
	local store = DataStore2(DATA_KEY, player)
	return store:GetAsync(DEFAULT_DATA):andThen(function(data: Data)
		local now: UnixTimestamp = DateTime.now().UnixTimestamp
		local difference = now - data.timestamp
		if difference > Configuration.PlaytimeRewards.RefreshTime then
			data.timestamp = now
			data.count = 0
		end

		data.count += 1

		local rewardIndex = Sift.Array.findWhere(Configuration.PlaytimeRewards.Rewards, function(reward)
			return reward.RoundCountRequired == data.count
		end)
		if rewardIndex then
			local reward = Configuration.PlaytimeRewards.Rewards[rewardIndex]
			CurrencyService:addCurrency(player, reward.Currency, reward.Amount)
		end

		store:Set(data)

		self._notified:Fire(player, {
			count = data.count,
			timestamp = data.timestamp,
		})
	end)
end

return Loader:registerSingleton(PlaytimeRewardsService)

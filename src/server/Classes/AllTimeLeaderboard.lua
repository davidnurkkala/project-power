local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local TauntStore = require(ReplicatedStorage.Shared.Singletons.TauntStore)

local CACHE_TIME = 60 * 5
local RETRY_COUNT = 8

type Promise<T> = any

type Cache = {
	timeCreated: number,
	data: any,
}

local AllTimeLeaderboard = {}
AllTimeLeaderboard.__index = AllTimeLeaderboard

function AllTimeLeaderboard.new(currency)
	local self = setmetatable({}, AllTimeLeaderboard)

	self._dataStore = DataStoreService:GetOrderedDataStore("AllTimeLeaderboard", currency)
	self._cache = nil

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				Promise.try(function()
					self._dataStore:SetAsync(player.UserId, CurrencyService:getCurrency(player, currency))
				end):expect()
				task.wait(2.5)
			end
			task.wait(30)
		end
	end)

	return self
end

function AllTimeLeaderboard:_createCache(data): Cache
	return {
		timeCreated = tick(),
		data = data,
	}
end

function AllTimeLeaderboard:_hasCacheExpired(cache: Cache): boolean
	return tick() - cache.timeCreated > CACHE_TIME
end

function AllTimeLeaderboard:get(): Promise<any?>
	if (self._cache == nil) or (self:_hasCacheExpired(self._cache)) then
		self._cache = nil

		return Promise.retry(function()
			return Promise.try(function()
				local pages: DataStorePages = self._dataStore:GetSortedAsync(false, 10)
				return pages:GetCurrentPage()
			end)
				:andThen(function(entries)
					return Promise.all(Sift.Array.map(entries, function(entry)
						return Promise.new(function(resolve)
							local taunt = TauntStore:get(entry.key):expect()
							local name = Players:GetNameFromUserIdAsync(entry.key)
							resolve(Sift.Dictionary.merge(entry, {
								taunt = taunt,
								name = name,
							}))
						end)
					end))
				end)
				:andThen(function(data)
					self._cache = self:_createCache(data)
					return data
				end)
		end, RETRY_COUNT):catch(function()
			return nil
		end)
	else
		return Promise.resolve(self._cache.data)
	end
end

return AllTimeLeaderboard

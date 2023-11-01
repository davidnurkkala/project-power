local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LeaderboardQueuer = require(ServerScriptService.Server.Singletons.LeaderboardQueuer)
local ProductService = require(ServerScriptService.Server.Services.ProductService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local TauntStore = require(ReplicatedStorage.Shared.Singletons.TauntStore)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local CACHE_TIME = 60 * 5
local RETRY_COUNT = 8

type Promise<T> = any

type Cache = {
	timeCreated: number,
	data: any,
}

local WeaponLeaderboard = {}
WeaponLeaderboard.__index = WeaponLeaderboard

function WeaponLeaderboard.new(weaponId: string)
	assert(WeaponDefinitions[weaponId], `Invalid weapon id {weaponId}`)

	local self = setmetatable({}, WeaponLeaderboard)

	self._weaponId = weaponId
	self._dataStore = DataStoreService:GetOrderedDataStore("WeaponLeaderboard", weaponId)
	self._cache = nil

	return self
end

function WeaponLeaderboard:_createCache(data): Cache
	return {
		timeCreated = tick(),
		data = data,
	}
end

function WeaponLeaderboard:_hasCacheExpired(cache: Cache): boolean
	return tick() - cache.timeCreated > CACHE_TIME
end

function WeaponLeaderboard:onGameClosed()
	if self._savePromise then
		self._savePromise:cancel()
		return self._savePromise
	end

	return
end

function WeaponLeaderboard:get(): Promise<any?>
	if (self._cache == nil) or (self:_hasCacheExpired(self._cache)) then
		self._cache = nil

		return Promise.retry(function()
			return LeaderboardQueuer:request()
				:andThen(function()
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

function WeaponLeaderboard:addScore(player, score)
	if not self._scores then
		local scores = {
			tauntsByPlayer = {},
			scoresByPlayer = {},
		}

		self._savePromise = Promise.delay(30):finally(function()
			self._savePromise = nil
			self._scores = nil

			for taunter, taunt in scores.tauntsByPlayer do
				TauntStore:set(taunter, taunt)
			end

			for scorer, finalScore in scores.scoresByPlayer do
				Promise.retry(function()
					return Promise.new(function()
						self._dataStore:UpdateAsync(scorer.UserId, function(previousScore: number?)
							return (previousScore or 0) + finalScore
						end)
					end)
				end, RETRY_COUNT):catch(function() end)
			end
		end)

		self._scores = scores
	end

	self._scores.tauntsByPlayer[player] = ProductService:getEquipped(player, "taunt")
	self._scores.scoresByPlayer[player] = (self._scores.scoresByPlayer[player] or 0) + score
end

function WeaponLeaderboard:destroy() end

return WeaponLeaderboard

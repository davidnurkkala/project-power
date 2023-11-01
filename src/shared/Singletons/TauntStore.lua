local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductDefinitions = require(ReplicatedStorage.Shared.Data.ProductDefinitions)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

local RETRY_COUNT = 8
local DEFAULT_TAUNT = pickRandom(Sift.Dictionary.keys(ProductDefinitions.taunt.products))

type Promise<T> = any

local TauntStore = {
	_store = nil,
	_tauntsByUserId = {},
}

function TauntStore:_getStore()
	if not self._store then self._store = DataStoreService:GetDataStore("EquippedTaunts") end
	return self._store
end

function TauntStore:get(userIdRaw: number | string): Promise<string>
	local userId = tostring(userIdRaw)

	if self._tauntsByUserId[userId] then
		return Promise.resolve(self._tauntsByUserId[userId])
	else
		return Promise.retry(function()
			return Promise.new(function(resolve)
				local taunt = self:_getStore():GetAsync(userId)
				if taunt == nil then
					resolve(DEFAULT_TAUNT)
				else
					self._tauntsByUserId[userId] = taunt
					resolve(taunt)
				end
			end)
		end, RETRY_COUNT):catch(function()
			return DEFAULT_TAUNT
		end)
	end
end

function TauntStore:set(player, taunt)
	local userId = tostring(player.UserId)
	if not taunt then return end
	if taunt == self._tauntsByUserId[userId] then return end

	self._tauntsByUserId[userId] = taunt

	return Promise.retry(function()
		return Promise.new(function(resolve)
			self:_getStore():SetAsync(userId, taunt)
			resolve(true)
		end)
	end, RETRY_COUNT):catch(function()
		return false
	end)
end

return TauntStore

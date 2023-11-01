local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Loader = require(ReplicatedStorage.Shared.Loader)
local ProductService = require(ServerScriptService.Server.Services.ProductService)
local Sift = require(ReplicatedStorage.Packages.Sift)
local StarterPackHelper = require(ServerScriptService.Server.Util.StarterPackHelper)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local StarterPackService = {}
StarterPackService.className = "StarterPackService"
StarterPackService.priority = 0

local EXPIRE_TIME = 24 * 60 * 60

local DATA_KEY = "StarterPackData"
DataStore2.Combine(Configuration.DataStoreKey, DATA_KEY)

local DEFAULT_DATA = {
	expireTimestamp = nil,
}

local function getNewExpireTimestamp()
	local now = DateTime.now().UnixTimestamp
	local expire = now + EXPIRE_TIME
	return DateTime.fromUnixTimestamp(expire):ToIsoDate()
end

function StarterPackService:init() end

function StarterPackService:start()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "StarterPackService")
	self._expireTimestamp = self._comm:CreateProperty("ExpireTimestamp", nil)
	self._comm:BindFunction("Buy", function(player)
		return self:purchase(player):await()
	end)

	Players.PlayerAdded:Connect(function(player)
		local store = DataStore2(DATA_KEY, player)
		local data = store:Get(DEFAULT_DATA)

		if not data.expireTimestamp then
			data.expireTimestamp = getNewExpireTimestamp()
			store:Set(data)
		end
		if StarterPackHelper.isOwned(player) then return end

		local expireUnix = DateTime.fromIsoDate(data.expireTimestamp).UnixTimestamp
		local nowUnix = DateTime.now().UnixTimestamp
		if nowUnix >= expireUnix then return end

		self._expireTimestamp:SetFor(player, data.expireTimestamp)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._expireTimestamp:ClearFor(player)
	end)
end

function StarterPackService:purchase(player)
	local timestamp = self._expireTimestamp:GetFor(player)
	if not timestamp then return end

	return ProductService:purchaseProduct(player, StarterPackHelper.Product)
		:andThen(function()
			if StarterPackHelper.isOwned(player) then
				-- give sufficient power to unlock the first ten weapons
				-- keep in mind that fist is the first in order, so we add 1
				local amount = Sift.Dictionary.values(Sift.Dictionary.filter(WeaponDefinitions, function(def)
					return def.order == 11
				end))[1].price

				CurrencyService:addCurrency(player, "power", amount)

				-- give the exclusive kill image
				ProductService:giveProduct(player, { kind = "killImage", id = "PovertyDetected" })

				-- clear the expire timestamp
				self._expireTimestamp:ClearFor(player)
			end
		end)
		:catch(function(err)
			warn(`Something went wrong with player {player} buying the starter pack:\n{err}`)
		end)
end

return Loader:registerSingleton(StarterPackService)

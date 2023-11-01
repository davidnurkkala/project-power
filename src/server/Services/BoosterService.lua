local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Loader = require(ReplicatedStorage.Shared.Loader)

type UnixTimestamp = number
type Data = {
	expireTimestamp: UnixTimestamp,
}

local DATA_KEY = "Booster"
local DEFAULT_DATA: Data = {
	expireTimestamp = 0,
}

DataStore2.Combine(Configuration.DataStoreKey, DATA_KEY)

local BoosterService = {}
BoosterService.className = "BoosterService"
BoosterService.priority = 0

function BoosterService:init()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "BoosterService")
	self._expireTimestamp = self._comm:CreateProperty("ExpireTimestamp", nil)

	local function onPlayerAdded(player)
		local store = DataStore2(DATA_KEY, player)
		store:GetAsync(DEFAULT_DATA):andThen(function(data: Data)
			self._expireTimestamp:SetFor(player, data.expireTimestamp)
		end)
		store:OnUpdate(function(data: Data)
			self._expireTimestamp:SetFor(player, data.expireTimestamp)
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function BoosterService:boostPlayer(player, minutes)
	local store = DataStore2(DATA_KEY, player)
	store:GetAsync(DEFAULT_DATA):andThen(function(data: Data)
		local now = DateTime.now().UnixTimestamp
		if data.expireTimestamp < now then data.expireTimestamp = now end
		data.expireTimestamp += (minutes * 60)

		store:Set(data)
	end)
end

function BoosterService:isActive(player)
	local store = DataStore2(DATA_KEY, player)
	return store
		:GetAsync(DEFAULT_DATA)
		:andThen(function(data: Data)
			return data.expireTimestamp > DateTime.now().UnixTimestamp
		end)
		:now()
		:catch(function()
			return false
		end)
		:expect()
end

function BoosterService:start() end

return Loader:registerSingleton(BoosterService)

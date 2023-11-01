local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)

local DataSafetyService = {}
DataSafetyService.className = "DataSafetyService"
DataSafetyService.priority = 0

function DataSafetyService:init() end

function DataSafetyService:start()
	while true do
		task.wait(90)

		Promise.allSettled(Sift.Array.map(Players:GetPlayers(), function(player)
			local store = DataStore2(Configuration.DataStoreKey, player)
			return store:SaveAsync()
		end)):await()
	end
end

return Loader:registerSingleton(DataSafetyService)

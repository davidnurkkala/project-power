local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local PowerUpDefinitions = require(ReplicatedStorage.Shared.Data.PowerUpDefinitions)

local PowerUpService = {}
PowerUpService.className = "PowerUpService"
PowerUpService.priority = 0

function PowerUpService:init() end

function PowerUpService:start()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "PowerUpService")

	self.powerUpActivated = self._comm:CreateSignal("PowerUpActivated")
end

function PowerUpService:createPowerUp(definitionId, rootPart, position)
	local definition = PowerUpDefinitions[definitionId]
	local source = ServerScriptService.Server.Classes.PowerUps[`{definitionId}Server`]
	local class = require(source)
	return class.new(definition, rootPart, position)
end

return Loader:registerSingleton(PowerUpService)

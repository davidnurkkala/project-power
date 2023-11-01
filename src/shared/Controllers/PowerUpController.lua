local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local PowerUpDefinitions = require(ReplicatedStorage.Shared.Data.PowerUpDefinitions)

local PowerUpController = {}
PowerUpController.className = "PowerUpController"
PowerUpController.priority = 0

function PowerUpController:init() end

function PowerUpController:start()
	self._activePowerUps = {}

	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "PowerUpService")

	self.powerUpActivated = self._comm:GetSignal("PowerUpActivated")
	self.powerUpActivated:Connect(function(...)
		self:_onPowerUpActivated(...)
	end)
end

function PowerUpController:_onPowerUpActivated(definitionId)
	local definition = PowerUpDefinitions[definitionId]
	local source = ReplicatedStorage.Shared.PowerUps[`{definitionId}Client`]
	local callback = require(source)
	callback(definition)
end

return Loader:registerSingleton(PowerUpController)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local ProgressionController = {}
ProgressionController.className = "ProgressionController"
ProgressionController.priority = 0

ProgressionController.weaponUnlocked = Signal.new() :: Signal.Signal<WeaponDefinitions.WeaponDefinition>

function ProgressionController:init() end

function ProgressionController:start()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "ProgressionService")

	self._comm:GetSignal("WeaponUnlocked"):Connect(function(weaponId)
		local weaponDef = WeaponDefinitions[weaponId]
		if not weaponDef then
			warn("Weapon with id", weaponId, "does not exist")
			return
		end
		self.weaponUnlocked:Fire(weaponDef)
	end)
end

return Loader:registerSingleton(ProgressionController)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)

local KillController = {}
KillController.className = "KillController"
KillController.priority = 0

KillController.playerKilled = Signal.new() :: Signal.Signal<Player, Player>

function KillController:init() end

function KillController:start()
	self._damageComm = Comm.ClientComm.new(ReplicatedStorage, true, "DamageService")
	self._playerKilled = self._damageComm:GetSignal("PlayerKilled")

	self._playerKilled:Connect(function(killer, victim)
		KillController.playerKilled:Fire(killer, victim)
	end)
end

return Loader:registerSingleton(KillController)

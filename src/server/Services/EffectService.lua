local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Loader = require(ReplicatedStorage.Shared.Loader)

local DENY_LIST = {
	setRootCFrame = true,
	setMotorTransform = true,
}

local EffectService = {}
EffectService.className = "EffectService"
EffectService.priority = 0

function EffectService:init() end

function EffectService:start()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "EffectService")

	self._effectRequested = self._comm:CreateSignal("EffectRequested")

	self._effectRequested:Connect(function(player, effectName, effectArgs)
		if not effectName then return end
		if DENY_LIST[effectName] then return end

		if string.find(effectName, "Server") then
			EffectUtil[effectName](player, effectArgs)
		else
			self._effectRequested:FireExcept(player, effectName, effectArgs)
		end
	end)
end

function EffectService:effect(effectName, effectArgs)
	self._effectRequested:FireAll(effectName, effectArgs)
end

function EffectService:effectPlayer(player, effectName, effectArgs)
	self._effectRequested:Fire(player, effectName, effectArgs)
end

return Loader:registerSingleton(EffectService)

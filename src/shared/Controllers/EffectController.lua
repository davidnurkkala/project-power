local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Loader = require(ReplicatedStorage.Shared.Loader)

local EffectController = {}
EffectController.className = "EffectController"
EffectController.priority = 0

function EffectController:init() end

function EffectController:start()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "EffectService")

	self._effectRequested = self._comm:GetSignal("EffectRequested")

	self._effectRequested:Connect(function(effectName, effectArgs)
		EffectUtil[effectName](effectArgs)
	end)

	EffectUtil.replicationRequested:Connect(function(...)
		self:replicate(...)
	end)
end

function EffectController:replicate(name, ...)
	self._effectRequested:Fire(name, ...)
end

function EffectController:cancel(...)
	for _, guid in { ... } do
		self:replicate(EffectUtil.cancel({ guid = guid }))
	end
end

function EffectController:getRapidReplicator()
	local last = 0
	return function(...)
		local now = tick()
		if (now - last) < EffectUtil.RAPID_REPLICATION_TIME then return end
		last = now

		self:replicate(...)
	end
end

return Loader:registerSingleton(EffectController)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Damage = require(ReplicatedStorage.Shared.Classes.Damage)

local ComboTracker = {}
ComboTracker.__index = ComboTracker

function ComboTracker.new(comboTime: number)
	local self = setmetatable({
		_targets = {} :: { [Damage.DamageTarget]: number },
		_comboTime = comboTime,
	}, ComboTracker)
	return self
end

function ComboTracker:track(target: Damage.DamageTarget)
	if not self._targets[target] then self._targets[target] = 0 end

	self._targets[target] += 1

	task.delay(self._comboTime, function()
		self._targets[target] -= 1

		if self._targets[target] == 0 then self._targets[target] = nil end
	end)

	return self._targets[target]
end

function ComboTracker:get(target: Damage.DamageTarget)
	return self._targets[target] or 0
end

function ComboTracker:destroy() end

return ComboTracker

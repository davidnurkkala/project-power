local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Damage = require(ReplicatedStorage.Shared.Classes.Damage)
local Trove = require(ReplicatedStorage.Packages.Trove)

local WIGGLE = 0.025

local HitLimiter = {}
HitLimiter.__index = HitLimiter

function HitLimiter.new(duration: number, count: number?)
	local self = setmetatable({
		_targets = {} :: { [Damage.DamageTarget]: number },
		_duration = duration,
		_count = count or 1,
		_trove = Trove.new(),
	}, HitLimiter)
	return self
end

function HitLimiter:setCount(count: number)
	self._count = count
end

function HitLimiter:reset()
	self._targets = {}
	self._trove:Clean()
end

function HitLimiter:limitTarget(target: Damage.DamageTarget): boolean
	if (self._targets[target] or 0) >= self._count then
		return true
	else
		self._targets[target] = (self._targets[target] or 0) + 1
		self._trove:Add(task.delay(self._duration - WIGGLE, function()
			self._targets[target] -= 1
			if self._targets[target] == 0 then self._targets[target] = nil end
		end))
		return false
	end
end

function HitLimiter:destroy() end

return HitLimiter

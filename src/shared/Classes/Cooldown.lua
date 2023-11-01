local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Updater = require(ReplicatedStorage.Shared.Classes.Updater)

local CooldownUpdater = Updater.new()

local Cooldown = {}
Cooldown.__index = Cooldown

function Cooldown.new(baseDuration)
	local self = setmetatable({
		_baseDuration = baseDuration,
		_duration = baseDuration,
		_current = 0,
		_ready = true,
		_speed = 1,

		used = Signal.new(),
		completed = Signal.new(),
		chargesChanged = Signal.new(),
	}, Cooldown)
	return self
end

function Cooldown:setSpeed(speed)
	self._speed = speed
end

function Cooldown:getSpeed()
	return self._speed
end

function Cooldown:adjustSpeed(amount)
	self:setSpeed(self:getSpeed() + amount)
end

function Cooldown:hasMultipleCharges()
	return false
end

function Cooldown:getCharges()
	return 1
end

function Cooldown:update(dt)
	self._current -= self._speed * dt
	if self._current <= 0 then
		self._current = 0
		self._ready = true
		CooldownUpdater:remove(self)
		self.completed:Fire()
	end
end

function Cooldown:isReady()
	return self._ready
end

function Cooldown:getPercentage()
	-- it's bad if this happens but we should still recover gracefully
	if self._duration == 0 then return 1 end

	return 1 - (self._current / self._duration)
end

function Cooldown:getDuration()
	return self._duration
end

function Cooldown:use(duration: number?)
	duration = duration or self._baseDuration

	if duration == 0 then
		if self._ready then return end

		self._duration = self._baseDuration
		self._current = 0

		self.used:Fire(0)

		self:update(0)
	else
		if self._ready then
			self._duration = duration
			self._current = self._duration
			self._ready = false

			self.used:Fire(self._duration)

			CooldownUpdater:add(self)
		else
			self._duration = duration
			self._current = self._duration
		end
	end
end

function Cooldown:reset()
	self:use(0)
end

function Cooldown:reduceBy(amount)
	self._current -= amount
	self:update(0)
end

function Cooldown:destroy()
	CooldownUpdater:remove(self)
end

return Cooldown

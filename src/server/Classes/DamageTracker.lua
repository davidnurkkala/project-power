local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local LIFETIME = 30

local DamageTracker = {}
DamageTracker.__index = DamageTracker

function DamageTracker.new(target: Humanoid)
	local self = setmetatable({
		target = target,
		destroyed = Signal.new(),

		_blobsBySource = {},
	}, DamageTracker)

	self:_expire()

	return self
end

function DamageTracker:trackDamage(source: Player, amount: number)
	local blob = self._blobsBySource[source]

	if not blob then
		blob = {
			amount = 0,
			timestamp = 0,
		}
		self._blobsBySource[source] = blob
	end

	blob.amount += amount
	blob.timestamp = tick()
end

function DamageTracker:getMostRecent()
	local timestamp = 0
	local bestSource = nil
	for source, blob in self._blobsBySource do
		if blob.timestamp > timestamp then
			timestamp = blob.timestamp
			bestSource = source
		end
	end
	return bestSource
end

function DamageTracker:getMostDamage()
	local amount = 0
	local bestSource = nil
	for source, blob in self._blobsBySource do
		if blob.amount > amount then
			amount = blob.amount
			bestSource = source
		end
	end
	return bestSource
end

function DamageTracker:_expire()
	if self._expirePromise then
		self._expirePromise:cancel()
		self._expirePromise = nil
	end

	self._expirePromise = Promise.delay(LIFETIME):andThenCall(self.destroy, self)
end

function DamageTracker:destroy()
	self.destroyed:Fire()
end

return DamageTracker

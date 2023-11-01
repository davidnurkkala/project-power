local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CooldownCharges = {}
CooldownCharges.__index = CooldownCharges

function CooldownCharges.new(chargeCount, chargeDuration, useDuration)
	local self = setmetatable({
		_charges = chargeCount,
		_chargesMax = chargeCount,
		_chargeCooldown = Cooldown.new(chargeDuration),
		_useCooldown = Cooldown.new(useDuration),
		_recharging = false,

		completed = Signal.new(),
		used = Signal.new(),
		chargesChanged = Signal.new(),
	}, CooldownCharges)

	self._useCooldown.completed:Connect(function()
		if self._charges >= 1 then self.completed:Fire() end
	end)

	return self
end

function CooldownCharges:setSpeed(speed)
	self._useCooldown:setSpeed(speed)
	self._chargeCooldown:setSpeed(speed)
end

function CooldownCharges:getSpeed()
	return self._useCooldown:getSpeed()
end

function CooldownCharges:adjustSpeed(amount)
	self:setSpeed(self:getSpeed() + amount)
end

function CooldownCharges:hasMultipleCharges()
	return self._chargesMax > 1
end

function CooldownCharges:getCharges()
	return self._charges
end

function CooldownCharges:getMaxCharges()
	return self._chargesMax
end

function CooldownCharges:setCharges(charges)
	if charges == self._charges then return end

	self._charges = charges
	self.chargesChanged:Fire(charges)
end

function CooldownCharges:setMaxCharges(maxCharges)
	if maxCharges == self._chargesMax then return end
	if maxCharges < 1 then return end
	if maxCharges ~= math.floor(maxCharges) then return end

	self._chargesMax = maxCharges
	self._charges = math.min(self._charges, maxCharges)
	self.chargesChanged:Fire(self._charges)

	if self._charges < self._chargesMax then self:_recharge() end
end

function CooldownCharges:isReady()
	if self._charges == 0 then
		return false
	else
		return self._useCooldown:isReady()
	end
end

function CooldownCharges:getPercentage()
	if self._charges == 0 then
		return self._chargeCooldown:getPercentage()
	else
		return self._useCooldown:getPercentage()
	end
end

function CooldownCharges:_recharge()
	if self._recharging then return end

	self._recharging = true
	task.spawn(function()
		while self._charges < self._chargesMax do
			self._chargeCooldown:use()
			self._chargeCooldown.completed:Wait()
			self:setCharges(self._charges + 1)
			if self._charges == 1 then self.completed:Fire() end
		end
		self._recharging = false
	end)
end

function CooldownCharges:getDuration()
	if self._charges == 0 then
		return self._chargeCooldown:getDuration()
	else
		return self._useCooldown:getDuration()
	end
end

function CooldownCharges:recooldown()
	self._chargeCooldown:use()
end

function CooldownCharges:use(override)
	self:setCharges(self._charges - 1)
	self:_recharge()

	self._useCooldown:use(override)

	self.used:Fire(self:getDuration())
end

function CooldownCharges:reduceBy(amount)
	self._useCooldown:reduceBy(amount)
	self._chargeCooldown:reduceBy(amount)
end

function CooldownCharges:reset()
	self._useCooldown:reset()
	self._chargeCooldown:reset()
	self:setCharges(self._chargesMax)
end

function CooldownCharges:destroy()
	self._useCooldown:destroy()
	self._chargeCooldown:destroy()
end

return CooldownCharges

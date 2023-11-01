local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TryNow = require(ReplicatedStorage.Shared.Util.TryNow)
local BotTarget = {}
BotTarget.__index = BotTarget

function BotTarget.new(human: Humanoid)
	local self = setmetatable({
		_human = human,
	}, BotTarget)

	return self
end

function BotTarget:getPosition()
	return TryNow(function()
		return self._human.Parent:GetPivot().Position
	end, Vector3.new(0, 0, 0))
end

function BotTarget:getHeadPosition()
	return TryNow(function()
		return self._human.Parent.Head.Position
	end, self:getPosition())
end

function BotTarget:isAlive()
	return TryNow(function()
		return self._human.Health > 0
	end, false)
end

function BotTarget:isGrounded()
	return TryNow(function()
		return self._human.FloorMaterial ~= Enum.Material.Air
	end, false)
end

function BotTarget:getDistance(point: Vector3)
	return (point - self:getPosition()).Magnitude
end

function BotTarget:isInSphere(point: Vector3, range: number)
	local delta = point - self:getPosition()
	local distanceSq = delta.X ^ 2 + delta.Y ^ 2 + delta.Z ^ 2
	return distanceSq <= (range ^ 2)
end

function BotTarget:isInRange(point: Vector3, range: number)
	local delta = point - self:getPosition()
	local distanceSq = delta.X ^ 2 + delta.Z ^ 2
	return distanceSq <= (range ^ 2) and (math.abs(delta.Y) < range)
end

function BotTarget:destroy() end

return BotTarget

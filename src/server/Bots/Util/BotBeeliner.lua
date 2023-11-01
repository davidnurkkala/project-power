local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BattleService = require(ServerScriptService.Server.Services.BattleService)
local Sift = require(ReplicatedStorage.Packages.Sift)

local STUCK_EPSILON = 0.1
local STUCK_TIME = 1

local BotBeeliner = {}
BotBeeliner.__index = BotBeeliner

function BotBeeliner.new(visionParts: { BasePart }, target: any)
	local self = setmetatable({
		_visionParts = visionParts,
		_target = target,

		_timeStuck = 0,
		_lastPosition = nil,
	}, BotBeeliner)

	return self
end

function BotBeeliner:try(dt: number): boolean
	if not self._target:isGrounded() then return false end

	local foundObstacle = Sift.Array.some(self._visionParts, function(part)
		local origin = part.Position
		local direction = self._target:getHeadPosition() - origin

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { BattleService:getArena() }
		params.FilterType = Enum.RaycastFilterType.Include

		local result = workspace:Raycast(origin, direction, params)

		return result ~= nil
	end)

	if foundObstacle then return false end

	local currentPosition = self._visionParts[1].Position
	if self._lastPosition then
		local wasStuck = currentPosition:FuzzyEq(self._lastPosition, STUCK_EPSILON)
		if wasStuck then
			self._timeStuck += dt
			if self._timeStuck > STUCK_TIME then
				self._timeStuck = 0
				return false
			end
		else
			self._timeStuck = 0
		end
	end
	self._lastPosition = currentPosition

	return true
end

function BotBeeliner:destroy() end

return BotBeeliner

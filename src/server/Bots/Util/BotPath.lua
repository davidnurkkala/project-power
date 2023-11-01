local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local REACHED_RADIUS_SQ = 4 ^ 2

local BotPath = {}
BotPath.__index = BotPath

function BotPath.new(args: {
	params: any,
	getPosition: () -> Vector3,
	getFinish: () -> Vector3,
	getIsValid: (any) -> boolean,
})
	local self = setmetatable({
		_path = PathfindingService:CreatePath(args.params),
		_calculating = false,
		_waypoints = {},
		_waypointIndex = -1,

		_getPosition = args.getPosition,
		_getFinish = args.getFinish,
		_getIsValid = args.getIsValid,
	}, BotPath)

	self:_calculate()

	return self
end

function BotPath:_calculate()
	if self._calculating then return end
	self._calculating = true

	Promise.try(function()
		self._path:ComputeAsync(self._getPosition(), self._getFinish())
	end):andThen(function()
		self._calculating = false
		self:_clear()

		if self._path.Status == Enum.PathStatus.NoPath then return end

		self._waypoints = table.clone(self._path:GetWaypoints())

		if #self._waypoints == 0 then return end

		self._waypointIndex = 1
	end)
end

function BotPath:_clear()
	self._waypoints = {}
	self._waypointIndex = -1
end

function BotPath:getStatus()
	return self._path.Status
end

function BotPath:hasFailed()
	if self._calculating then return false end

	return self._path.Status == Enum.PathStatus.NoPath
end

function BotPath:getNext(): PathWaypoint?
	if not self:_getIsValid() then self:_calculate() end

	return self._waypoints[self._waypointIndex]
end

function BotPath:getLast(): PathWaypoint?
	return self._waypoints[#self._waypoints]
end

function BotPath:checkReached(): boolean
	local waypoint = self:getNext()
	if not waypoint then return false end

	local here = self._getPosition()
	local delta = waypoint.Position - here
	local distanceSq = delta.X ^ 2 + delta.Z ^ 2

	if distanceSq <= REACHED_RADIUS_SQ then return self:increment() end

	return false
end

function BotPath:increment(): boolean
	self._waypointIndex += 1
	return self._waypointIndex > #self._waypoints
end

function BotPath:destroy() end

return BotPath

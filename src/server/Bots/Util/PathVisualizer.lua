local PathVisualizer = {}
PathVisualizer.__index = PathVisualizer

function PathVisualizer.new()
	local self = setmetatable({}, PathVisualizer)
	return self
end

function PathVisualizer:_clear()
	if self._model then
		self._model:Destroy()
		self._model = nil
	end
end

function PathVisualizer:onReached(index)
	if not self._model then return end
	local part = self._model:FindFirstChild(tostring(index))
	if not part then return end
	part:Destroy()
end

function PathVisualizer:visualize(waypoints)
	self:_clear()

	self._model = Instance.new("Model")
	self._model.Name = "VisualizedPath"

	for index, waypoint: PathWaypoint in waypoints do
		local part = Instance.new("Part")
		part.Name = tostring(index)
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Anchored = true
		if waypoint.Action == Enum.PathWaypointAction.Walk then
			part.Color = Color3.new(1, 0, 1)
		else
			part.Color = Color3.new(1, 1, 0)
		end
		part.Size = Vector3.new(0.25, 0.25, 0.25)
		part.Position = waypoint.Position
		part.Parent = self._model
	end

	self._model.Parent = workspace
end

function PathVisualizer:destroy()
	self:_clear()
end

return PathVisualizer

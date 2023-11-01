return function(origin, direction, duration)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Color = Color3.new(1, 0, 0)
	part.Size = Vector3.new(0.25, 0.25, direction.Magnitude)
	part.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -direction.Magnitude / 2)
	part.Parent = workspace
	task.delay(duration, part.Destroy, part)
	return part
end

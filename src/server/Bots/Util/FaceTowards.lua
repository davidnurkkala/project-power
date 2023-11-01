return function(root: BasePart, point: Vector3)
	local delta = (point - root.Position) * Vector3.new(1, 0, 1)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + delta)
end

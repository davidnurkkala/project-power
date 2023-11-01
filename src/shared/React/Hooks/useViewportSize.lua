local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useCamera = require(ReplicatedStorage.Shared.React.Hooks.useCamera)

return function()
	local camera = useCamera()
	local viewportSize, setViewportSize = React.useState(camera and camera.ViewportSize or Vector2.new(0, 0))

	React.useEffect(function()
		if not camera then return end

		setViewportSize(camera.ViewportSize)
		local viewportSizeChanged = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			setViewportSize(camera.ViewportSize)
		end)

		return function()
			viewportSizeChanged:Disconnect()
		end
	end, { camera })

	return viewportSize
end

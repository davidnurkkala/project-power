local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
return function()
	local camera, setCamera = React.useState(game.Workspace.CurrentCamera)

	React.useEffect(function()
		local cameraChanged = game.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			setCamera(game.Workspace.CurrentCamera)
		end)

		return function()
			cameraChanged:Disconnect()
		end
	end, {})

	return camera
end

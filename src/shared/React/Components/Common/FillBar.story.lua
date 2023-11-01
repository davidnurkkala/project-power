local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FillBar = require(ReplicatedStorage.Shared.React.Components.Common.FillBar)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local controls = {
	maxValue = 100,
	incrementPerSecond = 25,
}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(props)
		local elapsed, setElapsed = React.useState(0)

		React.useEffect(function()
			local connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
				setElapsed(function(prevElapsed)
					return (prevElapsed + (props.controls.incrementPerSecond * dt)) % (props.controls.maxValue + 1)
				end)
			end)

			return function()
				connection:Disconnect()
			end
		end, { props.controls.maxValue, props.controls.incrementPerSecond })

		return React.createElement(FillBar, {
			maxValue = props.controls.maxValue,
			value = elapsed,
		})
	end,
}

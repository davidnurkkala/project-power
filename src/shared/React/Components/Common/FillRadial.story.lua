local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FillRadial = require(ReplicatedStorage.Shared.React.Components.Common.FillRadial)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local controls = {
	maxValue = 5,
	incrementPerSecond = 1,
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

		return React.createElement(FillRadial, {
			maxValue = props.controls.maxValue,
			value = elapsed,
		})
	end,
}

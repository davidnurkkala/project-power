local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudButtons = require(ReplicatedStorage.Shared.React.Components.HUD.HudButtons.HudButtons)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Signal = require(ReplicatedStorage.Packages.Signal)

local controls = {
	shopNotification = true,
	extrasNotification = true,
}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(props)
		local notificationAdded = React.useRef(Signal.new()).current
		React.useEffect(function()
			if props.controls.shopNotification then Promise.delay(0.25):andThen(function()
				notificationAdded:Fire("Shop")
			end) end
			if props.controls.extrasNotification then Promise.delay(0.25):andThen(function()
				notificationAdded:Fire("Extras")
			end) end
			return function()
				return
			end
		end, { props.controls.shopNotification, props.controls.extrasNotification })

		return React.createElement(HudButtons, {
			buttonSelected = function(buttonName: string?)
				print("selected", buttonName)
			end,
			notificationAdded = notificationAdded,
		})
	end,
}

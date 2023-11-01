local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyLabel = require(ReplicatedStorage.Shared.React.Components.HUD.CurrencyDisplay.CurrencyLabel)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local controls = {
	amount = 0,
	currency = "power",
}

type Props = {
	controls: typeof(controls),
}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(props: Props)
		return React.createElement(CurrencyLabel, {
			amount = props.controls.amount,
			currency = props.controls.currency,
			position = UDim2.new(0.5, 0, 0.5, 0),
			size = UDim2.fromScale(1, 1),
			anchorPoint = Vector2.new(0, 0),
		})
	end,
}

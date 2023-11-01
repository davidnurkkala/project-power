local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local WeaponStandDisplay = require(ReplicatedStorage.Shared.React.Components.WeaponStand.WeaponStandDisplay)

local controls = {
	owned = false,
}

type Props = {
	controls: typeof(controls),
}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(props: Props)
		return React.createElement(WeaponStandDisplay, {
			weaponDefinition = WeaponDefinitions.Fist,
			owned = props.controls.owned,
		})
	end,
}

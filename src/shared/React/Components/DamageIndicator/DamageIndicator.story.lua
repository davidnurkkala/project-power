local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageIndicator = require(ReplicatedStorage.Shared.React.Components.DamageIndicator.DamageIndicator)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local _IndicatorIcon = require(ReplicatedStorage.Shared.React.Components.DamageIndicator.IndicatorIcon)

local controls = {
	damage = 100,
}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(props)
		local part = Instance.new("Part")
		part.Archivable = false
		part.Anchored = true
		part.CFrame = CFrame.new(0, 20, 0)
		part.Size = Vector3.new(1, 1, 1)
		part.Parent = workspace

		React.useEffect(function()
			return function()
				part:Destroy()
			end
		end, {
			part,
		})

		local damage = if props.controls.damage == "" then controls.damage else tonumber(props.controls.damage)

		return React.createElement(DamageIndicator, {
			damage = damage,
			lifetime = 0.5,
			target = part,
			unmount = function()
				print("unmount component")
			end,
		})
	end,
}

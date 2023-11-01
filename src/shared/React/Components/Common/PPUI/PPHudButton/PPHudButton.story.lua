local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PPHudButton = require(ReplicatedStorage.Shared.React.Components.Common.PPUI.PPHudButton.PPHudButton)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local controls = {}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(_props)
		local children = {}

		return React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			React.createElement(PPHudButton, {
				size = UDim2.new(0, 128, 0, 128),
				position = UDim2.new(0.25, 0, 0.25, 0),
			}, children),
		})
	end,
}

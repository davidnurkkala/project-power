local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PPFrame = require(ReplicatedStorage.Shared.React.Components.Common.PPUI.PPFrame.PPFrame)
local Popup = require(ReplicatedStorage.Shared.React.Components.Common.Popup)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Signal = require(ReplicatedStorage.Packages.Signal)

local controls = {
	text = "Menu",
}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(props)
		local signal = React.useRef(Signal.new()).current

		local children = {}
		return React.createElement(Popup, {
			anchorPoint = Vector2.new(0, 1),
			position = UDim2.new(0.25, 0, 0, 0),
			targetPosition = UDim2.new(0.25, 0, 0.5, 100),
			size = UDim2.new(0.5, 0, 0.5, 0),

			lifeTime = -1,
			tweenInInfo = TweenInfo.new(0.75, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			tweenOutInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			closeForced = signal,
		}, {
			content = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
			}, {
				React.createElement(PPFrame, {
					headerText = tostring(props.controls.text),

					size = UDim2.fromScale(1, 1),
					position = UDim2.new(0, 0, 0, 0),
					onClosed = function()
						signal:Fire()
					end,
				}, children),
			}),
		})
	end,
}

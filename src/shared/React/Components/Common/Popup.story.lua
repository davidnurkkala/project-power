local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Popup = require(ReplicatedStorage.Shared.React.Components.Common.Popup)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local controls = {}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(_props)
		local children = {}
		for i = 1, 10 do
			children["Popup" .. i] = React.createElement(Popup, {
				anchorPoint = Vector2.new(0, 1),
				size = UDim2.new(0, 100, 0, 100),
				position = UDim2.new(0, i * 110, 0, 0),
				targetPosition = UDim2.new(0, i * 110, 0, 200),

				lifeTime = 1,
				tweenInInfo = TweenInfo.new(0.5 + math.random() * 1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
				tweenOutInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				onTweenIn = function()
					print("tweened in", i)
				end,
				onTweenOut = function()
					print("tweened out", i)
				end,
			})
		end
		return React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		}, children)
	end,
}

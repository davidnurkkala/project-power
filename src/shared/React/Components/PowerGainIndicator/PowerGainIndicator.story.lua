local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PowerGainIndicator = require(ReplicatedStorage.Shared.React.Components.PowerGainIndicator.PowerGainIndicator)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

return function(target)
	local powerAdded = Signal.new()

	local element = React.createElement(React.Fragment, nil, {
		screen = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(640, 360),
			Position = UDim2.fromOffset(0, 0),
			LayoutOrder = 1,
		}, {
			Stroke = React.createElement("UIStroke", {
				Thickness = 2,
			}),

			Element = React.createElement(PowerGainIndicator, {
				PowerAdded = powerAdded,
			}),
		}),

		buttons = React.createElement("Frame", {
			Size = UDim2.fromOffset(60, 30),
			Position = UDim2.fromOffset(20, 380),
		}, {
			layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
			}),

			buttons = React.createElement(
				React.Fragment,
				nil,
				Sift.Dictionary.map({ 1, 5, 10 }, function(value, key)
					return React.createElement("TextButton", {
						Size = UDim2.fromScale(1, 1),
						Text = `+{value}`,
						[React.Event.Activated] = function()
							powerAdded:Fire(value)
						end,
					}),
						`Button{key}`
				end)
			),
		}),
	})

	local root = ReactRoblox.createRoot(target)
	root:render(element)

	return function()
		root:unmount()
	end
end

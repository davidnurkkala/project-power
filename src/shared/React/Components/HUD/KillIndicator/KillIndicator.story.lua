local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KillIndicator = require(ReplicatedStorage.Shared.React.Components.HUD.KillIndicator.KillIndicator)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

return function(target)
	local killAdded = Signal.new()

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

			Element = React.createElement(KillIndicator, {
				KillAdded = killAdded,
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
				Sift.Dictionary.map({ "Bob", "Chuck", "Billy" }, function(value, key)
					return React.createElement("TextButton", {
						Size = UDim2.fromScale(1, 1),
						Text = `{value}`,
						[React.Event.Activated] = function()
							killAdded:Fire(value)
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

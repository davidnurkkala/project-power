local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Shop = require(ReplicatedStorage.Shared.React.Components.Shop.Shop)

return function(target)
	local element = React.createElement(function()
		local screen = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(0, 0),
			LayoutOrder = 1,
		}, {
			Stroke = React.createElement("UIStroke", {
				Thickness = 2,
			}),

			Element = React.createElement(Shop, {
				getIsPurchased = function()
					return Promise.delay(math.random()):andThen(function()
						return math.random(1, 2) == 1
					end)
				end,

				getIsEquipped = function()
					return Promise.delay(math.random()):andThen(function()
						return math.random(1, 2) == 1
					end)
				end,

				setEquipped = function()
					return Promise.delay(math.random())
				end,

				purchase = function()
					return Promise.delay(math.random())
				end,

				exit = function()
					print("exit")
				end,

				visible = true,
			}),
		})

		return screen
	end)

	local root = ReactRoblox.createRoot(target)
	root:render(element)

	return function()
		root:unmount()
	end
end

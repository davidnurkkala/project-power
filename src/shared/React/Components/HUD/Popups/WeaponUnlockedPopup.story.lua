local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Sift = require(ReplicatedStorage.Packages.Sift)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponUnlockedPopup = require(ReplicatedStorage.Shared.React.Components.HUD.Popups.WeaponUnlockedPopup)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

return function(target)
	local element = React.createElement(function()
		local screen = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(640, 360),
			Position = UDim2.fromOffset(0, 0),
			LayoutOrder = 1,
		}, {
			Stroke = React.createElement("UIStroke", {
				Thickness = 2,
			}),

			Element = React.createElement(WeaponUnlockedPopup, {
				weaponDef = pickRandom(Sift.Dictionary.values(WeaponDefinitions)),
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

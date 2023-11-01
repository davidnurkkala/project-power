local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaytimeRewardsPopup = require(ReplicatedStorage.Shared.React.Components.PlaytimeRewards.PlaytimeRewardsPopup)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

return function(target)
	local element = React.createElement(PlaytimeRewardsPopup, {
		count = 3,
		timestamp = DateTime.now().UnixTimestamp,

		finish = function()
			print("DONE")
		end,
	})

	local root = ReactRoblox.createRoot(target)
	root:render(element)

	return function()
		root:unmount()
	end
end

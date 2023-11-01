local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local StarterPack = require(ReplicatedStorage.Shared.React.Components.StarterPack.StarterPack)

return function(target)
	local element = React.createElement(StarterPack, {
		expireTimestamp = DateTime.fromUnixTimestamp(DateTime.now().UnixTimestamp + 500):ToIsoDate(),
	})

	local root = ReactRoblox.createRoot(target)
	root:render(element)

	return function()
		root:unmount()
	end
end

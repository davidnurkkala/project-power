local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

return {
	react = React,
	reactRoblox = ReactRoblox,
	storyRoots = {
		ReplicatedStorage.Shared.React,
	},
}

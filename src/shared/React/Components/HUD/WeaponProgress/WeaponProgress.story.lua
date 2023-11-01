local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Sift = require(ReplicatedStorage.Packages.Sift)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponProgress = require(ReplicatedStorage.Shared.React.Components.HUD.WeaponProgress.WeaponProgress)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

return function(target)
	local root = ReactRoblox.createRoot(target)
	local def = pickRandom(Sift.Dictionary.values(WeaponDefinitions))

	local c = RunService.Heartbeat:Connect(function()
		local clock = tick() % 1

		local element = React.createElement(WeaponProgress, {
			weaponDefinition = def,
			percent = clock,
		})

		root:render(element)
	end)

	return function()
		root:unmount()
		c:Disconnect()
	end
end

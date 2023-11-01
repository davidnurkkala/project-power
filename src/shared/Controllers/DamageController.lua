local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Damage = require(ReplicatedStorage.Shared.Classes.Damage)
local DamageIndicator = require(ReplicatedStorage.Shared.React.Components.DamageIndicator.DamageIndicator)
local Loader = require(ReplicatedStorage.Shared.Loader)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local DamageController = {}
DamageController.className = "DamageController"
DamageController.priority = 0

function DamageController:init() end

function DamageController:start()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "DamageService")

	self._damageDealtRemote = self._comm:GetSignal("DamageDealt")

	self._damageDealtRemote:Connect(function(target: Damage.DamageTarget, damageDealt: number, _didKill: boolean)
		local root = WeaponUtil.getTargetRoot(target)
		if not root then return end

		-- mount damage indicator
		local reactTree = ReactRoblox.createRoot(Instance.new("Folder"))
		reactTree:render(React.createElement(DamageIndicator, {
			damage = damageDealt,
			lifetime = 0.5,
			target = root,
			unmount = function()
				reactTree:unmount()
			end,
		}))

		-- can do something extra for killing
	end)
end

return Loader:registerSingleton(DamageController)

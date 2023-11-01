local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

return function(player, weaponId)
	return Badger.create({
		isComplete = function(_self)
			return WeaponService:getSelectedWeapon(player) == weaponId
		end,
	})
end

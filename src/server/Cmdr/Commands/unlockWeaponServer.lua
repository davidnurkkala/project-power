local ServerScriptService = game:GetService("ServerScriptService")

local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

return function(_context, forPlayer, weaponDefinition)
	WeaponService:unlockWeapon(forPlayer, weaponDefinition.id)

	return ("Unlocked weapon %s for %s"):format(weaponDefinition.name, forPlayer.Name)
end

local ServerScriptService = game:GetService("ServerScriptService")

local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

return function(_, player, def)
	WeaponService:selectWeapon(player, def.id)
end

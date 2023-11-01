-- unlockWeapon.lua - Unlocks a weapon for a player
return {
	Name = "unlockWeapon",
	Aliases = { "additem" },
	Description = "Unlocks a weapon for a player",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "for",
			Description = "The player to unlock the weapon for",
		},
		{
			Type = "weaponDefinition",
			Name = "weapon",
			Description = "The weapon to unlock",
		},
	},
}

return {
	Name = "nukeData",
	Aliases = { "nukeData" },
	Description = "Resets a player's data entirely (use with caution)",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "The player whose data to nuke",
		},
	},
}

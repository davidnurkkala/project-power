-- give.lua: Gives a player an item
return {
	Name = "giveCurrency",
	Aliases = {},
	Description = "Gives an amount of currency to a player",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "to",
			Description = "The player to give currency to",
		},
		{
			Type = "string",
			Name = "currency",
			Description = "The currency to give",
			Default = "power",
		},
		{
			Type = "integer",
			Name = "amount",
			Description = "The amount of currency to give",
			Default = 1,
		},
	},
}

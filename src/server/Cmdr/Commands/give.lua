-- give.lua: Gives a player an item
return {
	Name = "give",
	Aliases = { "additem" },
	Description = "Gives a player an item",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "to",
			Description = "The player to give the item to",
		},
		{
			Type = "string",
			Name = "item",
			Description = "The item to give",
		},
		{
			Type = "integer",
			Name = "amount",
			Description = "The amount of the item to give",
			Default = 1,
		},
	},
}

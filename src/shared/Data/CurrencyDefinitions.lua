export type CurrencyType = "power" | "kills" | "premium" | string

export type CurrencyDefinition = {
	name: string,
	initialValue: number,
	canSpend: boolean, -- denotes a currency whose value is checked rather than spent
	iconId: string?,
	leaderstatTracked: boolean?,
	textColor: Color3?,
}

return {
	power = { -- xp currency adjacent
		name = "Power",
		initialValue = 0,
		canSpend = false,
		iconId = "rbxassetid://13981862812",
		leaderstatTracked = true,
		textColor = Color3.fromRGB(235, 107, 102),
	},
	kills = { -- kill tracker
		name = "Kills",
		initialValue = 0,
		canSpend = false,
		iconId = "rbxassetid://13981862932",
		textColor = Color3.fromRGB(255, 119, 78),
	},
	premium = { -- robux bought currency
		name = "Crystals",
		initialValue = 0,
		canSpend = true,
		iconId = "rbxassetid://14977683461",
		textColor = Color3.fromRGB(123, 240, 255),
	},
} :: { [CurrencyType]: CurrencyDefinition }

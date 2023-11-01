export type PerkType = "increaseMaxHealth" | "fullHeal" | "doubleJump" | "doubleDash"

type LevelUpDefinitions = {
	perksByLevel: { { PerkType } },
	descriptionsByPerk: { [PerkType]: string },
}

local LevelUpDefinitions: LevelUpDefinitions = {
	perksByLevel = {
		[1] = {},
		[2] = { "increaseMaxHealth" },
		[3] = { "increaseMaxHealth" },
		[4] = { "increaseMaxHealth" },
		[5] = { "doubleJump" },
		[6] = { "increaseMaxHealth" },
		[7] = { "increaseMaxHealth" },
		[8] = { "increaseMaxHealth" },
		[9] = { "increaseMaxHealth" },
		[10] = { "doubleDash", "fullHeal" },
	},
	descriptionsByPerk = {
		increaseMaxHealth = "+10 Maximum Health",
		fullHeal = "Full Heal",
		doubleJump = "Double Jump Unlocked",
		doubleDash = "+1 Dash",
	},
}

return LevelUpDefinitions

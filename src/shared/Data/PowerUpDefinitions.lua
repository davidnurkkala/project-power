local definitions = {
	Heal = {
		name = "Heal",
		recoveryAmount = 50,
		duration = 3,
	},
	DamageBoost = {
		name = "Damage Boost",
		duration = 10,
		amount = 0.5,
	},
	MovementBoost = {
		name = "Movement Boost",
		duration = 10,
		speed = 0.5,
		jump = 0.5,
		cooldown = 0.5,
	},
	Invincibility = {
		name = "Invincibility",
		duration = 10,
	},
}

for id, definition in definitions do
	definition.id = id
end

return definitions

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)

export type WeaponDefinition = {
	id: string,
	name: string,
	info: {
		description: string,
		attack: string,
		special: string,
		other: string,
	},
	price: number,
	currency: CurrencyDefinitions.CurrencyType,
	model: Model,
	[any]: any,
}

export type WeaponServer = {
	player: Player,
	definition: WeaponDefinition,

	equip: (WeaponServer) -> (),
	destroy: (WeaponServer) -> (),
	attack: (WeaponServer, ...any?) -> boolean,
	special: (WeaponServer, ...any?) -> boolean,
	dash: ((WeaponServer, ...any?) -> boolean)?,
	custom: ((WeaponServer, ...any?) -> ())?,
}

export type WeaponClient = {
	definition: WeaponDefinition,

	equip: (WeaponClient) -> (),
	destroy: (WeaponServer) -> (),
	attack: (WeaponClient, (...any?) -> ()) -> (),
	special: (WeaponClient, (...any?) -> ()) -> (),
	dash: ((WeaponClient, (...any?) -> ()) -> ())?,
}

local WeaponDefinitions = {
	Fist = {
		name = "Fist",
		info = {
			description = "The most basic weapon. It's your fist.",
			attack = "Rapidly punch with alternating hands. Deals extra damage while dashing.",
			special = "Deliver a swift uppercut, launching enemies up and away.",
			other = "Dashing resets the cooldown of your Special.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.2,
		attackRange = 12,
		specialCooldown = 2,
	},
	RedDagger = {
		name = "Red Dagger",
		info = {
			description = "A red dagger. It's sharp.",
			attack = "Slice enemies with quick slashes.",
			special = "Quickly cut twice, dealing high damage.",
			other = "Combining your attack and special with good timing can deal a lot of damage.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.3,
		attackRange = 12,
		specialCooldown = 1.5,
	},
	LinkedSword = {
		name = "Linked Sword",
		info = {
			description = "A classic Roblox weapon.",
			attack = "Slash at enemies with criss-crossing cuts.",
			special = "Cut with a quick spin attack. Resets your dash cooldown.",
			other = "Dash replaced with a damaging lunge that launches enemies forward.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.4,
		attackRange = 14,
		attackSounds = { "LinkedSwordSwing" },
		specialCooldown = 2,
		dashCooldown = 3,
	},
	Demon = {
		name = "Demon Fighter",
		info = {
			description = "These fists know no equal.",
			attack = "Deliver brutal blows with martial artistry.",
			special = "Jump into the air and come crashing down, launching enemies away when you hit the ground.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.34,
		attackRange = 14,
		specialRange = 16,
		specialCooldown = 5,
		dashCooldown = 1.05,
	},
	SlateMaul = {
		name = "Slate Maul",
		info = {
			description = "A giant maul made out of <s>granite</s> slate. It's made out of slate.",
			attack = "Hit enemies with wide, heavy swings.",
			special = "Jump into the air and smash the ground upon landing, launching enemies away.",
			other = "The longer you fall with your special, the larger the shockwave is when you land.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.6,
		attackDamage = 17.5,
		attackRange = 16,
		specialCooldown = 3,
		specialDamage = 25,

		attackSounds = { "HammerSlash1", "HammerSlash2", "HammerSlash3" },
		hitSounds = { "HammerHit1", "HammerHit2", "HammerHit3", "HammerHit4" },
		impactSounds = { "HammerSlam1" },

		launchSpeed = 256,
	},
	Balefire = {
		name = "Balefire",
		info = {
			description = "Fire magic inspired by classic Roblox.",
			attack = "Scorch enemies with melee fire magic.",
			special = "Lock yourself in space and summon a line of searing flame.",
			other = "Dash replaced with an explosive double jump that deals damage.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.4,
		attackRange = 16,
		specialCooldown = 5,
		dashCooldown = 3,
	},
	Glaive = {
		name = "Glaive",
		info = {
			description = "It's like a sword on a stick!",
			attack = "Slice through enemies with wide swings.",
			special = "Spin the glaive rapidly above your head, dealing damage. If done in midair, slowly float up.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.6,
		attackRange = 16,
		specialCooldown = 3,
		specialHitCount = 8,
	},
	StopSign = {
		name = "Stop Sign",
		info = {
			description = "A stop sign. Hopefully the road you took it from doesn't have any accidents.",
			attack = "Slap enemies with the broad front of the sign.",
			special = "Spin rapidly, slapping enemies. Enemies hit three times are launched away.",
			other = "Dash replaced with a smacking lunge that launches enemies away.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.5,
		attackRange = 16,
		specialCooldown = 3,
		specialHitCount = 5,
		dashCooldown = 2.5,
	},
	DragonSlayer = {
		name = "Dragon Slayer",
		info = {
			description = "A hulking slab of iron in the shape of a sword. Go berserk!",
			attack = "Cleave enemies with ridiculously large swings.",
			special = "Brace yourself for a moment, then annihilate everyone around you with a launching full spin attack.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 1,
		attackRange = 16,
		specialCooldown = 5,
		chargeDuration = 0.5,
	},
	Uncanny = {
		name = "Uncanny",
		info = {
			description = "😐 (model by @unaclanker)",
			attack = "Headbutt people.",
			special = "Headbutt people, but in a circle. Enemies hit three times get launched away.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.75,
		attackRange = 16,
		specialCooldown = 3,
		specialHitCount = 6,
	},
	Bat = {
		name = "Bat",
		info = {
			description = "A well-crafted wooden bat. Go for the home run!",
			attack = "Smack enemies with wild swings.",
			special = "Wind up for a home run swing, launching enemies far away.",
			other = "Hitting enemies with the special makes your attacks deal more damage for a bit.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.35,
		attackRange = 16,
		attackDamage = 14,
		attackDamageRage = 18,

		specialCooldown = 6,
		specialChargeDuration = 0.5,
		rageDuration = 10,
	},
	SamKatana = {
		name = "Sam's Katana",
		info = {
			description = "It's a katana, and it belongs to Sam.",
			attack = "Chop up enemies with criss-crossing slices. Try not to hit any arms.",
			special = "Sheathe your sword, then trigger an explosive slash that sends enemies flying.",
			other = "Immediately after dashing, your next three attacks are much faster.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.5,
		attackRange = 16,
		specialCooldown = 5,
		chargeDuration = 0.75,

		dashBuffDuration = 0.5,
		dashBuffCount = 3,
	},
	SqueakyHammer = {
		className = "SlateMaul",

		name = "Squeaky Hammer",
		info = {
			description = "A squeaky toy. Not for children ages 3 and under.",
			attack = "Swing the toy in front of you.",
			special = "Jump into the air and land with a shockwave, launching enemies away.",
			other = "A variation on the Slate Maul that's faster, launches further, but deals less damage.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.35,
		attackDamage = 12,
		attackRange = 16,
		specialCooldown = 3,
		specialDamage = 15,

		attackSounds = { "Swish1" },
		hitSounds = { "Squeak1", "Squeak2", "Squeak3" },
		impactSounds = { "DoubleSqueak1" },

		launchSpeed = 512,
	},
	RayGun = {
		name = "Ray Gun",
		info = {
			description = "An uncivilized weapon from the future. Get me up, I have Ray Gun!",
			attack = "Charge and fire a three-round burst of projectiles.",
			special = "Charge and fire a single exploding projectile which launches enemies.",
			other = `Hitting yourself with the special allows you to "laser jump" away from the explosion.`,
		},
		currency = "power",
		price = 0,

		attackCooldown = 1.5,
		specialCooldown = 5,
	},
	Abyss = {
		name = "Abyss Strider",
		info = {
			description = "A blade that's seen better days but is infused with a sinister darkness. You can trace a rogue lineage down to its dark soul.",
			attack = "Attack with a series of cutting and thrusting movements that push enemies.",
			special = "Jump up and forward, piercing the ground with your sword and afflicting enemies with darkness.",
			other = "Enemies afflicted with darkness take extra damage.",
		},
		currency = "power",
		price = 0,

		attackDamage = 18,
		attackDamageCursed = 25,
		attackRange = 18,
		attackCooldown = 0.48,
		attackLaunchSpeed = 100,

		specialBaseDamage = 5,
		specialCurseDamage = 10,
		specialChargeDuration = 0.5,
		specialCooldown = 7.5,
		specialRadius = 18,
		specialLaunchSpeed = 400,

		curseDuration = 16,
	},
	Pipe = {
		name = "Metal Pipe",
		info = {
			description = "A brutish, heavy weapon. Don't drop it.",
			attack = "Swing wildly, bashing your enemies.",
			special = "<s>Drop</s> throw the metal pipe. The sonic aftermath of it hitting the ground damages and launches enemies.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.38,
		attackRange = 16,
		attackDamage = 16.5,

		specialCooldown = 6,
		specialChargeDuration = 0.3,
	},
	Spear = {
		name = "Spear",
		info = {
			description = "A chapter in the long human story of getting further away from people while still being able to stab them.",
			attack = "Stab your enemies from far away.",
			special = "Perform a wide martial flourish which launches enemies away.",
			other = "",
		},
		currency = "power",
		price = 200,

		attackCooldown = 0.45,
		attackRange = 12,
		attackDamage = 19,

		specialRadius = 12,
		specialChargeDuration = 0.15,
		specialDamage = 18,
		specialLaunchSpeed = 400,
		specialCooldown = 4.5,
	},
	DhorakAxe = {
		name = "Dhorak's Greataxe",
		info = {
			description = "With how many bodies this thing makes, you'll need several wheelbarrows.",
			attack = "Hold to charge. If released early, pommel strike. If held, deliver a brutal swing which launches enemies.",
			special = "Summon the spirit of vengeance! For a brief moment, deal 75% of the damage you take back at attackers.",
			other = "The lower your health is, the more damage your attack (but not your special) deals.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 1,
		attackChargeDuration = 1,
		attackRange = 16,

		specialCooldown = 8,
		specialDuration = 1.5,
		specialReflectAmount = 0.75,
	},
	EarthBlade = {
		name = "Earth Blade",
		info = {
			description = "It might be the key to your victory.",
			attack = "Slash enemies with criss-cross strikes.",
			special = "Spin your blade in front of you, dealing damage and launching away enemies that are struck three times.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.4,
		attackRange = 14,
		attackSounds = { "BluntWhoosh1", "BluntWhoosh2", "BluntWhoosh3", "BluntWhoosh4", "BluntWhoosh5", "BluntWhoosh6" },
		specialCooldown = 2,
		specialDuration = 3,
		specialHitCount = 15,
	},
	Trident = {
		name = "Trident",
		info = {
			description = "An extra stabby weapon. Makes too many points. Sea what I did there?",
			attack = "Rapidly stab enemies in front of you.",
			special = "Throw a lightning-charged trident that explodes where it lands, damaging and launching enemies.",
			other = "",
		},
		currency = "power",
		price = 700,

		attackCooldown = 0.45,
		attackRange = 12,
		attackDamage = 18.5,

		specialRadius = 12,
		specialDamage = 15,
		specialChargeDuration = 0.5,
		specialLaunchSpeed = 400,
		specialCooldown = 5,
	},
	RocketLauncher = {
		name = "Rocket Launcher",
		info = {
			description = "Not a terribly creative name for something that launches rockets.",
			attack = "Fire explosive rockets that push enemies.",
			special = "Launch yourself with the rocket tube with accelerating speed, exploding upon hitting anything.",
			other = `You can "rocket jump" by catching yourself with your own attacks' explosions, launching you away.`,
		},
		currency = "power",
		price = 0,

		attackCooldown = 1.5,
		specialCooldown = 6,
		specialDuration = 2,
	},
	LaserSword = {
		name = "Legally Distinct Laser Sword",
		info = {
			description = "A sword, but it's a laser. Use the mass multiplied by acceleration.",
			attack = "Zap enemies with quick diagonal strikes.",
			special = "Summon... uh, a mystical power to launch enemies in front of you.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.5,
		attackRange = 16,
		specialCooldown = 5,
	},
	Paddle = {
		name = "Ping Pong Paddle",
		info = {
			description = "Equipment for an indoor sport. It's Project Power's ping pong paddle.",
			attack = "Rapidly hit ping pong balls as projectiles.",
			special = "Cartoonishly increase the size of your paddle and smack enemies in front of you, launching them away.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackDamage = 17.5,
		attackCooldown = 0.1,
		attackChargeDuration = 0.2,

		specialDamage = 30,
		specialCooldown = 5,
		specialChargeDuration = 0.45,
		specialRange = 16,
	},
	Pyromaniac = {
		name = "Pyromaniac",
		info = {
			description = "A glass bottle filled with flammable liquid. Some people just want to watch the world burn.",
			attack = "Strike enemies with a series of flailing attacks.",
			special = "Hold to charge. If released early, throw the bottle, which explodes. If held, spit fire at enemies in front of you.",
			other = "Enemies hit by either special are set on fire, burning for some extra damage.",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.45,
		attackRange = 8,
		attackDamage = 15,

		throwDamage = 10,
		throwRadius = 10,
		throwLaunchSpeed = 256,
		throwCooldownMultiplier = 0.4,

		fireBreathDamage = 15,
		fireBreathRange = 15,
		fireBreathChargeDuration = 0.5,
		fireBreathDuration = 0.85,
		fireBreathLaunchSpeed = 256,
		fireBreathStun = 0.8,

		specialCooldown = 4,
		specialRadius = 12,

		burnDamage = 3,
		burnAmount = 8,
		burnInterval = 0.25,
	},
	Isoh = {
		name = "Reversed Lance of Paradise",
		info = {
			description = "Some people call this a tool, but that's kind of cursed.",
			attack = "Slice enemies with quick slashes.",
			special = "Wind up and stab ahead, preventing enemies hit from using their special for a few seconds.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.3,
		attackRange = 12,
		specialCooldown = 7.5,
	},
	Unlimited = {
		name = "Unlimited Technique",
		info = {
			description = "A technique that makes the abstract concepts of infinite sequences quite concrete.",
			attack = "Hold to charge. If released early, throw a blue orb that deals damage. If held, throw a red orb that launches enemies.",
			special = "Wind up and release a large, slow-moving purple orb that deals tremendous damage.",
			other = "",
		},
		currency = "power",
		price = 0,

		attackCooldown = 0.75,
		specialCooldown = 10,
	},
}

do -- assign prices to the ordered weapons mathematically
	local unlockOrder = {
		"Fist",
		"RedDagger",
		"LinkedSword",
		"SlateMaul",
		"DragonSlayer",
		"Isoh",
		"RayGun",
		"Glaive",
		"Bat",
		"RocketLauncher",
		"Spear",
		"Demon",
		"Paddle",
		"DhorakAxe",
		"Balefire",
		"StopSign",
		"Trident",
		"SqueakyHammer",
		"Pyromaniac",
		"Uncanny",
		"Pipe",
		"SamKatana",
		"EarthBlade",
		"LaserSword",
		"Abyss",
		"Unlimited",
	}
	local powerPerMinute = 15000 / 60
	local downtime = 0.3
	local downtimeStep = 1.75
	local downtimeStepStep = 1.75
	for rank, weaponId in unlockOrder do
		local price = downtime * powerPerMinute

		local def = WeaponDefinitions[weaponId]
		def.price = math.round(price / 10) * 10
		def.order = rank

		downtimeStep += downtimeStepStep
		downtime += downtimeStep
	end
end

local Assets = ReplicatedStorage:FindFirstChild("Assets")
local AssetsFolder = Assets and Assets:FindFirstChild("Weapons") :: Folder

for id, weaponDefinition in WeaponDefinitions do
	local asset = AssetsFolder and AssetsFolder:FindFirstChild(id) :: Model | BasePart

	if not asset then
		warn(`WeaponDefinitions: Could not find asset for weapon {id}`)
		continue
	end

	local model = asset
	if asset:IsA("BasePart") then
		model = Instance.new("Model")
		model.Name = asset.Name

		asset.Parent = model
		model.PrimaryPart = asset
		asset.Name = "Root"

		model.Parent = AssetsFolder
	end

	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.Massless = true
			object.CanCollide = false
			object.Anchored = false
		end
	end

	weaponDefinition.id = id
	weaponDefinition.model = model
end

WeaponDefinitions.Fist.price = 0 -- TODO: remove this

return WeaponDefinitions :: { [string]: WeaponDefinition }

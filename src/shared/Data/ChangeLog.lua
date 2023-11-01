return {
	"10/6/2023",
	{
		"Changed",
		{
			"Rocket Launcher",
			{
				"Self damage on attack and special 7.5 -> 30",
			},
			"Ray Gun",
			{
				"Self damage on special 7.5 -> 30",
			},
			"Other",
			{
				"Increased the size of weapon stand leaderboards 'cause y'all got long usernames.",
				"Jump pads are now blue.",
				"Spawn points are now invisible.",
				`Power-up pads will no longer spawn the "full heal" power-up.`,
				"New pads have been added to all maps in rotation which are guaranteed to spawn a health pickup that restores 50 health over 3 seconds.",
			},
		},
		"Fixed",
		{
			"Hitting breakable buildings with moves that ragdoll no longer causes them to lose their collision.",
			"Falling all the way out of the arena (not hitting any kill floor) will now properly give kill credit.",
		},
	},
	"10/4/2023 Part 2",
	{
		"Added",
		{
			"Killing bots will now show up in the kill feed and the kill popup.",
			"Getting killed by bots will now show up in the kill feed.",
			"If you're killed by someone who has no kill images equipped, you will see a default kill image of ☠️ to make it more obvious that you have died.",
		},
	},
	"10/4/2023",
	{
		"Added",
		{
			"Practice Mode",
			{
				"There's now a new portal in the lobby which will take you to your very own practice space.",
				"In the practice space, a detailed explanation of your equipped weapon is visible.",
				"There's also a training dummy with infinite health that you can test your techniques on.",
				"Hitting the dummy does grant some power, but not as much as fighting bots or players in the arena.",
			},
		},
		"Changed",
		{
			"The shop no longer has a chance to open upon respawning in the lobby.",
		},
		"Fixed",
		{
			`A bug involving double jump allowed players to essentially have more jump charges than intended, allowing them to stay airborne nearly indefinitely. Now, double jumping resets the "charge timer" on jumping without actively costing a charge like jumping off the ground does.`,
		},
	},
	"10/3/2023",
	{
		"Added",
		{
			"Bots",
			{
				"Bots have been added to the game! Currently, just the Noob Bot is available.",
				"Attacking bots grants 75% power and does not grant kills for the leaderboard.",
				"Every second, if the number of players in the game plus the number of bots in the arena is less than ten, a bot will spawn. Once there are ten or more players, the bots will disappear after they're killed.",
				"More bot types are coming soon! We're also considering using them in alternative gamemodes.",
			},
		},
		"Changed",
		{
			"Ray Gun",
			{
				"Attack damage 15 -> 20.",
				"Special damage 25 -> 30.",
			},
			"Pyromaniac",
			{
				"Attack damage 13.5 -> 15.",
			},
			"Ping Pong Paddle",
			{
				"Attack damage 10 -> 17.5.",
				"Special damage 14 -> 30.",
				"Special launch amount 350 -> 450.",
			},
		},
		"Fixed",
		{
			"You can no longer get two identical daily challenges.",
			"Data is now automatically saved every 90 seconds rather than just when the server closes, so crashing servers should no longer cause data loss.",
		},
	},
	"9/30/2023",
	{
		"New weapon: Ping Pong Paddle",
		{
			"Attack: a quick single-target projectile",
			"Special: enlarge the paddle and smack people in front of you",
		},
		"Badges!",
		{
			"Powerhouse: get 10,000 power",
			"Battle Tested: get 30 kills",
			"Full Power: reach max level",
			"More to come soon!",
		},
		"New map: Dustpit",
		"Various map changes balancing out spawns, powerup pads, and damage zones",
	},
	"9/25/2023",
	{
		"New weapon: Pyromaniac",
		{
			"Attack: a sequence of varying melee hits",
			"Special: tap to throw a molotov cocktail, hold to chug fuel and release to breathe fire",
		},
		"New map: Vapor Dreams",
		"Lobby rework",
		{
			"Is now transparent, allowing you to spectate the battle (maps with obscuring parts will be made transparent)",
			"New launcher to send you into battle instead of a portal",
			"Weapons more conveniently located",
			"You have faster movement speed in the lobby",
			"Stepping off while send you into the fight",
			"Trying to break into the lobby will result in... something fun! 😁",
		},
		"Power gain from attacking players has been increased by 10 times, and most power requirements (weapon prices, level-ups) have been adjusted to account for this",
		"Players now have 200 health instead of 100 health, allowing for a longer time-to-kill",
		"You now get 10 maximum health when you level up instead of 5",
		"You no longer full heal on every level up, instead only at level 10",
		"You get a modest amount of power for destroying props on the map with your weapon",
		"Linked Sword's special now resets its dash cooldown",
	},
	"9/3/2023",
	{
		"New map: Blossom",
		"Confirmed a fix for the bug that would prevent you from entering the game",
		"Fixed a bug where you could acquire too much power when killing players with more damage than they had health remaining",
		"Fixed a bug where you could get progress on daily challenges by killing yourself",
		"Made it impossible to deal damage to, stun, or push back players that are not yet in battle so that players that glitch their way back to the lobby during battle cannot earn power or harass other players.",
	},

	"9/2/2023",
	{
		"Dhorak's Greataxe",
		{
			"Damage 50 -> 40",
			"Missing health scaling 1:1 -> 1:0.75",
			"Can now attack during ability",
		},
		"Added text to the Shop button",
		"Added text to the Starter Pack button",
		"Added an update log",
		"Added daily challenges",
		{
			"Get a killstreak with a weapon",
			"Get a certain amount of power",
			"Play a certain number of rounds",
		},
		"Added a possible fix to a rare bug which would make it impossible to enter battle",
		"Fixed a bug that was causing Playtime Rewards not to reset after a day (rewards you get just for playing a certain number of rounds every day)",
	},
}

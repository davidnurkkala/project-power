local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)

local Products = {
	currency = {
		order = 1,
		displayName = "Crystals",
		displayNameSingular = "Crystal",
		products = {
			Crystals50 = {
				assetId = 1582087840,
				amount = 50,
				name = "50 Crystals",
				description = "50 Crystals",
				image = "rbxassetid://14056846473",
			},
			Crystals100 = {
				assetId = 1582088707,
				amount = 100,
				name = "100 Crystals",
				description = "100 Crystals",
				image = "rbxassetid://14056846473",
			},
			Crystals250 = {
				assetId = 1582089242,
				amount = 250,
				name = "250 Crystals",
				description = "250 Crystals",
				image = "rbxassetid://14056846473",
			},
			Crystals500 = {
				assetId = 1582089757,
				amount = 500,
				name = "500 Crystals",
				description = "500 Crystals",
				image = "rbxassetid://14056846473",
			},
		},
	},
	booster = {
		order = 2,
		displayName = "Boosters",
		displayNameSingular = "Booster",
		products = {
			Minutes15 = {
				pricePremium = 25,
				name = "15 Minutes",
				description = "15 minutes of x2 Power",
				image = "",
				amount = 15,
			},
			Minutes30 = {
				pricePremium = 45,
				name = "30 Minutes",
				description = "30 minutes of x2 Power",
				image = "",
				amount = 30,
			},
			Minutes60 = {
				pricePremium = 90,
				name = "60 Minutes",
				description = "60 minutes of x2 Power",
				image = "",
				amount = 60,
			},
			Minutes120 = {
				pricePremium = 150,
				name = "2 Hours",
				description = "Two hours of x2 Power",
				image = "",
				amount = 120,
			},
		},
	},
	taunt = {
		order = 3,
		displayName = "Taunts",
		displayNameSingular = "Taunt",
		products = {
			Griddy = {
				pricePremium = 100,
				name = "Griddy",
				description = "Hit the griddy. Honestly, why is this dance popular? It's so simple. I honestly didn't believe it when I learned how it was supposed to be done. How does this constitute a dance move, let alone a viral one? Come on!",
				image = "rbxassetid://14056846473",
			},
			DefaultDance = {
				pricePremium = 100,
				name = "Default Dance",
				description = `This is a great way to show off your dance moves, especially if you haven't hit the floor in a fortnight.`,
				image = "rbxassetid://14056846473",
			},
			Twist = {
				pricePremium = 100,
				name = "Twist",
				description = `Wipe your enemies off your boots.`,
				image = "rbxassetid://14056846473",
			},
			Flex = {
				pricePremium = 100,
				name = "Flex",
				description = `Flex on 'em!`,
				image = "rbxassetid://14056846473",
			},
			BackSmack = {
				pricePremium = 100,
				name = "Back Smack",
				description = `Hey, nerd! Yeah, right here!`,
				image = "rbxassetid://14056846473",
			},
			Cutthroat = {
				pricePremium = 100,
				name = "Cutthroat",
				description = `You're dead meat, pal.`,
				image = "rbxassetid://14056846473",
			},
			Attrition = {
				pricePremium = 100,
				name = "Attrition",
				description = `I'm literally crying and shaking right now.`,
				image = "rbxassetid://14056846473",
			},
			CanCan = {
				pricePremium = 100,
				name = "Can-can",
				description = `I don't know, can you?`,
				image = "rbxassetid://14056846473",
			},
			SoulSpin = {
				pricePremium = 100,
				name = "Soul Spin",
				description = `You spin me right round, baby, right round, like a record, baby!`,
				image = "rbxassetid://14056846473",
			},
			RunningMan = {
				pricePremium = 100,
				name = "Running Man",
				description = `Nothing quite like basic human locomotion, but without any of the upsides.`,
				image = "rbxassetid://14056846473",
			},
			Rumba = {
				pricePremium = 100,
				name = "Rumba",
				description = `Do you want to dance? Because Havana dance. Get it? It's because Rumba is from Cuba, and "Havana" sounds like "I wanna," so I basically said "I wanna dance" after asking you if you wanted to. It's funny, right?`,
				image = "rbxassetid://14056846473",
			},
			Robot = {
				pricePremium = 100,
				name = "Robot",
				description = `Domo arigato, Mister Roboto, for doing the job that nobody wants to.`,
				image = "rbxassetid://14056846473",
			},
		},
	},
	killSound = {
		order = 4,
		displayName = "Kill Sounds",
		displayNameSingular = "Kill Sound",
		isMultiEquip = true,
		products = {
			VineBoom = {
				pricePremium = 25,
				name = "Vine Boom",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://5178876770",
			},
			ShortScream = {
				pricePremium = 10,
				name = "Short Scream",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://9125652443",
			},
			Yeet = {
				pricePremium = 25,
				name = "Yeet",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://2690828999",
			},
			Bababooey = {
				pricePremium = 25,
				name = "Bababooey",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://4956861134",
			},
			WilhelmScream = {
				pricePremium = 25,
				name = "Wilhelm Scream",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://605536910",
			},
			RobloxOof = {
				pricePremium = 25,
				name = "Oof",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://14214915070",
			},
			MinecraftOof = {
				pricePremium = 25,
				name = "Steve Oof",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://14214868011",
			},
			DarkSoulsDeath = {
				pricePremium = 25,
				name = "You Died",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://14214868317",
			},
			SamGoodbye = {
				pricePremium = 25,
				name = "Goodbye",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://14214868445",
			},
			Bruh = {
				pricePremium = 25,
				name = "Bruh",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://14214868567",
			},
			SuperIdol = {
				pricePremium = 25,
				name = "Super Idol",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://14214868132",
			},
			PriceHorn = {
				pricePremium = 25,
				name = "Price is Right",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://14214914935",
			},
			OhDear = {
				pricePremium = 25,
				name = "Oh dear, you are dead!",
				image = "rbxassetid://7203392850",
				soundId = "rbxassetid://14270156070",
			},
		},
	},
	killImage = {
		order = 5,
		displayName = "Kill Images",
		displayNameSingular = "Kill Image",
		isMultiEquip = true,
		products = {
			PointingSoyjaks = {
				pricePremium = 150,
				name = "Pointing Soyjaks",
				image = "rbxassetid://13562728827",
			},
			GentlemanFrog = {
				pricePremium = 150,
				name = "Gentleman Frog",
				image = "rbxassetid://14214827376",
			},
			YouDied = {
				pricePremium = 150,
				name = "You Died",
				image = "rbxassetid://14214825721",
			},
			EmoPenguin = {
				pricePremium = 150,
				name = "Emo Penguin",
				image = "rbxassetid://14214826248",
			},
			Sit = {
				pricePremium = 150,
				name = "Sit",
				image = "rbxassetid://14214826004",
			},
			SmugJak = {
				pricePremium = 150,
				name = "SmugJak",
				image = "rbxassetid://14214825852",
			},
			SadJak = {
				pricePremium = 150,
				name = "SadJak",
				image = "rbxassetid://14214827508",
			},
			PovertyDetected = {
				priceSpecial = "From\nStarter Pack",
				name = "Poverty Detected",
				image = "rbxassetid://14503575720",
			},
			MonkeyNotNeeded = {
				pricePremium = 250,
				name = "JJK Unneeded",
				image = "rbxassetid://14983587692",
			},
			KnowYourPlace = {
				pricePremium = 250,
				name = "JJK Know Your Place",
				image = "rbxassetid://14983587511",
			},
			SurprisedYouThought = {
				pricePremium = 250,
				name = "JJK Surprised You Thought",
				image = "rbxassetid://14983845287",
			},
		},
	},
	other = {
		invisible = true,
		products = {
			StarterPack = {
				assetId = 1618098958,
			},
		},
	},

	--[[killEffect = {
		order = 3,
		displayName = "Kill Effects",
		displayNameSingular = "Kill Effect",
		products = {
			BreakApart = {
				pricePremium = 50,
				name = "Break Apart",
				description = "Players you kill will fall to pieces.",
				image = "rbxassetid://14056846473",
			},
		},
	},]]
}

for kind, category in Products do
	for id, product in category.products do
		product.kind = kind
		product.id = id
		product.getPrice = function()
			if product.pricePremium then return Promise.resolve(product.pricePremium, "premium") end

			if product.priceSpecial then return Promise.resolve(product.priceSpecial) end

			if not product.assetId then
				return Promise.resolve(-1, nil)
			elseif product._priceRobux then
				return Promise.resolve(product._priceRobux, "robux")
			else
				return Promise.try(function()
					local info = MarketplaceService:GetProductInfo(product.assetId, Enum.InfoType.Product)
					if info and info.PriceInRobux then
						product._priceRobux = info.PriceInRobux
						return product._priceRobux, "robux"
					else
						return -1, nil
					end
				end):catch(function()
					return -1, nil
				end)
			end
		end
	end
end

type Promise<T...> = any

return Products :: {
	[string]: {
		invisible: boolean?,
		isMultiEquip: boolean?,

		order: number?,
		displayName: number?,
		displayNameSingular: number?,

		products: {
			[string]: {
				kind: string,
				id: string,
				getPrice: () -> Promise<number, string>,
				pricePremium: number?,
				assetId: number?,
				name: string?,
				[string]: any,
			},
		},
	},
}

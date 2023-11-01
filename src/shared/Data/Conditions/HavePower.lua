local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)

return function(player: Player, amount: number)
	return Badger.create({
		state = {},
		getFilter = function()
			return {
				PowerEarned = true,
			}
		end,
		process = function(_self, _kind, payload)
			if payload.player ~= player then return end
		end,
		isComplete = function()
			return CurrencyService:getCurrency(player, "power") >= amount
		end,
	})
end

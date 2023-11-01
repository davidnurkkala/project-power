local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local InventoryService = require(ServerScriptService.Server.Services.InventoryService)

return function(_context, players: { Player }, currency: CurrencyDefinitions.CurrencyType, amount: number): string
	if amount >= 0 then
		for _, player in players do
			CurrencyService:addCurrency(player, currency, amount)
		end
		if #players == 1 then return `Added {amount} {currency} for {players[1].Name}` end
		return `Added {amount} {currency} for {#players} players`
	end

	for _, player in players do
		InventoryService:removeItem(currency, -amount, player)
	end
	if #players == 1 then return `Removed {-amount} {currency} for {players[1].Name}` end
	return `Removed {-amount} {currency} for {#players} players`
end

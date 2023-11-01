local ServerScriptService = game:GetService("ServerScriptService")

local InventoryService = require(ServerScriptService.Server.Services.InventoryService)

return function(_context, players: { Player }, itemId: string, amount: number)
	for _, player in players do
		InventoryService:addItem(itemId, amount, player)
	end

	if #players == 1 then return `Added {amount} of {itemId} to {players[1]}'s inventory` end
	return `Added {amount} of {itemId} to {#players} players' inventories.`
end

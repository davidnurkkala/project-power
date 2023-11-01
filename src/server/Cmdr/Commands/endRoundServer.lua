local ServerScriptService = game:GetService("ServerScriptService")

local BattleService = require(ServerScriptService.Server.Services.BattleService)

return function()
	BattleService.roundEndForced:Fire()
	return `Attempted to end the round.`
end

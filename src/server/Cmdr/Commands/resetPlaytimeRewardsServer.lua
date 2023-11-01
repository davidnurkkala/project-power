local ServerScriptService = game:GetService("ServerScriptService")

local PlaytimeRewardsService = require(ServerScriptService.Server.Services.PlaytimeRewardsService)

return function(_, player)
	PlaytimeRewardsService:resetPlayer(player)
	return `Reset {player}'s playtime rewards.`
end

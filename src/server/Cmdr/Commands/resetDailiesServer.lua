local ServerScriptService = game:GetService("ServerScriptService")

local ChallengeService = require(ServerScriptService.Server.Services.ChallengeService)

return function(_, player)
	ChallengeService:rerollPlayer(player)
end

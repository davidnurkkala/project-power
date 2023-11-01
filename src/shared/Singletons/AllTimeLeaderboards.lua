local ServerScriptService = game:GetService("ServerScriptService")

local AllTimeLeaderboard = require(ServerScriptService.Server.Classes.AllTimeLeaderboard)
local AllTimeLeaderboards = {}

function AllTimeLeaderboards:_init()
	AllTimeLeaderboards._leaderboards = {
		kills = AllTimeLeaderboard.new("kills"),
		power = AllTimeLeaderboard.new("power"),
	}
end

function AllTimeLeaderboards:getLeaderboard(key)
	return self._leaderboards[key]
end

AllTimeLeaderboards:_init()
return AllTimeLeaderboards

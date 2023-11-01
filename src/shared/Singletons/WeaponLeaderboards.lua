local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local WeaponLeaderboard = require(ServerScriptService.Server.Classes.WeaponLeaderboard)

local WeaponLeaderboards = {
	_leaderboardsById = {},
}

function WeaponLeaderboards:_init()
	game:BindToClose(function()
		Promise.allSettled(Sift.Dictionary.map(self._leaderboardsById, function(leaderboard)
			return leaderboard:onGameClosed()
		end)):expect()
	end)
end

function WeaponLeaderboards:getLeaderboard(id)
	if not self._leaderboardsById[id] then self._leaderboardsById[id] = WeaponLeaderboard.new(id) end
	return self._leaderboardsById[id]
end

WeaponLeaderboards:_init()
return WeaponLeaderboards

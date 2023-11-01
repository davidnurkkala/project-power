local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetKills = require(ReplicatedStorage.Shared.Data.Conditions.GetKills)

local BADGE_ID = 2152660968
local KILLS = 30

return {
	maker = function(player)
		return GetKills(player, KILLS)
	end,
	badgeId = BADGE_ID,
}

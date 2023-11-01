local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HasReachedLevel = require(ReplicatedStorage.Shared.Data.Conditions.HasReachedLevel)

local BADGE_ID = 2152660995
local LEVEL_REACHED = 10

return {
	maker = function(player)
		return HasReachedLevel(player, LEVEL_REACHED)
	end,
	badgeId = BADGE_ID,
}

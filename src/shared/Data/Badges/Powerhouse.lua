local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HavePower = require(ReplicatedStorage.Shared.Data.Conditions.HavePower)

local BADGE_ID = 2152660913
local POWER_AMOUNT = 10000

return {
	maker = function(player)
		return HavePower(player, POWER_AMOUNT)
	end,
	badgeId = BADGE_ID,
}

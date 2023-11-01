local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HavePower = require(ReplicatedStorage.Shared.Data.Conditions.HavePower)

local BADGE_ID = 2152927677
local POWER_AMOUNT = 500000

return {
	maker = function(player)
		return HavePower(player, POWER_AMOUNT)
	end,
	badgeId = BADGE_ID,
}

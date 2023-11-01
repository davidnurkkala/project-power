local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HavePower = require(ReplicatedStorage.Shared.Data.Conditions.HavePower)

local BADGE_ID = 2152927665
local POWER_AMOUNT = 300000

return {
	maker = function(player)
		return HavePower(player, POWER_AMOUNT)
	end,
	badgeId = BADGE_ID,
}

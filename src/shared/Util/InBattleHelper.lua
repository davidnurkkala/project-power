local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sift = require(ReplicatedStorage.Packages.Sift)
local TryNow = require(ReplicatedStorage.Shared.Util.TryNow)
local InBattleHelper = {}

InBattleHelper.attributeNames = { "InBattle", "InPractice" }

function InBattleHelper.isModelInBattle(model: Model)
	return TryNow(function()
		local player = Players:GetPlayerFromCharacter(model)
		if not player then
			return true
		else
			return Sift.Array.some(InBattleHelper.attributeNames, function(attributeName)
				return model:GetAttribute(attributeName) == true
			end)
		end
	end, false)
end

function InBattleHelper.isPlayerInBattle(player: Player)
	if player.Character ~= nil then
		return InBattleHelper.isModelInBattle(player.Character)
	else
		return false
	end
end

function InBattleHelper.isCharacterInPractice(char: Model)
	return char:GetAttribute("InPractice") == true
end

return InBattleHelper

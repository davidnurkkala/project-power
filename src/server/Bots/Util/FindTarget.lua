local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BotTarget = require(ServerScriptService.Server.Bots.Util.BotTarget)
local TryNow = require(ReplicatedStorage.Shared.Util.TryNow)

return function(position: Vector3, radius: number): Humanoid?
	for _, player in Players:GetPlayers() do
		if player:DistanceFromCharacter(position) <= radius then
			return TryNow(function()
				local target = BotTarget.new(player.Character.Humanoid)
				if target:isAlive() then return target end

				return nil
			end)
		end
	end
	return nil
end

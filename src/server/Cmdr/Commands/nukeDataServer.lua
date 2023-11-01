local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)

local Nukees = {}

return function(_context, player: Player): string
	if Nukees[player] then
		local store = DataStore2(Configuration.DataStoreKey, player)
		store:Set({})
		return `Player {player.Name} has had their data reset.`
	else
		Nukees[player] = true
		task.delay(10, function()
			Nukees[player] = nil
		end)
		return `Are you certain you want to nuke {player.Name}'s data? Re-use this command within 10 seconds to confirm.`
	end
end

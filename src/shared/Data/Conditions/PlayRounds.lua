local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local Sift = require(ReplicatedStorage.Packages.Sift)
return function(player: Player, count: number)
	local function getState()
		return {
			rounds = 0,
		}
	end

	return Badger.create({
		state = getState(),
		getFilter = function()
			return {
				RoundEnded = true,
			}
		end,
		process = function(self, _, payload)
			if payload.player ~= player then return end
			self.state.rounds += 1
		end,
		isComplete = function(self)
			return self.state.rounds >= count
		end,
		reset = function(self)
			self.state = getState()
		end,
		save = function(self)
			return Sift.Dictionary.copyDeep(self.state)
		end,
		load = function(self, data)
			self.state = Sift.Dictionary.copyDeep(data)
		end,
	})
end

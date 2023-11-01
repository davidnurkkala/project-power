local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local Sift = require(ReplicatedStorage.Packages.Sift)

return function(player, number)
	local function getState()
		return {
			kills = 0,
		}
	end

	return Badger.create({
		state = getState(),
		getFilter = function(_self)
			return {
				PlayerKilled = true,
			}
		end,
		process = function(self, _, payload)
			if payload.killer == payload.target then return end
			if payload.killer ~= player then return end
			self.state.kills += 1
		end,
		isComplete = function(self)
			return self.state.kills >= number
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

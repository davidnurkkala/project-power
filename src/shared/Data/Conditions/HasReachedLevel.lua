local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local Sift = require(ReplicatedStorage.Packages.Sift)

return function(player, level)
	local function getState()
		return {
			level = 0,
		}
	end

	return Badger.create({
		state = getState(),
		getFilter = function(_self)
			return {
				LevelReached = true,
			}
		end,
		process = function(self, _, payload)
			if payload.player ~= player then return end
			self.state.level = payload.level
		end,
		isComplete = function(self)
			return self.state.level >= level
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

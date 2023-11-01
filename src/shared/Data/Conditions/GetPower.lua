local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local Sift = require(ReplicatedStorage.Packages.Sift)

return function(player: Player, amount: number)
	local function getState()
		return {
			power = 0,
		}
	end

	return Badger.create({
		state = getState(),
		getFilter = function()
			return {
				PowerEarned = true,
			}
		end,
		process = function(self, _kind, payload)
			if payload.player ~= player then return end
			self.state.power += payload.amount
		end,
		isComplete = function(self)
			return self.state.power >= amount
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

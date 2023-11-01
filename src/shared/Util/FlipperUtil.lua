local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local FlipperUtil = {}

function FlipperUtil.waitForGoal(motor, goal, targetValue: number?)
	return Promise.new(function(resolve, _reject, onCancel)
		motor:setGoal(goal)

		local connection
		if targetValue then
			local increasing = motor:getValue() < targetValue
			connection = motor:onStep(function(value)
				if (increasing and (value > targetValue)) or (not increasing and (value < targetValue)) then
					connection:disconnect()
					resolve()
				end
			end)
		else
			connection = motor:onComplete(function()
				connection:disconnect()
				resolve()
			end)
		end

		onCancel(function()
			connection:disconnect()
		end)
	end)
end

return FlipperUtil

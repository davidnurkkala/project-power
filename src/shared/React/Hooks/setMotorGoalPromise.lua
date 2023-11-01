local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

return function(motor, goal, predicate)
	motor:setGoal(goal)
	return Promise.new(function(resolve, _reject, onCancel)
		local connection

		connection = motor:onStep(function()
			if predicate(motor:getValue()) then
				connection:disconnect()
				resolve()
			end
		end)

		onCancel(function()
			connection:disconnect()
		end)
	end)
end

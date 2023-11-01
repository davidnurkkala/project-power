local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animation = require(ReplicatedStorage.Shared.Util.Animation)

return function(model, root, spawnCFrame)
	return {
		onEntered = function(state)
			state.finished = false

			root.Anchored = true

			local startCFrame = model:GetPivot()
			local midpoint = Vector3.new(startCFrame.X, spawnCFrame.Y, startCFrame.Z)
			local midCFrame = startCFrame.Rotation + midpoint

			state.promise = Animation(1, function(scalar)
					model:PivotTo(startCFrame:Lerp(midCFrame, scalar))
				end)
				:andThenCall(Animation, 1, function(scalar)
					model:PivotTo(midCFrame:Lerp(spawnCFrame, scalar))
				end)
				:andThen(function()
					state.finished = true
				end)
				:finally(function()
					root.Anchored = false
				end)
		end,
		onUpdated = function(state)
			if state.finished then
				return "idling"
			else
				return
			end
		end,
		onWillLeave = function(state)
			state.promise:cancel()
			state.promise = nil
		end,
	}
end

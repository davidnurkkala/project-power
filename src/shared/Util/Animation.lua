local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Promise = require(ReplicatedStorage.Packages.Promise)

local EVENT = if RunService:IsClient() then RunService.RenderStepped else RunService.Heartbeat

return function(duration, callback)
	return Promise.new(function(resolve, _, onCancel)
		callback(0)

		local steppedConnection
		local t = 0
		steppedConnection = EVENT:Connect(function(dt)
			t += dt

			local alpha = math.min(t / duration, 1)
			callback(alpha)

			if alpha == 1 then
				steppedConnection:Disconnect()
				resolve()
			end
		end)

		onCancel(function()
			steppedConnection:Disconnect()
			callback(1)
		end)
	end)
end

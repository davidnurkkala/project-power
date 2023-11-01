local RunService = game:GetService("RunService")
local ScalarClock = {}
ScalarClock.__index = ScalarClock

function ScalarClock.new(cycleTime: number, callback: (number) -> ())
	local clock = 0
	local self = setmetatable({
		_connection = RunService.Heartbeat:Connect(function(dt)
			clock += dt
			clock = clock % cycleTime
			callback(clock / cycleTime)
		end),
	}, ScalarClock)
	return self
end

function ScalarClock:destroy()
	self._connection:Disconnect()
end

return ScalarClock

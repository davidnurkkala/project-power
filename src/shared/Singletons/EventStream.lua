local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

export type EventFilter = { [string]: boolean }

local EventStream = {}

local eventHappened = Signal.new()

function EventStream:event(kind: string, payload: any)
	eventHappened:Fire(kind, payload)
end

function EventStream:subscribe(callback: (string, any) -> (), filter: EventFilter?)
	if filter then
		filter = Sift.Dictionary.copy(filter)
		return eventHappened:Connect(function(kind, payload)
			if not filter[kind] then return end
			callback(kind, payload)
		end)
	else
		return eventHappened:Connect(callback)
	end
end

return EventStream

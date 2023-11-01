local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventStream = require(ReplicatedStorage.Shared.Singletons.EventStream)
local Sift = require(ReplicatedStorage.Packages.Sift)

export type ConditionExtension = {
	willProcess: (Condition) -> boolean,
	didProcess: (Condition) -> (),
}

export type Condition = {
	_extensionQueues: {
		willProcess: {},
		didProcess: {},
	}?,

	save: (Condition) -> { [any]: any },
	load: (Condition, { [any]: any }) -> nil,
	reset: (Condition) -> nil,
	process: (Condition, ...any) -> nil,
	isComplete: (Condition) -> boolean,

	getFilter: (Condition) -> { [string]: boolean },
	getDescription: (Condition) -> string,
	getProgress: (Condition) -> number,
	getState: (Condition) -> any,
}

local Badger: any = {}
Badger.condition = {
	__index = {
		save = function()
			return nil
		end,
		load = function() end,
		reset = function() end,
		process = function() end,
		isComplete = function()
			return false
		end,

		getFilter = function()
			return {}
		end,
		getDescription = function()
			return ""
		end,
		getProgress = function()
			return 0
		end,
		getState = function()
			return {}
		end,

		-- builder methods
		with = function(self, prerequisiteList)
			return Badger.with(self, Badger.all(prerequisiteList))
		end,
		without = function(self, prerequisiteList)
			return Badger.without(self, Badger.all(prerequisiteList))
		end,
	},
}

-- event stream listener
local activeListenerSets = {}
local function getListenerSet(kind: string)
	if activeListenerSets[kind] then return activeListenerSets[kind] end

	local new = {}
	activeListenerSets[kind] = new

	EventStream:subscribe(function(eventKind, payload)
		for condition in new do
			condition:process(eventKind, payload)
		end
	end, {
		[kind] = true,
	})

	return new
end

function Badger.create(condition: Condition)
	return setmetatable(condition, Badger.condition)
end

function Badger.wrap(core: Condition, wrapper: Condition)
	return setmetatable(wrapper, { __index = core })
end

function Badger.processFiltered(condition, kind, payload)
	if not condition:getFilter()[kind] then return end
	condition:process(kind, payload)
end

function Badger.all(conditionList: { Condition }): Condition
	return Badger.create({
		save = function(_self)
			return Sift.Array.map(conditionList, function(condition)
				return condition:save()
			end)
		end,
		load = function(_self, data)
			for index, save in data do
				conditionList[index]:load(save)
			end
		end,
		process = function(_self, ...)
			for _, condition in conditionList do
				Badger.processFiltered(condition, ...)
			end
		end,
		reset = function(_self)
			for _, condition in conditionList do
				condition:reset()
			end
		end,
		isComplete = function(_self)
			for _, condition in conditionList do
				if not condition:isComplete() then return false end
			end
			return true
		end,
		getFilter = function(_self)
			return Sift.Set.merge(table.unpack(Sift.Array.map(conditionList, function(condition)
				return condition:getFilter()
			end)))
		end,
		getState = function(_self)
			return Sift.Array.map(conditionList, function(condition)
				return condition:getState()
			end)
		end,
	})
end

function Badger.any(conditionList: { Condition }): Condition
	return Badger.create({
		save = function(_self)
			return Sift.Array.map(conditionList, function(condition)
				return condition:save()
			end)
		end,
		load = function(_self, data)
			for index, save in data do
				conditionList[index]:load(save)
			end
		end,
		process = function(_self, ...)
			for _, condition in conditionList do
				Badger.processFiltered(condition, ...)
			end
		end,
		reset = function(_self)
			for _, condition in conditionList do
				condition:reset()
			end
		end,
		isComplete = function(_self)
			for _, condition in conditionList do
				if condition:isComplete() then return true end
			end
			return false
		end,
		getFilter = function(_self)
			return Sift.Set.merge(table.unpack(Sift.Array.map(conditionList, function(condition)
				return condition:getFilter()
			end)))
		end,
		getState = function(_self)
			return Sift.Array.map(conditionList, function(condition)
				return condition:getState()
			end)
		end,
	})
end

function Badger.with(condition: Condition, prerequisite: Condition): Condition
	return Badger.create({
		save = function(_self)
			return { condition:save(), prerequisite:save() }
		end,
		load = function(_self, data)
			condition:load(data[1])
			prerequisite:load(data[2])
		end,
		getFilter = function(_self)
			return Sift.Set.merge(condition:getFilter(), prerequisite:getFilter())
		end,
		process = function(_self, ...)
			if prerequisite:isComplete() then
				condition:process(...)
			else
				prerequisite:process(...)
			end
		end,
		reset = function(_self)
			condition:reset()
			prerequisite:reset()
		end,
		isComplete = function(_self)
			return prerequisite:isComplete() and condition:isComplete()
		end,
	})
end

function Badger.onCompleted(condition: Condition, callback: (Condition) -> ()): Condition
	local wrapped
	wrapped = Badger.wrap(condition, {
		process = function(_self, ...)
			condition:process(...)
			if condition:isComplete() then callback(wrapped) end
		end,
		load = function(_self, ...)
			condition:load(...)
			if condition:isComplete() then callback(wrapped) end
		end,
	})
	return wrapped
end

function Badger.without(condition: Condition, prerequisite: Condition): Condition
	return Badger.create({
		save = function(_self)
			return { condition:save(), prerequisite:save() }
		end,
		load = function(_self, data)
			condition:load(data[1])
			prerequisite:load(data[2])
		end,
		getFilter = function(_self)
			return Sift.Set.merge(condition:getFilter(), prerequisite:getFilter())
		end,
		process = function(self, ...)
			prerequisite:process(...)
			if prerequisite:isComplete() then
				self:reset()
			else
				condition:process(...)
			end
		end,
		reset = function(_self)
			condition:reset()
			prerequisite:reset()
		end,
		isComplete = function(_self)
			return condition:isComplete()
		end,
	})
end

function Badger.start(condition: Condition)
	for eventKind in condition:getFilter() do
		getListenerSet(eventKind)[condition] = true
	end

	return condition
end

function Badger.stop(condition: Condition)
	for eventKind in condition:getFilter() do
		getListenerSet(eventKind)[condition] = nil
	end

	return condition
end

return Badger

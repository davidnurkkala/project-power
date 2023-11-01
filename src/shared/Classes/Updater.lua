local RunService = game:GetService("RunService")

export type Updateable = {
	update: (Updateable, number) -> (),
}

local Updater = {}
Updater.__index = Updater

function Updater.new(): {
	add: (any, Updateable) -> (),
}
	local self = setmetatable({
		_connection = nil,
		_objects = {},
		_objectCount = 0,
	}, Updater)
	return self
end

function Updater:add(object: Updateable)
	table.insert(self._objects, object)
	self._objectCount += 1

	if not self._connection then self._connection = RunService.Heartbeat:Connect(function(dt)
		self:_update(dt)
	end) end
end

function Updater:remove(object)
	local index = table.find(self._objects, object)
	if not index then return end

	self:_removeIndex(index)
end

function Updater:_removeIndex(index)
	table.remove(self._objects, index)
	self._objectCount -= 1

	if self._objectCount == 0 then
		self._connection:Disconnect()
		self._connection = nil
	end
end

function Updater:_update(dt)
	for index = self._objectCount, 1, -1 do
		local object: Updateable = self._objects[index]
		object:update(dt)
	end
end

function Updater:destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

return Updater

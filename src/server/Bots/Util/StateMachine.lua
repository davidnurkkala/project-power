local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sift = require(ReplicatedStorage.Packages.Sift)
local StateMachine = {}
StateMachine.__index = StateMachine

export type StateChange = string | { name: string, [string]: any }

export type State = {
	onEntered: ((state: State, previousState: State?, StateChange) -> ())?,
	onUpdated: (state: State, dt: number) -> StateChange?,
	onWillLeave: ((state: State, nextState: State?) -> ())?,
	[string]: any,
}

function StateMachine.new(states: { [string]: State })
	local self = setmetatable({
		_currentState = nil,
		_states = Sift.Dictionary.map(Sift.Dictionary.copyDeep(states), function(state, name)
			return Sift.Dictionary.set(state, "name", name)
		end),
		_active = true,
	}, StateMachine)

	return self
end

function StateMachine:start(stateName: string)
	assert(self._states[stateName], `No state {stateName}`)

	task.spawn(function()
		self:setCurrentState(stateName)

		local dt = 0
		while self._active do
			self:_update(dt)
			dt = task.wait()
		end
	end)

	return self
end

function StateMachine:setCurrentState(stateChange: StateChange)
	local stateName = if typeof(stateChange) == "table" then stateChange.name else stateChange

	local previousState = self._currentState
	local nextState = self._states[stateName]

	if previousState and previousState.onWillLeave then previousState:onWillLeave(nextState) end

	self._currentState = nextState

	if nextState.onEntered then nextState:onEntered(previousState, stateChange) end
end

function StateMachine:_update(dt: number)
	local stateChange = self._currentState:onUpdated(dt)
	if stateChange then self:setCurrentState(stateChange) end
end

function StateMachine:destroy()
	if self._currentState.onWillLeave then self._currentState:onWillLeave() end

	self._active = false
end

return StateMachine

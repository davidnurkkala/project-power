local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BattleController = require(ReplicatedStorage.Shared.Controllers.BattleController)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SilenceHelper = require(ReplicatedStorage.Shared.Util.SilenceHelper)
local StunController = require(ReplicatedStorage.Shared.Controllers.StunController)
local StunHelper = require(ReplicatedStorage.Shared.Util.StunHelper)
local TauntController = require(ReplicatedStorage.Shared.Controllers.TauntController)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)

-- type defs
type Action = "attack" | "special" | "dash" | "taunt"
type ActionStates = {
	[Action]: boolean,
}

local BINDINGS: { [Action]: Enum.KeyCode | Enum.UserInputType } = {
	attack = Enum.UserInputType.MouseButton1,
	special = Enum.KeyCode.R,
	dash = Enum.KeyCode.Q,
	taunt = Enum.KeyCode.T,
}

local ActionController = {}
ActionController.className = "ActionController"
ActionController.priority = 0

ActionController.actionStarted = Signal.new()
ActionController.actionStopped = Signal.new()

function ActionController:init()
	self._trove = Trove.new()
	self._actionStates = {
		attack = false,
		special = false,
		dash = false,
	} :: ActionStates
end

function ActionController:start()
	BattleController.inBattleChanged:Connect(function(isInBattle: boolean)
		if isInBattle then
			self:_setupBattleActions()
		else
			self._trove:Clean()
		end
	end)
end

function ActionController:_attack()
	if StunHelper.isStunned(Players.LocalPlayer) then return end

	WeaponController:attack()
end

function ActionController:_special()
	if StunHelper.isStunned(Players.LocalPlayer) then return end
	if SilenceHelper.isSilenced(Players.LocalPlayer) then return end

	WeaponController:special()
end

function ActionController:_dash()
	if StunHelper.isStunned(Players.LocalPlayer) then return end

	WeaponController:dash()
end

function ActionController:handleInputAction(action: Action, inputState: Enum.UserInputState)
	if action == "taunt" then
		if inputState == Enum.UserInputState.Begin then TauntController:taunt() end
		return
	end

	if inputState == Enum.UserInputState.Begin then
		self._actionStates[action] = true
		self.actionStarted:Fire(action)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		self._actionStates[action] = false
		self.actionStopped:Fire(action)
	end
end
function ActionController:_setupBattleActions()
	-- setup action bindings
	for action, binding in BINDINGS do
		ContextActionService:BindAction(action, function(_, inputState)
			ActionController:handleInputAction(action, inputState)
		end, false, binding)

		self._trove:Add(function()
			ContextActionService:UnbindAction(action)
			self._actionStates[action] = false
		end)
	end

	-- on gamestep perform actions if input is active
	self._trove:Add(RunService.Stepped:Connect(function(_, _deltaTime)
		-- go through each action and perform if active
		for action, state in self._actionStates do
			if not state then continue end
			task.spawn(function()
				self["_" .. action](self)
			end)
		end
	end))

	if RunService:IsStudio() then
		ContextActionService:BindAction("DebugRagdoll", function(_, state)
			if state ~= Enum.UserInputState.Begin then return end

			StunController.stunned:Fire()
		end, false, Enum.KeyCode.V)

		self._trove:Add(function()
			ContextActionService:UnbindAction("DebugRagdoll")
		end)
	end
end

return Loader:registerSingleton(ActionController)

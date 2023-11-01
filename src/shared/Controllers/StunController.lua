local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local StunController = {}
StunController.className = "StunController"
StunController.priority = 0

StunController.stunned = Signal.new()

function StunController:init() end

function StunController:start()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "StunService")
	self._comm:GetSignal("RagdollRequested"):Connect(function(...)
		self:_onRagdollRequested(...)
	end)
	self._comm:GetSignal("PushbackRequested"):Connect(function(...)
		self:_onPushbackRequested(...)
	end)
end

function StunController:_onPushbackRequested(duration, velocity, modelIn: Model?)
	local player = Players.LocalPlayer
	local char = player.Character

	local model: Model = modelIn or char

	if not model then return end

	local human = model:FindFirstChildWhichIsA("Humanoid")
	if not human then return end

	local root = model.PrimaryPart
	if not root then return end

	local trove = Trove.new()
	local mover = ForcedMovementHelper.register(root)
	trove:Add(mover, "destroy")

	trove:Connect(RunService.Stepped, function()
		mover:update(if velocity.X ~= 0 then velocity.X else nil, if velocity.Y ~= 0 then velocity.Y else nil, if velocity.Z ~= 0 then velocity.Z else nil)
	end)

	task.delay(duration, function()
		trove:Destroy()
	end)
end

function StunController:_onRagdollRequested(isInRagdoll, velocity)
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then return end

	local human = char.Humanoid
	if not human then return end

	local root = char.PrimaryPart
	if not root then return end

	if isInRagdoll then
		self.stunned:Fire()

		human:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		human:ChangeState(Enum.HumanoidStateType.FallingDown)

		root.AssemblyLinearVelocity += velocity
	else
		human:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		human:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

return Loader:registerSingleton(StunController)

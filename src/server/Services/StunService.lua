local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local DamageService = require(ServerScriptService.Server.Services.DamageService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local InBattleHelper = require(ReplicatedStorage.Shared.Util.InBattleHelper)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Promise = require(ReplicatedStorage.Packages.Promise)
local StunHelper = require(ReplicatedStorage.Shared.Util.StunHelper)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local StunService = {}
StunService.className = "StunService"
StunService.priority = 0

type RagdollConstraint = "HingeConstraint" | "BallSocketConstraint"

-- consts

local JOINT_PARAMETERS: { [string]: { any } } = {
	-- i hate r6
	["Right Shoulder"] = { "BallSocketConstraint", "Right", "Up", 90 },
	["Left Shoulder"] = { "BallSocketConstraint", "Left", "Up", 90 },
	["Right Hip"] = { "BallSocketConstraint", "Down", "Right", 20 },
	["Left Hip"] = { "BallSocketConstraint", "Down", "Left", 20 },
	["RootJoint"] = { "BallSocketConstraint", "Right", "Forward", 90 },

	-- i love r15
	Neck = { "BallSocketConstraint", "Up", "Forward", 45 },
	RightShoulder = { "BallSocketConstraint", "Right", "Up", 90 },
	LeftShoulder = { "BallSocketConstraint", "Left", "Up", 90 },
	RightWrist = { "BallSocketConstraint", "Down", "Right", 20 },
	LeftWrist = { "BallSocketConstraint", "Down", "Left", 20 },

	Waist = { "HingeConstraint", "Right", "Up", 90, -90 },

	RightElbow = { "HingeConstraint", "Right", "Down", 135, 0 },
	LeftElbow = { "HingeConstraint", "Left", "Down", 0, -135 },

	RightKnee = { "HingeConstraint", "Right", "Down", 0, -135 },
	LeftKnee = { "HingeConstraint", "Left", "Down", 135, 0 },

	RightHip = { "BallSocketConstraint", "Down", "Right", 20 },
	LeftHip = { "BallSocketConstraint", "Down", "Left", 20 },

	RightAnkle = { "BallSocketConstraint", "Down", "Right", 20 },
	LeftAnkle = { "BallSocketConstraint", "Down", "Left", 20 },

	Root = { "BallSocketConstraint", "Right", "Forward", 90 },
}

local VECTORS_BY_DIRECTION = {
	Up = Vector3.new(0, 1, 0),
	Down = Vector3.new(0, -1, 0),
	Left = Vector3.new(-1, 0, 0),
	Right = Vector3.new(1, 0, 0),
	Forward = Vector3.new(0, 0, -1),
	Back = Vector3.new(0, 0, 1),
}

local function makeAttachment(parent, position, primaryAxisDirection, secondaryAxisDirection)
	local attachment = Instance.new("Attachment")
	attachment.Axis = VECTORS_BY_DIRECTION[primaryAxisDirection]
	attachment.SecondaryAxis = VECTORS_BY_DIRECTION[secondaryAxisDirection]
	attachment.Position = position
	attachment.Parent = parent

	return attachment
end

local function makeConstraint(
	character: Model,
	joint: Motor6D,
	constraintType: RagdollConstraint,
	primaryAxisDirection: string,
	secondaryAxisDirection: string,
	upperAngle: number,
	lowerAngle: number?
): { Instance }
	local constraint = Instance.new(constraintType)
	constraint.Attachment0 = makeAttachment(joint.Part0, joint.C0.Position, primaryAxisDirection, secondaryAxisDirection)
	constraint.Attachment1 = makeAttachment(joint.Part1, joint.C1.Position, primaryAxisDirection, secondaryAxisDirection)
	constraint.LimitsEnabled = true
	constraint.UpperAngle = upperAngle
	if constraint:IsA("HingeConstraint") then constraint.LowerAngle = lowerAngle end
	constraint.Parent = character

	return { constraint, constraint.Attachment0, constraint.Attachment1 }
end

function StunService:init() end

function StunService:start()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "StunService")

	self._ragdollRequested = self._comm:CreateSignal("RagdollRequested")
	self._pushbackRequested = self._comm:CreateSignal("PushbackRequested")
end

function StunService:ragdollModel(model: Model, velocity: Vector3): () -> ()
	local trove = Trove.new()

	local root = model.PrimaryPart
	local player = Players:GetPlayerFromCharacter(model)

	if player then
		self._ragdollRequested:Fire(player, true, velocity)
		trove:Add(function()
			self._ragdollRequested:Fire(player, false)
		end)
	else
		if root then
			root.AssemblyLinearVelocity += velocity
		end
	end

	if velocity.Magnitude > 0 then
		local smoke = ReplicatedStorage.Assets.Emitters.SmokeTrail:Clone()
		smoke.Parent = root
		trove:Add(function()
			smoke.Enabled = false
			task.delay(smoke.Lifetime.Max, smoke.Destroy, smoke)
		end)

		local human = model:FindFirstChildWhichIsA("Humanoid")
		if human then
			local hitLimiter = HitLimiter.new(5)
			trove:Add(hitLimiter, "destroy")

			trove:Connect(human.Touched, function(otherPart)
				local target = WeaponUtil.findDamageTarget(otherPart)
				if not target then return end
				if not target:IsA("Model") then return end
				if hitLimiter:limitTarget(target) then return end

				EffectService:effect("sound", {
					position = root.Position,
					name = target:GetAttribute("RagdollBreakSoundName") or "RagdollImpact1",
				})

				DamageService:damage({
					source = human,
					target = target,
					amount = 100,
				})
			end)
		end
	end

	for _, object in model:GetDescendants() do
		if object:IsA("Motor6D") then
			if object.Part0 == model.PrimaryPart then continue end

			local jointStuff = JOINT_PARAMETERS[object.Name]
			if not jointStuff then continue end

			local constraintStuff = makeConstraint(model, object, unpack(jointStuff))
			for _, instance in constraintStuff do
				trove:Add(instance)
			end

			object.Enabled = false
			trove:Add(function()
				object.Enabled = true
			end)
		elseif (player == nil) and object:IsA("Humanoid") then
			local human = object :: Humanoid
			human:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			human:ChangeState(Enum.HumanoidStateType.FallingDown)
			trove:Add(function()
				human:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				human:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		elseif object:IsA("BasePart") then
			local collisionGroup = object.CollisionGroup
			object.CollisionGroup = "Ragdolls"
			trove:Add(function()
				object.CollisionGroup = collisionGroup
			end)
		end
	end

	if player and model.PrimaryPart then model.PrimaryPart:SetNetworkOwner(player) end

	return function()
		trove:Clean()
	end
end

function StunService:stunTarget(target: StunHelper.StunTarget, duration: number, velocity: Vector3?)
	if StunHelper.isStunned(target) then return end

	local model = StunHelper.getModel(target)
	if not model then return end

	if not InBattleHelper.isModelInBattle(model) then return end

	if StunHelper.isInvincible(target) then return end

	model:SetAttribute(StunHelper.stunAttributeName, true)
	local cleanUp = self:ragdollModel(model, velocity or Vector3.new())

	task.delay(duration, function()
		if not StunHelper.isAlive(target) then return end

		model:SetAttribute(StunHelper.stunAttributeName, nil)
		cleanUp()
	end)
end

function StunService:pushbackTarget(target: StunHelper.StunTarget, duration: number, velocity: Vector3)
	if StunHelper.isStunned(target) then return end

	local model = StunHelper.getModel(target)
	if not model then return end

	if not InBattleHelper.isModelInBattle(model) then return end

	if StunHelper.isInvincible(target) then return end

	model:SetAttribute(StunHelper.pushAttributeName, true)
	task.delay(duration, function()
		model:SetAttribute(StunHelper.pushAttributeName, nil)
	end)

	if target:IsA("Player") then
		-- player will get pushed back
		self._pushbackRequested:Fire(target, duration, velocity)
	else
		-- tell network owner to push target
		local root = model.PrimaryPart
		if not root then return end

		local player = root:GetNetworkOwner()
		if not player then
			-- server owns the model
			root.AssemblyLinearVelocity += velocity
			return
		end

		self._pushbackRequested:Fire(player, duration, velocity, model)
	end
end

return Loader:registerSingleton(StunService)

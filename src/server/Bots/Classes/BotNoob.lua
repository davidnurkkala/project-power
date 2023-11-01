local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BotAnimator = require(ServerScriptService.Server.Bots.Util.BotAnimator)
local BotDash = require(ServerScriptService.Server.Bots.Util.BotDash)
local ChanceOnHeartbeat = require(ServerScriptService.Server.Bots.Util.ChanceOnHeartbeat)
local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DamageService = require(ServerScriptService.Server.Services.DamageService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local FaceTowards = require(ServerScriptService.Server.Bots.Util.FaceTowards)
local FindTarget = require(ServerScriptService.Server.Bots.Util.FindTarget)
local MeleeChasing = require(ServerScriptService.Server.Bots.Util.MeleeChasing)
local Resetting = require(ServerScriptService.Server.Bots.Util.Resetting)
local Signal = require(ReplicatedStorage.Packages.Signal)
local StateMachine = require(ServerScriptService.Server.Bots.Util.StateMachine)
local StunHelper = require(ReplicatedStorage.Shared.Util.StunHelper)
local StunService = require(ServerScriptService.Server.Services.StunService)
local Stunned = require(ServerScriptService.Server.Bots.Util.Stunned)
local WanderIdling = require(ServerScriptService.Server.Bots.Util.WanderIdling)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local ATTACK_RANGE = 6

local BotNoob = {}
BotNoob.__index = BotNoob

function BotNoob.new(args: {
	cframe: CFrame,
	maxHealth: number?,
	damageMultiplier: number?,
})
	local model = ReplicatedStorage.Assets.NonPlayers["Noob Bot"]:Clone()
	model:PivotTo(args.cframe)

	local self = setmetatable({
		destroyed = Signal.new(),

		_model = model,
		_human = model.Humanoid,
		_root = model.HumanoidRootPart,
		_attackCooldown = Cooldown.new(0.5),
		_specialCooldown = Cooldown.new(10),
		_punchRight = true,
	}, BotNoob)

	self._animator = BotAnimator.new(self._human)

	self._targetFilter = function(target)
		return target ~= self._human
	end

	CollectionService:AddTag(self._human, "NonPlayer")
	self._human.Died:Connect(function()
		self:destroy(true)
		task.delay(5, function()
			self._model:Destroy()
		end)
	end)

	self._model.Parent = workspace
	self._root:SetNetworkOwner(nil)

	self._stateMachine = StateMachine.new({
		stunned = Stunned({ root = self._root, model = self._model, animator = self._animator }),
		idling = WanderIdling({
			visionPart = self._model.Head,
			human = self._human,
			animator = self._animator,
			onIdling = function()
				self._target = FindTarget(self._model.Head.Position, 40)
				if self._target then return "chasing" end

				return
			end,
		}),
		resetting = Resetting(self._model, self._root, args.cframe),
		attacking = {
			onUpdated = function()
				if not self._target:isAlive() then
					self._target = nil
					return "idling"
				end

				if not self._target:isInRange(self:getPosition(), ATTACK_RANGE) then
					self._target = nil
					return "idling"
				end

				FaceTowards(self._root, self._target:getPosition())
				self:_tryAttacking()

				return
			end,
		},
		chasing = MeleeChasing({
			bot = self,
			attackRange = ATTACK_RANGE,
			human = self._human,
			animator = self._animator,
			visionParts = { self._model.Head, self._root },
			getTarget = function()
				return self._target
			end,
			clearTarget = function()
				self._target = nil
			end,
			onChasing = function()
				if ChanceOnHeartbeat(4) then BotDash({
					animator = self._animator,
					root = self._root,
				}) end
			end,
		}),
	}):start("idling")

	StunHelper.observeStunnedOrPushed(self._model, function()
		self._stateMachine:setCurrentState("stunned")
	end)

	return self
end

function BotNoob:_tryAttacking()
	if self._specialCooldown:isReady() and ChanceOnHeartbeat(2) then
		self:_special()
		return
	end

	if self._attackCooldown:isReady() then
		self:_attack()
		return
	end
end

function BotNoob:_special()
	if not self._specialCooldown:isReady() then return end

	local root = self._root

	root.AssemblyLinearVelocity += Vector3.new(0, 80, 0)

	self._animator:play("FistsUppercut")

	local rotation = CFrame.Angles(math.pi / 2, 0, 0)
	EffectService:effect("punch", {
		width = 6,
		length = 12,
		duration = 0.2,
		startOffset = CFrame.new(0, -3, -1) * rotation,
		endOffset = CFrame.new(0, 2, -1) * rotation,
		root = root,
	})

	EffectService:effect("sound", { parent = root, name = "Swish1" })

	local launchCFrame = root.CFrame * CFrame.Angles(math.rad(60), 0, 0)

	WeaponUtil.hitboxLingering({
		hitbox = function()
			return WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(6, 12, 6),
				filter = self._targetFilter,
			})
		end,
		callback = function(target)
			EffectService:effect("hitEffect", {
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "Copyrighted",
			})

			DamageService:damage({
				source = self._human,
				target = target,
				amount = 20,
			})

			StunService:stunTarget(target, 1, launchCFrame.LookVector * 384)
		end,
	})

	self._specialCooldown:use()
	self._attackCooldown:use(0.5)
end

function BotNoob:_attack()
	if not self._attackCooldown:isReady() then return end

	local root = self._root

	self._animator:stopHard("FistsPunchRight", 0)
	self._animator:stopHard("FistsPunchLeft", 0)

	self._animator:play(if self._punchRight then "FistsPunchRight" else "FistsPunchLeft", 0)
	local dx = if self._punchRight then 1 else -1
	self._punchRight = not self._punchRight

	EffectService:effect("punch", {
		width = 4,
		length = 8,
		duration = 0.1,
		startOffset = CFrame.new(dx, -0.5, 2),
		endOffset = CFrame.new(dx, -0.5, -2),
		root = root,
	})

	EffectService:effect("sound", { parent = root, name = "Swish1" })

	WeaponUtil.hitboxLingering({
		hitbox = function()
			return WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(4, 4, 8),
				filter = self._targetFilter,
			})
		end,
		callback = function(target)
			EffectService:effect("hitEffect", {
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "Hit1",
			})

			DamageService:damage({
				source = self._human,
				target = target,
				amount = 10,
			})
		end,
	})

	self._attackCooldown:use()
end

function BotNoob:getPosition()
	return self._model:GetPivot().Position
end

function BotNoob:destroy(preserveModel: boolean?)
	self._stateMachine:destroy()

	if not preserveModel then self._model:Destroy() end

	self.destroyed:Fire()
end

return BotNoob

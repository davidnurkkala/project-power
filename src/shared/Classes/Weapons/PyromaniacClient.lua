local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionController = require(ReplicatedStorage.Shared.Controllers.ActionController)
local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local StunController = require(ReplicatedStorage.Shared.Controllers.StunController)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local FIRE_SEQUENCE = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
	ColorSequenceKeypoint.new(0.6, Color3.new(1, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.new(1, 1, 0)),
})

local PyromaniacClient = {}
PyromaniacClient.__index = PyromaniacClient

function PyromaniacClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_attacks = {
			"PyromaniacAttack1",
			"PyromaniacAttack2",
			"PyromaniacAttack3",
			"PyromaniacAttack4",
		},
		_attackIndex = 0,
		_lastAttackTime = 0,
		_trove = Trove.new(),
	}, PyromaniacClient)

	return self
end

function PyromaniacClient:destroy()
	self._trove:Clean()
end

function PyromaniacClient:equip()
	self._animator = WeaponUtil.createAnimator()

	local char = WeaponUtil.getChar()
	if not char then return end

	self._head = char:FindFirstChild("Head")
	if not self._head then return end

	self._faceCenterAttachment = self._head.FaceCenterAttachment
	self._breathLight = self._faceCenterAttachment.FireBreath

	self._weapon = char.Pyromaniac
end

function PyromaniacClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	-- TODO: create generic input timing object for button mash combos
	local currentTime = tick()
	if currentTime - self._lastAttackTime > 0.7 then
		self._attackIndex = 1
	else
		self._attackIndex = (self._attackIndex % #self._attacks) + 1
	end
	self._lastAttackTime = currentTime

	-- animations
	for _, attackName in self._attacks do
		self._animator:stopHard(attackName)
	end
	self._animator:play(self._attacks[self._attackIndex], 0)

	-- sounds
	EffectController:replicate(EffectUtil.sound({
		parent = root,
		name = "Swish1",
		pitchRange = NumberRange.new(1, 1.1),
	}))
	EffectController:replicate(EffectUtil.sound({
		parent = root,
		name = "BottleSlosh" .. math.random(1, 2),
		pitchRange = NumberRange.new(1, 1.1),
	}))

	-- smears
	if self._attackIndex == 1 then
		local startCF = CFrame.new(-2, -0.5, 2) * CFrame.Angles(0, math.rad(-20), 0)
		EffectController:replicate(EffectUtil.punch({
			width = 5,
			length = self.definition.attackRange + 1,
			duration = 0.2,
			startOffset = startCF,
			endOffset = startCF * CFrame.new(0, 0, -8),
			root = root,
		}))
	elseif self._attackIndex == 2 then
		EffectController:replicate(EffectUtil.slash1({
			radius = self.definition.attackRange,
			duration = 0.2,
			cframe = CFrame.Angles(0, 0, math.rad(10)) * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
			partName = "SlashBash1",
		}))
	elseif self._attackIndex == 3 then
		EffectController:replicate(EffectUtil.slash1({
			radius = self.definition.attackRange,
			duration = 0.2,
			cframe = CFrame.Angles(0, 0, math.rad(-160)) * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
			partName = "SlashBash1",
		}))
	elseif self._attackIndex == 4 then
		EffectController:replicate(EffectUtil.slash1({
			radius = self.definition.attackRange,
			duration = 0.2,
			cframe = CFrame.Angles(0, 0, math.rad(-90)) * CFrame.Angles(0, math.rad(170), 0) * CFrame.Angles(0, 0, math.rad(40)),
			rotation = math.rad(-110),
			root = root,
			partName = "SlashBash1",
		}))
	end

	-- hitbox
	WeaponUtil.hitboxLingering({
		hitbox = function()
			return WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(6, 6, self.definition.attackRange),
			})
		end,

		callback = function(target)
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 1,
				soundName = "PunchHit" .. tostring(math.random(4)),
			}))

			request(target)
		end,
	})

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown(self.definition.attackCooldown)
end

function PyromaniacClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	-- animations
	for _, attackName in self._attacks do
		self._animator:stopHard(attackName)
	end
	self._animator:play("PyromaniacBreathCharge", 0, nil, 1 / self.definition.fireBreathChargeDuration)

	Promise.race({
		WeaponUtil.channelPromise(self.definition.fireBreathChargeDuration):andThenReturn("fireBreath"),
		Promise.fromEvent(ActionController.actionStopped, function(action)
			return action == "special"
		end):andThenReturn("throw"),
	})
		:finally(function()
			self._animator:stopHard("PyromaniacBreathCharge")
		end)
		:andThen(function(move)
			if move == "throw" then
				return self:_throw(request, root)
			elseif move == "fireBreath" then
				-- animations
				self._animator:play("PyromaniacBreathDrink")

				-- effects
				local guid = EffectUtil.guid()
				EffectController:replicate(EffectUtil.emitter({
					parent = self._faceCenterAttachment,
					name = "PyromaniacBreathHold",
					guid = guid,
				}))
				EffectController:replicate(EffectUtil.sound({
					parent = self._head,
					name = "PyromaniacChargeReady",
				}))

				return Promise.race({
					Promise.fromEvent(ActionController.actionStopped, function(action)
						return action == "special"
					end):andThenCall(function()
						self:_fireBreath(request, root)
					end),

					Promise.fromEvent(StunController.stunned):andThenCall(Promise.reject),
				}):finally(function()
					EffectController:cancel(guid)
					self._animator:stopHard("PyromaniacBreathDrink")
				end)
			else
				error(`Unrecognized move {move}`)
			end
		end)
		:catch(function()
			self._specialCooldown:use(self.definition.specialCooldown / 2)
			WeaponController:useGlobalCooldown()
		end)

	WeaponController:useGlobalCooldown(math.huge)
end

function PyromaniacClient:_throw(request, root)
	-- cooldown
	self._specialCooldown:use(self.definition.specialCooldown * self.definition.throwCooldownMultiplier)
	WeaponController:useGlobalCooldown(self.definition.attackCooldown)

	-- animations
	self._animator:play("PipeThrow", 0, nil, 1 / 0.5)
	EffectController:replicate(EffectUtil.sound({
		parent = root,
		name = "PipeThrow",
	}))

	-- projectile
	local here = root.Position
	local there = MouseUtil.raycast().position
	local cframe = CFrame.new(here, there) * CFrame.new(0, 0.5, 0) * CFrame.Angles(math.rad(30), 0, 0)

	local guid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.projectile({
		guid = guid,
		name = "PyromaniacProjectile",
		cframe = cframe,
		speed = 80,
		owner = Players.LocalPlayer,
		gravity = 0.9,

		onTouched = function(part)
			local target = WeaponUtil.findDamageTarget(part)
			if not target then return part.Anchored and part.CanCollide end
			if WeaponUtil.isTargetMe(target) then return false end
			return true
		end,

		onFinished = function(part)
			-- sounds
			EffectController:replicate(EffectUtil.sound({
				parent = self._head,
				name = "BottleBreak" .. math.random(1, 2),
			}))
			EffectController:replicate(EffectUtil.sound({
				parent = self._head,
				name = "BottleBreakFire1",
			}))

			-- effects
			EffectController:replicate(EffectUtil.burst1({
				cframe = CFrame.new(part.Position),
				radius = self.definition.throwRadius,
				duration = 0.3,
				partName = "MolotovBurst",
				power = 0.4,
			}))
			EffectController:replicate(EffectUtil.emitAtCFrame({
				cframe = CFrame.new(part.Position),
				emitterName = "PyromaniacThrowImpact",
				particleCount = 50,
				useAttachment = true,
			}))

			-- hitbox
			local targets = WeaponUtil.hitSphere({
				position = part.Position,
				radius = self.definition.specialRadius,
			})

			for _, target in targets do
				local targetRoot = WeaponUtil.getTargetRoot(target)
				local delta = (targetRoot.Position - cframe.Position)

				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					color = FIRE_SEQUENCE,
				}))

				request("throw", target, delta.Unit)
			end
		end,
	}))
end

function PyromaniacClient:_fireBreath(request, root)
	-- hitbox
	local launchDirection = root.CFrame.LookVector * Vector3.new(1, 0, 1)

	WeaponUtil.hitboxLingering({
		duration = self.definition.fireBreathDuration,

		hitbox = function()
			return WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(9, 8, self.definition.fireBreathRange),
			})
		end,

		callback = function(target)
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 1,
				soundName = "FirePunch" .. tostring(math.random(4)),
			}))

			request("fireBreath", target, launchDirection)
		end,
	})

	-- animations
	self._animator:play("PyromaniacBreathSpit")

	-- sounds
	EffectController:replicate(EffectUtil.sound({
		parent = self._head,
		name = "PyromaniacBreath",
		duration = self.definition.fireBreathDuration,
	}))

	-- effects
	EffectController:replicate(EffectUtil.emitter({
		parent = self._faceCenterAttachment,
		name = "FireBreath1",
		duration = self.definition.fireBreathDuration,
	}))
	EffectController:replicate(EffectUtil.emitter({
		parent = self._faceCenterAttachment,
		name = "FireBreath2",
		duration = self.definition.fireBreathDuration,
	}))
	EffectController:replicate(EffectUtil.flash({
		light = self._breathLight,
		duration = self.definition.fireBreathDuration,
	}))

	task.delay(self.definition.fireBreathDuration, function()
		self._animator:stopHard("PyromaniacBreathSpit")
	end)

	self._specialCooldown:use(self.definition.specialCooldown)
	WeaponController:useGlobalCooldown(self.definition.fireBreathDuration + (self.definition.attackCooldown / 2))
end

return PyromaniacClient

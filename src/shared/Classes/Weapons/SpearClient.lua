local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local SpearClient = {}
SpearClient.__index = SpearClient

function SpearClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_attacks = {
			"SpearAttack1",
			"SpearAttack2",
		},
		_attackIndex = 0,
		_lastAttackTime = 0,
	}, SpearClient)
	return self
end

function SpearClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("SpearIdle")
end

function SpearClient:destroy()
	self._animator:stop("SpearIdle")
end

function SpearClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	for _, attackName in self._attacks do
		self._animator:stopHard(attackName)
	end

	-- Animation
	-- TODO: create generic input timing object for button mash combos
	local currentTime = tick()
	if currentTime - self._lastAttackTime > 1 then
		self._attackIndex = 1
	else
		self._attackIndex = (self._attackIndex % #self._attacks) + 1
	end
	self._lastAttackTime = currentTime
	self._animator:play(self._attacks[self._attackIndex], 0)

	-- Attack
	WeaponUtil.hitboxLingering({
		hitbox = function()
			return WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(7, 7, self.definition.attackRange),
			})
		end,
		callback = function(target)
			-- Hit effect
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "BigSwordHit" .. math.random(1, 3),
			}))
			request(target)
		end,
	})

	-- Effects
	task.delay(0.05, function()
		EffectController:replicate(EffectUtil.punch({
			width = 7,
			length = self.definition.attackRange + 8,
			duration = 0.15,
			startOffset = CFrame.new(1.5, -1, 2),
			endOffset = CFrame.new(1.5, -1, -4),
			root = root,
			color = Color3.fromRGB(255, 255, 255),
		}))

		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "Whoosh1",
			pitchRange = NumberRange.new(1, 1.02),
		}))
	end)

	-- Cooldowns
	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function SpearClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	-- Animation
	self._animator:play("SpearSpinCharge", 0, nil, 1 / self.definition.specialChargeDuration)

	-- Effects
	EffectController:replicate(EffectUtil.emit({
		emitter = root.SpearEmitter.SpearSpecialAlert,
		particleCount = 1,
	}))
	EffectController:replicate(EffectUtil.sound({
		name = "SpearSpecial",
		parent = root,
		pitchRange = NumberRange.new(1.04),
	}))

	-- Promise
	WeaponUtil.channelPromise(self.definition.specialChargeDuration)
		:andThen(function()
			-- Hitbox
			WeaponUtil.hitboxLingering({
				hitbox = function()
					return WeaponUtil.hitSphere({
						position = root.Position,
						radius = self.definition.specialRadius,
					})
				end,
				callback = function(target)
					EffectController:replicate(EffectUtil.hitEffect({
						part = WeaponUtil.getTargetRoot(target),
						emitterName = "Impact1",
						particleCount = 2,
						soundName = "BigSwordHit" .. math.random(1, 3), -- TODO: unique sound
					}))

					local targetRoot = WeaponUtil.getTargetRoot(target)
					if not targetRoot then return end

					local delta = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)

					request({
						target = target,
						direction = delta.Unit,
					})
				end,
			})

			local trove = Trove.new()
			local mover = ForcedMovementHelper.register(root)
			trove:Add(mover, "destroy")

			local direction = root.CFrame.LookVector
			local start = tick()
			trove:Add(RunService.Stepped:Connect(function(_, _deltaTime)
				if not root or tick() - start > 0.25 then
					trove:Clean()
					return
				end
				mover:update(direction.X * -45, nil, direction.Z * -35)
			end))

			-- Effects
			-- spin animation
			self._animator:stopHard("SpearSpinCharge")
			self._animator:play("SpearSpin", 0, nil, 1 / 0.85)

			-- spin smear effect
			task.delay(0.03, function()
				EffectController:replicate(EffectUtil.slash1({
					radius = self.definition.specialRadius + 1,
					duration = 0.3,
					cframe = CFrame.new(0, -1, 0) * CFrame.Angles(0, math.rad(45), 0) * CFrame.Angles(math.rad(180), 0, 0),
					rotation = math.rad(360),
					root = root,
					partName = "Slash2",
					color = Color3.fromRGB(255, 255, 255),
				}))
			end)

			-- Spin sound
			EffectController:replicate(EffectUtil.sound({
				name = "SpearSpecialSwing",
				parent = root,
				pitchRange = NumberRange.new(1, 1.02),
			}))
			EffectController:replicate(EffectUtil.sound({
				name = "Whoosh1",
				parent = root,
				pitchRange = NumberRange.new(0.98, 1.02),
			}))
		end)
		:catch(function()
			self._animator:stopHard("SpearSpinCharge")
		end)

	-- Cooldowns
	WeaponController:useGlobalCooldown(self.definition.specialChargeDuration + 0.1)
	self._specialCooldown:use()
end

return SpearClient

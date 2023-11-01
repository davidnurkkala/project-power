local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local ProjectileHelper = require(ReplicatedStorage.Shared.Util.ProjectileHelper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local PaddleClient = {}
PaddleClient.__index = PaddleClient

function PaddleClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_attackCount = 2,
		_attackIndex = 0,
	}, PaddleClient)
	return self
end

function PaddleClient:destroy()
	self._tilter:destroy()
end

function PaddleClient:equip()
	self._animator = WeaponUtil.createAnimator()
	self._tilter = WeaponUtil.createWaistTilter()

	local char = WeaponUtil.getChar()
	if not char then return end

	local weapon = char.Paddle
	self._paddle = weapon.Paddle
	self._ball = weapon.Ball
end

function PaddleClient:_shoot(request, char)
	local here = self._paddle.Position
	local there = MouseUtil.raycast().position
	local cframe = CFrame.lookAt(here, there)

	local guid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.projectile({
		guid = guid,
		name = "PingPongBall",
		cframe = cframe,
		speed = 160,
		owner = Players.LocalPlayer,
		gravity = 0.01,
		lifetime = 2,

		onTouched = function(part)
			local target = WeaponUtil.findDamageTarget(part)
			if not target then return ProjectileHelper.isProjectileCollidable(part) end
			if target:IsDescendantOf(char) then return false end

			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "PingPongHit1",
			}))

			request(target)

			return true
		end,
		onFinished = function(part)
			EffectController:replicate(EffectUtil.sound({
				position = part.Position,
				name = "PingPongImpact" .. math.random(1, 2),
			}))
		end,
	}))
end

function PaddleClient:attack(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	if not self._attackCooldown:isReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._attackIndex = (self._attackIndex % self._attackCount) + 1

	-- chargeup
	self._animator:play(`PaddleAttack{self._attackIndex}Charge`, 0, nil, 1 / self.definition.attackChargeDuration)

	local preHitTime = 4 / 60
	local chargeDuration = self.definition.attackChargeDuration - preHitTime

	WeaponUtil.channelPromise(chargeDuration)
		:finally(function()
			self._animator:stopHard(`PaddleAttack{self._attackIndex}Charge`, self._attackIndex)
		end)
		:andThen(function()
			-- animations
			self._animator:play(`PaddleAttack{self._attackIndex}Swing`, 0)

			-- sounds
			EffectController:replicate(EffectUtil.sound({
				name = "PaddleSwish1",
				parent = root,
				pitchRange = NumberRange.new(1, 1.08),
			}))

			return WeaponUtil.channelPromise(preHitTime)
				:andThen(function()
					-- hitbox
					self:_shoot(request, char)

					-- sounds
					EffectController:replicate(EffectUtil.sound({
						name = "PaddleAttack" .. math.random(1, 3),
						parent = root,
						pitchRange = NumberRange.new(1, 1.05),
					}))
				end)
				:catch(function() end)
		end)
		:catch(function() end)

	WeaponController:useGlobalCooldown(self.definition.attackChargeDuration + self.definition.attackCooldown)
	self._attackCooldown:use()
end

function PaddleClient:special(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	if not self._specialCooldown:isReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 8
	local cframe = CFrame.Angles(0, 0, math.rad(160))

	-- animations
	self._animator:stopHard(`PaddleAttack{self._attackIndex}Swing`)
	self._animator:play("BatHomerunCharge", 0)

	-- increase paddle size
	local sizeGuid = HttpService:GenerateGUID(false)
	EffectController:replicate(EffectUtil.paddleSpecial({
		guid = sizeGuid,
		paddle = self._paddle,
	}))

	-- disable waist tilter
	self._tilter:pause()

	WeaponUtil.channelPromise(self.definition.specialChargeDuration)
		:finally(function()
			self._animator:stopHard("BatHomerunCharge")
			Promise.delay(self.definition.specialChargeDuration + 0.2):andThen(function()
				self._tilter:setPaused(false)
			end)
		end)
		:andThen(function()
			local launchCFrame = root.CFrame * CFrame.Angles(math.rad(50), 0, 0)

			-- Hitbox
			WeaponUtil.hitboxLingering({
				hitbox = function()
					return WeaponUtil.hitboxMelee({
						root = root,
						size = Vector3.new(radius, 12, radius),
					})
				end,
				callback = function(target)
					local targetRoot = WeaponUtil.getTargetRoot(target)

					EffectController:replicate(EffectUtil.hitEffect({
						part = WeaponUtil.getTargetRoot(target),
						emitterName = "Impact1",
						particleCount = 1,
						soundName = "BatHit",
					}))

					if targetRoot then
						EffectController:replicate(EffectUtil.emitAtCFrame({
							emitterName = "BatSpecialShine",
							particleCount = 1,
							cframe = CFrame.new(targetRoot.Position),
						}))
					end

					request(target, launchCFrame.LookVector)
				end,
			})

			-- animations
			self._animator:play("BatHomerunSwing", 0)

			-- sounds
			EffectController:replicate(EffectUtil.sound({
				name = "Whoosh1",
				parent = root,
			}))

			-- smear
			EffectController:replicate(EffectUtil.slash1({
				radius = radius,
				duration = 0.2,
				cframe = cframe * CFrame.Angles(0, math.rad(-130), 0),
				rotation = math.rad(-180),
				root = root,
				partName = "SlashBash1",
			}))
		end)
		:catch(function()
			EffectController:cancel(sizeGuid)
		end)

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(self.definition.specialChargeDuration + 0.2)
end

return PaddleClient

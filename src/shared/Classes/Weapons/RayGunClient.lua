local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local ProjectileHelper = require(ReplicatedStorage.Shared.Util.ProjectileHelper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local RayGunClient = {}
RayGunClient.__index = RayGunClient

function RayGunClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, RayGunClient)
	return self
end

function RayGunClient:destroy()
	self._tilter:destroy()
end

function RayGunClient:equip()
	self._animator = WeaponUtil.createAnimator()
	self._animator:play("RayGunIdle")

	self._tilter = WeaponUtil.createWaistTilter()
end

function RayGunClient:attack(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	if not self._attackCooldown:isReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local chargeDuration = 0.5

	self._animator:play("RayGunCharge", 0)

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid,
		parent = root,
		name = "RayGunCharge1",
	}))

	local emitterGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.enable({
		guid = emitterGuid,
		object = char.RayGun.Tip.Effects.ChargeEmitter,
	}))

	local function shoot()
		self._animator:play("RayGunFire", 0)

		EffectController:replicate(EffectUtil.emit({
			emitter = char.RayGun.Tip.Effects.FireEmitter,
			particleCount = 4,
		}))

		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "RayGunShot2",
		}))

		local here = char.RayGun.Tip.Position
		local there = MouseUtil.raycast().position
		local cframe = CFrame.lookAt(here, there)

		local guid = EffectUtil.guid()
		EffectController:replicate(EffectUtil.projectile({
			guid = guid,
			name = "RayGunProjectile",
			cframe = cframe,
			speed = 128,
			owner = Players.LocalPlayer,
			gravity = 0.01,
			onTouched = function(part)
				local target = WeaponUtil.findDamageTarget(part)
				if not target then return ProjectileHelper.isProjectileCollidable(part) end
				if target:IsDescendantOf(char) then return false end

				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					color = Color3.new(0, 1, 0),
				}))

				request(target)

				return true
			end,
			onFinished = function(part)
				EffectController:replicate(EffectUtil.sound({
					position = part.Position,
					name = "LaserHit1",
				}))
			end,
		}))
	end

	WeaponUtil.channelPromise(chargeDuration)
		:finally(function()
			EffectController:cancel(soundGuid)
			EffectController:cancel(emitterGuid)
			self._animator:stopHard("RayGunCharge")
		end)
		:andThen(function()
			for _ = 1, 3 do
				shoot()
				if WeaponUtil.channelPromise(0.15):awaitStatus() == Promise.Status.Rejected then return Promise.resolve() end
			end
			return Promise.resolve()
		end)
		:catch(function() end)

	WeaponController:useGlobalCooldown(chargeDuration + 0.1)
	self._attackCooldown:use()
end

function RayGunClient:special(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	if not self._specialCooldown:isReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local chargeDuration = 1
	local radius = 14

	self._animator:play("RayGunCharge", 0)

	local soundGuid1 = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid1,
		parent = root,
		name = "RayGunCharge1",
	}))

	local soundGuid2 = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid2,
		parent = root,
		name = "RayGunHeavyLoad1",
	}))

	local emitterGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.enable({
		guid = emitterGuid,
		object = char.RayGun.Tip.Effects.ChargeEmitter,
	}))

	WeaponUtil.channel({
		duration = chargeDuration,
		onFinished = function(success)
			EffectController:cancel(soundGuid1)
			EffectController:cancel(soundGuid2)
			EffectController:cancel(emitterGuid)
			self._animator:stopHard("RayGunCharge")

			if success then
				self._animator:play("RayGunFire", 0)

				EffectController:replicate(EffectUtil.emit({
					emitter = char.RayGun.Tip.Effects.FireEmitter,
					particleCount = 4,
				}))

				EffectController:replicate(EffectUtil.sound({
					parent = root,
					name = "RayGunHeavyFire1",
				}))

				local here = char.RayGun.Tip.Position
				local there = MouseUtil.raycast().position
				local cframe = CFrame.lookAt(here, there)

				local guid = EffectUtil.guid()
				EffectController:replicate(EffectUtil.projectile({
					guid = guid,
					name = "RayGunProjectileHeavy",
					cframe = cframe,
					speed = 48,
					owner = Players.LocalPlayer,
					gravity = 0.05,
					onTouched = function(part)
						local target = WeaponUtil.findDamageTarget(part)
						if not target then return part.Anchored and part.CanCollide end
						if WeaponUtil.isTargetMe(target) then return false end
						return true
					end,
					onFinished = function(part)
						EffectController:replicate(EffectUtil.sound({
							position = part.Position,
							name = "RayGunHeavyExplode1",
						}))

						EffectController:replicate(EffectUtil.burst1({
							cframe = CFrame.new(part.Position),
							radius = radius,
							duration = 0.5,
							partName = "BurstGreenHexGrid1",
							power = 0.4,
						}))

						local targets = WeaponUtil.hitSphere({
							position = part.Position,
							radius = radius,
							filter = function()
								return true
							end,
						})

						local victims = {}

						for _, target in targets do
							local targetRoot = WeaponUtil.getTargetRoot(target)
							local delta = (targetRoot.Position - cframe.Position)

							if WeaponUtil.isTargetMe(target) then
								WeaponController:customRemote("SelfDamage")
								WeaponUtil.forceJump():andThen(function()
									local velocity = delta.Unit * 128
									ForcedMovementHelper.instant(root, velocity.X, velocity.Y, velocity.Z)
								end)
								continue
							end

							EffectController:replicate(EffectUtil.hitEffect({
								part = WeaponUtil.getTargetRoot(target),
								emitterName = "Impact1",
								particleCount = 2,
								color = Color3.new(0, 1, 0),
							}))

							table.insert(victims, {
								target = target,
								direction = delta.Unit,
							})
						end

						request(victims)
					end,
				}))
			end
		end,
	})

	WeaponController:useGlobalCooldown(chargeDuration + 0.1)
	self._specialCooldown:use()
end

return RayGunClient

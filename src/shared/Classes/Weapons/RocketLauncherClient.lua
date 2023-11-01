local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local ForcedRotationHelper = require(ReplicatedStorage.Shared.Util.ForcedRotationHelper)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local ProjectileHelper = require(ReplicatedStorage.Shared.Util.ProjectileHelper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local RocketLauncherClient = {}
RocketLauncherClient.__index = RocketLauncherClient

function RocketLauncherClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, RocketLauncherClient)
	return self
end

function RocketLauncherClient:destroy()
	self._animator:stop("RocketLauncherIdle")
	self._tilter:destroy()
end

function RocketLauncherClient:equip()
	self._animator = WeaponUtil.createAnimator()
	self._animator:play("RocketLauncherIdle")

	self._tilter = WeaponUtil.createWaistTilter()
end

function RocketLauncherClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._animator:play("RocketLauncherShoot", 0)

	local weapon = char.RocketLauncher.Weapon

	EffectController:replicate(EffectUtil.emit({
		emitter = weapon.Rear.Emitter,
		particleCount = 4,
	}))

	EffectController:replicate(EffectUtil.flash({
		light = weapon.Rear.Light,
		duration = 0.5,
		smooth = true,
	}))

	EffectController:replicate(EffectUtil.sound({
		parent = root,
		name = "RocketLaunch" .. math.random(1, 3),
	}))

	local here = weapon.Tip.WorldPosition
	local there = MouseUtil.raycast().position
	local cframe = CFrame.lookAt(here, there)

	local guid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.projectile({
		guid = guid,
		name = "RocketProjectile",
		cframe = cframe,
		speed = 64,
		owner = Players.LocalPlayer,
		gravity = 0.1,
		onTouched = function(part)
			local target = WeaponUtil.findDamageTarget(part)
			if not target then
				return ProjectileHelper.isProjectileCollidable(part)
			else
				return not target:IsDescendantOf(char)
			end
		end,
		onFinished = function(part)
			local position = part.Position
			local radius = 10

			EffectController:replicate(EffectUtil.sound({
				position = position,
				name = "RocketExplosion" .. math.random(1, 3),
			}))

			EffectController:replicate(EffectUtil.burst1({
				cframe = EffectUtil.randomSpin(position),
				radius = radius,
				duration = 0.5,
				partName = "BurstFire1",
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
				local delta = (targetRoot.Position - position)

				if WeaponUtil.isTargetMe(target) then
					WeaponController:customRemote("SelfDamage")
					WeaponUtil.forceJump():andThen(function()
						local velocity = delta.Unit * 128
						ForcedMovementHelper.instant(root, velocity.X, velocity.Y, velocity.Z)
					end)
					continue
				end

				EffectController:replicate(EffectUtil.hitEffect({
					part = targetRoot,
					emitterName = "Impact1",
					particleCount = 2,
				}))

				table.insert(victims, {
					target = target,
					direction = delta.Unit,
				})
			end

			request(victims)
		end,
	}))

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function RocketLauncherClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local human = WeaponUtil.getHuman()
	if not human then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local weapon = char.RocketLauncher.Weapon

	local trove = Trove.new()

	local emitterGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.enable({
		guid = emitterGuid,
		object = weapon.Rear.Emitter,
	}))
	trove:Add(function()
		EffectController:cancel(emitterGuid)
	end)

	local lightGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.enable({
		guid = lightGuid,
		object = weapon.Rear.Light,
	}))
	trove:Add(function()
		EffectController:cancel(lightGuid)
		EffectController:replicate(EffectUtil.flash({
			light = weapon.Rear.Light,
			duration = 0.5,
			smooth = true,
		}))
	end)

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid,
		parent = root,
		name = "RocketLoop1",
		duration = self.definition.specialDuration,
	}))
	trove:Add(function()
		EffectController:cancel(soundGuid)
	end)

	self._animator:play("RocketLauncherSelfLaunch", 0)
	trove:Add(function()
		self._animator:stop("RocketLauncherSelfLaunch")
	end)

	local direction = self._tilter:getCFrame().LookVector
	local speed = 0
	local acceleration = 128

	local mover = ForcedMovementHelper.register(root)
	trove:Add(mover, "destroy")

	local rotator = ForcedRotationHelper.register(root, human)
	trove:Add(rotator, "destroy")

	trove:Connect(RunService.Heartbeat, function()
		rotator:update(CFrame.lookAt(root.Position, root.Position + direction))
	end)

	trove:Connect(RunService.Stepped, function(_, dt)
		mover:update(direction.X * speed, direction.Y * speed, direction.Z * speed)
		speed += acceleration * dt

		WeaponController:useGlobalCooldown()
	end)

	trove:Add(self._tilter:pause())
	trove:Add(DashController:disable())

	local function explode()
		local position = root.Position
		local radius = 16

		for number = 1, 3 do
			EffectController:replicate(EffectUtil.sound({
				position = position,
				name = "RocketExplosion" .. number,
			}))
		end

		EffectController:replicate(EffectUtil.burst1({
			cframe = EffectUtil.randomSpin(position),
			radius = radius,
			duration = 0.5,
			partName = "BurstFire1",
			power = 0.4,
		}))

		local targets = WeaponUtil.hitSphere({
			position = root.Position,
			radius = radius,
		})

		local victims = {}

		for _, target in targets do
			local targetRoot = WeaponUtil.getTargetRoot(target)
			local delta = (targetRoot.Position - position)

			EffectController:replicate(EffectUtil.hitEffect({
				part = targetRoot,
				emitterName = "Impact1",
				particleCount = 2,
			}))

			table.insert(victims, {
				target = target,
				direction = delta.Unit,
			})
		end

		request(victims)
		WeaponController:customRemote("SelfDamage")
	end

	Promise.race({
		WeaponUtil.channelPromise(self.definition.specialDuration),
		Promise.fromEvent(human.Touched, function(touchedPart, charPart)
			local isHuman = ProjectileHelper.isHumanProjectilePart(charPart)
			local isProjectile = ProjectileHelper.isProjectileCollidable(touchedPart)
			return isHuman and isProjectile
		end):andThen(explode),
	})
		:finally(function()
			trove:Clean()
		end)
		:catch(function()
			-- do nothing
		end)

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown()
end

return RocketLauncherClient

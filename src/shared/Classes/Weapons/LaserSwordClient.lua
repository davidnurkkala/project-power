local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local LaserSwordClient = {}
LaserSwordClient.__index = LaserSwordClient

function LaserSwordClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, LaserSwordClient)
	return self
end

function LaserSwordClient:destroy()
	self._animator:stop("SwordIdle")
end

function LaserSwordClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("SwordIdle")
end

function LaserSwordClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 11

	local function slash(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = "LaserSwordSwing" .. math.random(1, 4),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.slash1({
			partName = "SlashLaser1",
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
			color = Color3.new(1, 0, 0),
		}))

		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(radius * 2, 3, radius),
					offset = cframe,
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "LaserSwordHit" .. math.random(1, 4),
					color = Color3.new(1, 0, 0),
				}))

				request(target)
			end,
		})
	end

	self._animator:stopHard("SamKatanaSlash1")
	self._animator:stopHard("SamKatanaSlash2")

	if self._attackRight then
		self._animator:play("SamKatanaSlash1", 0)
		slash(CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(-150)))
	else
		self._animator:play("SamKatanaSlash2", 0)
		slash(CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(-30)))
	end

	self._attackRight = not self._attackRight

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function LaserSwordClient:special(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	if not self._specialCooldown:isReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local chargeDuration = 1
	local radius = 18

	self._animator:play("LaserSwordForceCharge", 0)

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid,
		parent = root,
		name = "ForcePushCharge1",
	}))

	local emitterGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.enable({
		guid = emitterGuid,
		object = char.LeftHand.LaserSwordEffects.Emitter,
	}))

	WeaponUtil.channelPromise(chargeDuration)
		:andThen(function()
			self._animator:play("LaserSwordForce", 0)

			EffectController:replicate(EffectUtil.sound({
				parent = root,
				name = "ForcePush1",
			}))

			EffectController:replicate(EffectUtil.forcePush({
				root = root,
				cframe = CFrame.new(0, 0.5, -0.5),
				radius = radius,
				duration = 0.3,
				power = 3,
			}))

			local targets = WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(radius, 3, radius),
			})

			for _, target in targets do
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					color = Color3.fromHex("aaffff"),
				}))
			end

			request(targets, root.CFrame.LookVector + Vector3.new(0, 1, 0))
		end)
		:finally(function()
			EffectController:cancel(soundGuid)
			EffectController:cancel(emitterGuid)
			self._animator:stopHard("LaserSwordForceCharge")
		end)
		:catch(function()
			-- do nothing
		end)

	WeaponController:useGlobalCooldown(chargeDuration + 0.1)
	self._specialCooldown:use()
end

return LaserSwordClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

local LinkedSwordClient = {}
LinkedSwordClient.__index = LinkedSwordClient

function LinkedSwordClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_attackRight = true,
	}, LinkedSwordClient)
	return self
end

function LinkedSwordClient:destroy()
	self._animator:stop("SwordIdle")
end

function LinkedSwordClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("SwordIdle")
end

function LinkedSwordClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 8

	local function slash(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = pickRandom(self.definition.attackSounds),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
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
					soundName = "SwordHit" .. math.random(1, 4),
				}))

				request(target)
			end,
		})
	end

	if self._attackRight then
		self._animator:play("SwordSlash1", 0)
		slash(CFrame.Angles(0, 0, math.rad(-150)))
	else
		self._animator:play("SwordSlash2", 0)
		slash(CFrame.Angles(0, 0, math.rad(-30)))
	end

	self._attackRight = not self._attackRight

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function LinkedSwordClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._animator:play("SwordSpin", 0)

	local radius = 10
	local cframe = CFrame.new(0, -1, 0)

	EffectController:replicate(EffectUtil.sound({
		name = "LinkedSwordUnsheathe",
		parent = root,
	}))

	EffectController:replicate(EffectUtil.slash1({
		radius = radius,
		duration = 0.2,
		cframe = cframe * CFrame.Angles(0, math.rad(45), 0),
		rotation = math.rad(-450),
		root = root,
	}))

	WeaponUtil.hitboxLingering({
		hitbox = function()
			return WeaponUtil.hitbox({
				cframe = root.CFrame * cframe,
				size = Vector3.new(radius * 2, 3, radius * 2),
			})
		end,
		callback = function(target)
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "SwordHit" .. math.random(1, 4),
			}))

			request(target)
		end,
	})

	DashController:getCooldown():reset()

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown()
end

function LinkedSwordClient:dash(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	local onDashCompletion = DashController:dash({
		soundDisabled = true,
		cooldown = self.definition.dashCooldown,
	})
	if not onDashCompletion then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._animator:play("SwordLunge", 0)

	EffectController:replicate(EffectUtil.sound({
		name = "LinkedSwordLunge",
		parent = root,
	}))

	WeaponUtil.hitboxLingering({
		duration = 0.25,
		hitbox = function()
			return WeaponUtil.hitbox({
				cframe = root.CFrame,
				size = Vector3.new(4, 4, 8),
			})
		end,
		callback = function(target)
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "SwordHit" .. math.random(1, 4),
			}))

			request(target, root.CFrame.LookVector)
		end,
	})

	WeaponController:useGlobalCooldown()
end

return LinkedSwordClient

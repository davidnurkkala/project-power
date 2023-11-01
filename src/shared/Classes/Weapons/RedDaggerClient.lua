local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local RedDaggerClient = {}
RedDaggerClient.__index = RedDaggerClient

function RedDaggerClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_upward = true,
	}, RedDaggerClient)
	return self
end

function RedDaggerClient:destroy() end

function RedDaggerClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
end

function RedDaggerClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 6
	local cframe
	if self._upward then
		self._animator:play("DaggerSlash1", 0)
		cframe = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(150))
		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
			color = Color3.new(1, 0, 0),
		}))
	else
		self._animator:play("DaggerSlash2", 0)
		cframe = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(30))
		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
			color = Color3.new(1, 0, 0),
		}))
	end

	EffectController:replicate(EffectUtil.sound({
		name = "DaggerSlash" .. math.random(1, 3),
		parent = root,
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
				soundName = "DaggerHit" .. math.random(1, 4),
				color = Color3.new(1, 0, 0),
			}))

			request(target)
		end,
	})

	self._upward = not self._upward

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function RedDaggerClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._animator:play("DaggerSpecial", 0)

	local radius = 8

	local function slash(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = "DaggerSlash" .. math.random(1, 3),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.slash1({
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
					soundName = "DaggerHit" .. math.random(1, 4),
					color = Color3.new(1, 0, 0),
				}))

				request(target)
			end,
		})
	end

	slash(CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(150)))
	task.delay(0.1, slash, CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(-15)))

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown()
end

return RedDaggerClient
